import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ble_access.dart';
import '../models/ble_unavailability.dart';
import '../models/bluetooth_state.dart';
import '../models/midi_connection.dart';
import '../models/midi_device.dart';
import 'midi_device_manager.dart';
import 'midi_preferences_notifier.dart';

final midiConnectionProvider =
    NotifierProvider<MidiConnectionNotifier, MidiConnectionState>(
      MidiConnectionNotifier.new,
    );

class MidiConnectionNotifier extends Notifier<MidiConnectionState> {
  static const int _maxAttempts = 5;
  static const Duration _maxBackoff = Duration(seconds: 16);

  bool _startupAttempted = false;
  DateTime? _lastAutoReconnectAt;

  Timer? _retryTimer;
  bool _backgrounded = false;
  bool _attemptInFlight = false;

  // Dedupe guard: prevents repeated persistence writes when the
  // connected-device stream re-emits the same device id.
  String? _lastSavedDeviceId;

  BluetoothState? _lastBluetoothState;
  bool _cancelRequested = false;

  MidiDeviceManager get _midi => ref.read(midiDeviceManagerProvider.notifier);

  /// Explicit user/controller cancel:
  /// - cancels reconnect/backoff loops
  /// - stops scanning
  /// - normalizes UI state
  Future<void> cancel({String reason = 'user_cancel'}) async {
    _cancelRequested = true;
    _cancelRetry();
    _attemptInFlight = false;

    // If already connected, do not reset connection state.
    final connected = ref.read(midiDeviceManagerProvider).connectedDevice;
    if (connected?.isConnected == true) {
      // Still stop scanning if it is running (likely already stopped by MidiManager.connect).
      try {
        await _midi.stopScanning();
      } catch (_) {}
      return;
    }

    try {
      await _midi.stopScanning();
    } catch (_) {}

    final bt =
        _lastBluetoothState ??
        ref.read(midiDeviceManagerProvider).bluetoothState;
    if (bt != BluetoothState.unknown && !_bluetoothReady(bt)) {
      state = state.copyWith(
        phase: MidiConnectionPhase.bluetoothUnavailable,
        message: bt.displayName,
        nextDelay: null,
        attempt: 0,
      );
    } else {
      state = const MidiConnectionState.idle();
    }
  }

  @override
  MidiConnectionState build() {
    // Keep connection state aligned with the connected device stream.
    ref.listen<MidiDevice?>(
      midiDeviceManagerProvider.select((s) => s.connectedDevice),
      (prev, next) {
        final device = next;

        if (device != null && device.isConnected) {
          _cancelRetry();
          state = MidiConnectionState(
            phase: MidiConnectionPhase.connected,
            device: device,
          );
          // Persist saved device on successful connection.
          // Dedupe by device id to avoid churn on repeated stream emissions.
          if (device.id != _lastSavedDeviceId) {
            _lastSavedDeviceId = device.id;
            final prefs = ref.read(midiPreferencesProvider.notifier);
            // Avoid awaiting inside a listener; persistence is best-effort.
            unawaited(prefs.setSavedDevice(device));
          }
          return;
        }

        // If we were connected and became disconnected, fall back to idle.
        if (state.phase == MidiConnectionPhase.connected) {
          state = const MidiConnectionState.idle();
        }
      },
    );

    // React to bluetooth availability changes.
    ref.listen<
      BluetoothState
    >(midiDeviceManagerProvider.select((s) => s.bluetoothState), (prev, next) {
      final bt = next;

      final prevBt = _lastBluetoothState; // capture before overwrite
      _lastBluetoothState = bt;

      final readyNow = _bluetoothReady(bt);
      final wasReady = prevBt != null ? _bluetoothReady(prevBt) : false;

      if (!readyNow) {
        final isInReconnectUi =
            state.phase == MidiConnectionPhase.connecting ||
            state.phase == MidiConnectionPhase.retrying ||
            state.phase == MidiConnectionPhase.bluetoothUnavailable;

        final shouldPublishUnavailable =
            bt != BluetoothState.unknown && (wasReady || isInReconnectUi);

        if (!shouldPublishUnavailable) {
          // Keep state as-is (usually idle) and just cache the bt value.
          return;
        }

        _cancelRetry();
        _cancelRequested = true;

        final nextReason = switch (bt) {
          BluetoothState.poweredOff => BleUnavailability.adapterOff,
          BluetoothState.unauthorized => BleUnavailability.permissionDenied,
          BluetoothState.unknown => BleUnavailability.notReady,
          BluetoothState.poweredOn =>
            BleUnavailability.notReady, // unreachable here
        };

        // Preserve a stronger reason already set by permission gating.
        final currentReason = state.unavailability;
        final preserve =
            currentReason == BleUnavailability.permissionPermanentlyDenied;
        final message = preserve ? state.message : bt.displayName;

        state = state.copyWith(
          phase: MidiConnectionPhase.bluetoothUnavailable,
          message: message,
          nextDelay: null,
          attempt: 0,
          unavailability: preserve ? currentReason : nextReason,
        );
        return;
      }

      // Only act on a transition to ready (avoid spamming if we get repeated "on").
      if (!wasReady && readyNow) {
        // IMPORTANT: bluetooth is ready again; allow reconnect attempts.
        _cancelRequested = false;

        if (!_backgrounded) {
          Future.microtask(() {
            if (_backgrounded) return;
            if (_attemptInFlight) return;
            unawaited(tryAutoReconnect(reason: 'bt-ready'));
          });
        } else {
          // clear stale UI if we're backgrounded.
          if (state.phase == MidiConnectionPhase.bluetoothUnavailable) {
            state = const MidiConnectionState.idle();
          }
        }
      }
    });

    ref.onDispose(_cancelRetry);
    return const MidiConnectionState.idle();
  }

  void setBackgrounded(bool value) {
    _backgrounded = value;
    if (_backgrounded) {
      // Controller-owned policy: background cancels attempts and stops scanning.
      unawaited(cancel(reason: 'background'));
    }
  }

  Future<void> tryAutoReconnect({required String reason}) async {
    if (_backgrounded) return;
    if (_attemptInFlight) return;

    final isManual = reason == 'manual';

    // Only run the startup auto-reconnect sequence once per app run.
    if (reason == 'startup') {
      if (_startupAttempted) return;
      _startupAttempted = true;
    }

    // Rate-limit other auto triggers (resume, bt-ready, etc.).
    final now = DateTime.now();
    final last = _lastAutoReconnectAt;

    if (!isManual &&
        reason != 'startup' &&
        last != null &&
        now.difference(last) < const Duration(seconds: 5)) {
      return;
    }

    if (!isManual) {
      _lastAutoReconnectAt = now;
    }

    _attemptInFlight = true;
    try {
      final prefs = ref.read(midiPreferencesProvider);

      // Manual reconnect should always work; autoReconnect only gates automatic triggers.
      if (!isManual && !prefs.autoReconnect) return;

      final savedDeviceId = prefs.savedDeviceId;
      if (savedDeviceId == null || savedDeviceId.trim().isEmpty) {
        _cancelRetry();
        if (state.phase == MidiConnectionPhase.connecting ||
            state.phase == MidiConnectionPhase.retrying ||
            state.phase == MidiConnectionPhase.deviceUnavailable ||
            state.phase == MidiConnectionPhase.error) {
          state = const MidiConnectionState.idle();
        } else {
          state = state.copyWith(message: null, nextDelay: null, attempt: 0);
        }
        return;
      }

      // Publish immediately (before any await) so UI reflects reconnect intent
      // even if the user navigates away mid-flight.
      state = state.copyWith(
        phase: isManual
            ? MidiConnectionPhase.connecting
            : MidiConnectionPhase.retrying,
        message: isManual
            ? 'Connecting to saved device…'
            : (reason == 'startup'
                  ? 'Reconnecting to saved device…'
                  : 'Reconnecting…'),
        nextDelay: null,
        attempt: 0,
      );

      // If already connected to the saved device, do nothing.
      final current = ref.read(midiDeviceManagerProvider).connectedDevice;
      if (current?.id == savedDeviceId && current?.isConnected == true) {
        final stillConnected = await _midi.isStillConnected(savedDeviceId);
        if (stillConnected) return;

        // Stale snapshot: clear it so UI reflects reality and reconnect proceeds.
        unawaited(_midi.reconcileConnectedDevice(reason: 'tryAutoReconnect'));
      }

      final ok = await _ensureBleAllowedOrPublishUnavailable(
        contextMsg: 'Bluetooth permission is required to reconnect.',
      );
      if (!ok) {
        _cancelRetry();
        return;
      }

      try {
        await ref.read(midiDeviceManagerProvider.notifier).ensureReady();
      } catch (_) {}

      final bt = await _awaitBluetoothState();
      if (bt == null || !_bluetoothReady(bt)) {
        _cancelRetry();
        final unavailableReason = switch (bt) {
          null => BleUnavailability.notReady,
          BluetoothState.poweredOff => BleUnavailability.adapterOff,
          BluetoothState.unauthorized => BleUnavailability.permissionDenied,
          BluetoothState.unknown => BleUnavailability.notReady,
          BluetoothState.poweredOn => BleUnavailability.notReady,
        };

        state = state.copyWith(
          phase: MidiConnectionPhase.bluetoothUnavailable,
          unavailability: unavailableReason,
          message: bt?.displayName ?? 'Bluetooth is not ready yet.',
          nextDelay: null,
          attempt: 0,
        );
        return;
      }

      await _reconnectWithBackoff(savedDeviceId);
    } finally {
      _attemptInFlight = false;
    }
  }

  Future<void> _reconnectWithBackoff(String deviceId) async {
    _cancelRetry();
    _cancelRequested = false; // start fresh for this run

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      if (_backgrounded) return;
      if (_cancelRequested) return;

      state = MidiConnectionState(
        phase: attempt == 1
            ? MidiConnectionPhase.connecting
            : MidiConnectionPhase.retrying,
        attempt: attempt,
        nextDelay: null,
        message: attempt == 1
            ? 'Reconnecting to saved device…'
            : 'Reconnecting to saved device (attempt $attempt)…',
      );

      final ok = await _midi.reconnect(deviceId);
      if (_cancelRequested) return;
      if (ok) return;

      final delay = _backoffForAttempt(attempt);

      state = state.copyWith(
        phase: MidiConnectionPhase.retrying,
        attempt: attempt,
        nextDelay: delay,
        message: 'Retrying in ${delay.inSeconds}s…',
      );

      if (_cancelRequested) return;
      await _sleep(delay);
      if (_cancelRequested) return;
    }

    // Terminal state after max attempts.
    if (!_backgrounded && !_cancelRequested) {
      state = MidiConnectionState(
        phase: MidiConnectionPhase.deviceUnavailable,
        message:
            'Unable to reconnect. Make sure the device is powered on and nearby.',
        attempt: _maxAttempts,
        nextDelay: null,
      );
    }
  }

  bool _bluetoothReady(BluetoothState s) {
    return switch (s) {
      BluetoothState.poweredOn => true,
      BluetoothState.poweredOff => false,
      BluetoothState.unknown => false,
      BluetoothState.unauthorized => false,
    };
  }

  Duration _backoffForAttempt(int attempt) {
    // attempt=1 -> 1s, 2->2s, 3->4s, 4->8s, 5->16s
    final seconds = 1 << (attempt - 1);
    final d = Duration(seconds: seconds);
    return d > _maxBackoff ? _maxBackoff : d;
  }

  Future<void> _sleep(Duration d) {
    final c = Completer<void>();
    _retryTimer = Timer(d, c.complete);
    return c.future;
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// Manual refresh from UI.
  /// - restartScan=true: "hard refresh" (stop/start scan)
  /// - restartScan=false: force device list refresh while scanning
  Future<void> refreshDevices({bool restartScan = true}) async {
    // If you're in backoff/retry UI, a manual refresh should cancel the timer.
    _cancelRetry();

    final ok = await _ensureBleAllowedOrPublishUnavailable(
      contextMsg: 'Bluetooth permission is required to scan for devices.',
    );
    if (!ok) {
      throw MidiException(state.message ?? 'Bluetooth permission is required');
    }

    if (restartScan) {
      await _midi.restartScanning();
    } else {
      await _midi.refreshDevices(ensureScanning: true);
    }
  }

  /// Start scanning for devices.
  Future<void> startScanning() async {
    _cancelRetry();

    final ok = await _ensureBleAllowedOrPublishUnavailable(
      contextMsg: 'Bluetooth permission is required to scan for devices.',
    );
    if (!ok) {
      throw MidiException(state.message ?? 'Bluetooth permission is required');
    }

    await _midi.startScanning();
  }

  /// Stop scanning for devices.
  Future<void> stopScanning() async {
    await _midi.stopScanning();
  }

  /// Connect to a device and save it as the last connected device.
  Future<void> connect(MidiDevice device) async {
    // Cancel any backoff/retry loop; this is an explicit user action.
    _cancelRetry();

    final ok = await _ensureBleAllowedOrPublishUnavailable(
      contextMsg: 'Bluetooth permission is required to connect.',
    );
    if (!ok) {
      state = state.copyWith(phase: MidiConnectionPhase.error, device: device);
      throw MidiException(state.message ?? 'Bluetooth permission is required');
    }

    // Publish "connecting" with the specific device so UI can render per-row spinners.
    state = MidiConnectionState(
      phase: MidiConnectionPhase.connecting,
      device: device,
      attempt: 1,
      nextDelay: null,
      message: 'Connecting…',
    );

    try {
      await _midi.connect(device);
      // Success path is handled by your connectedMidiDeviceProvider listener,
      // which will set phase=connected and persist the device.
    } on MidiException catch (e) {
      state = MidiConnectionState(
        phase: MidiConnectionPhase.error,
        device: device,
        message: e.message,
      );
      rethrow;
    } catch (e) {
      state = MidiConnectionState(
        phase: MidiConnectionPhase.error,
        device: device,
        message: 'Connection failed: $e',
      );
      rethrow;
    }
  }

  /// Disconnect from the current device.
  Future<void> disconnect() async {
    await _midi.disconnect();
  }

  /// Manually trigger a reconnection attempt.
  Future<bool> reconnect() async {
    await tryAutoReconnect(reason: 'manual');

    final connected = ref.read(midiDeviceManagerProvider).connectedDevice;
    return connected?.isConnected == true;
  }

  Future<bool> _ensureBleAllowedOrPublishUnavailable({
    String? contextMsg,
  }) async {
    final access = await _midi.ensureBleAccess();
    if (access.isReady) return true;

    final reason = switch (access.state) {
      BleAccessState.permanentlyDenied =>
        BleUnavailability.permissionPermanentlyDenied,
      BleAccessState.denied => BleUnavailability.permissionDenied,
      BleAccessState.restricted =>
        BleUnavailability.permissionPermanentlyDenied,
      _ => BleUnavailability.notReady,
    };

    state = state.copyWith(
      phase: MidiConnectionPhase.bluetoothUnavailable,
      unavailability: reason,
      message: access.message ?? contextMsg,
      attempt: 0,
      nextDelay: null,
    );
    return false;
  }

  Future<BluetoothState?> _awaitBluetoothState({
    Duration timeout = const Duration(milliseconds: 800),
  }) async {
    final current = ref.read(midiDeviceManagerProvider).bluetoothState;
    if (current != BluetoothState.unknown) return current;

    final completer = Completer<BluetoothState>();
    late final ProviderSubscription<BluetoothState> sub;

    sub = ref.listen<BluetoothState>(
      midiDeviceManagerProvider.select((s) => s.bluetoothState),
      (prev, next) {
        if (next != BluetoothState.unknown && !completer.isCompleted) {
          completer.complete(next);
        }
      },
    );

    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      // Fall back to whatever we have at timeout (may still be unknown).
      return ref.read(midiDeviceManagerProvider).bluetoothState;
    } finally {
      sub.close();
    }
  }
}
