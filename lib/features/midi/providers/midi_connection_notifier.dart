import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../midi_debug.dart';
import '../models/bluetooth_access.dart';
import '../models/bluetooth_state.dart';
import '../models/bluetooth_unavailability.dart';
import '../models/midi_connection.dart';
import '../models/midi_device.dart';
import 'midi_device_manager.dart';
import 'midi_preferences_notifier.dart';

final midiConnectionStateProvider =
    NotifierProvider<MidiConnectionNotifier, MidiConnectionState>(
      MidiConnectionNotifier.new,
    );

class MidiConnectionNotifier extends Notifier<MidiConnectionState> {
  static const int _maxAttempts = 5;
  static const Duration _maxBackoff = Duration(seconds: 16);
  static const Duration _findTargetTimeout = Duration(seconds: 8);
  static const Duration _reconnectAttemptTimeout = Duration(seconds: 12);
  static const Duration _connectedPublishTimeout = Duration(seconds: 3);
  static const bool _debugLog = midiDebug;

  bool _startupAttempted = false;
  DateTime? _lastAutoReconnectAt;

  Timer? _retryTimer;
  Completer<void>? _retrySleepCompleter;

  bool _backgrounded = false;
  bool _attemptInFlight = false;

  // Dedupe guard: prevents repeated persistence writes when the
  // connected-device stream re-emits the same device id.
  String? _lastPersistedDeviceId;

  BluetoothState? _lastBluetoothState;
  bool _cancelRequested = false;

  MidiDeviceManager get _midi => ref.read(midiDeviceManagerProvider.notifier);

  /// Explicit user/controller cancel:
  /// - cancels reconnect/backoff loops
  /// - stops scanning
  /// - normalizes UI state
  Future<void> cancel({String reason = 'user_cancel'}) async {
    if (_debugLog) debugPrint('[CONN] cancel reason=$reason');
    _cancelRequested = true;
    _cancelRetry();
    // Do not clear `_attemptInFlight` here: cancel only requests early exit.
    // The active reconnect run clears the flag in tryAutoReconnect's `finally`
    // after all in-flight async work has unwound.

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
        if (_debugLog) {
          debugPrint(
            '[CONN] device update prev=${prev?.id}/${prev?.isConnected} '
            'next=${next?.id}/${next?.isConnected} phase=${state.phase}',
          );
        }

        if (device != null && device.isConnected) {
          _cancelRetry();
          state = MidiConnectionState(
            phase: MidiConnectionPhase.connected,
            device: device,
          );
          // Persist last-connected device on successful connection.
          // Dedupe by device id to avoid churn on repeated stream emissions.
          if (device.id != _lastPersistedDeviceId) {
            _lastPersistedDeviceId = device.id;
            final prefs = ref.read(midiPreferencesProvider.notifier);
            // Avoid awaiting inside a listener; persistence is best-effort.
            unawaited(prefs.setLastConnectedDevice(device));
          }
          return;
        }

        // Allow persisting the same device id again after disconnect/forget.
        _lastPersistedDeviceId = null;

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
      if (_debugLog) {
        debugPrint(
          '[CONN] bt update prev=$prev next=$next phase=${state.phase}',
        );
      }

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
          BluetoothState.poweredOff => BluetoothUnavailability.adapterOff,
          BluetoothState.unauthorized =>
            BluetoothUnavailability.permissionDenied,
          BluetoothState.unknown => BluetoothUnavailability.notReady,
          BluetoothState.poweredOn =>
            BluetoothUnavailability.notReady, // unreachable here
        };

        // Preserve a stronger reason already set by permission gating.
        final currentReason = state.unavailability;
        final preserve =
            currentReason ==
            BluetoothUnavailability.permissionPermanentlyDenied;
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
    if (_debugLog) debugPrint('[CONN] backgrounded=$_backgrounded');
    if (_backgrounded) {
      // Controller-owned policy: background cancels attempts and stops scanning.
      unawaited(cancel(reason: 'background'));
    }
  }

  /// Await [future] with a hard timeout.
  /// Returns [onTimeout] if the timeout elapses instead of throwing.
  Future<T?> _withTimeout<T>(
    Future<T> future, {
    required Duration timeout,
    T? onTimeout,
  }) async {
    try {
      return await future.timeout(timeout);
    } on TimeoutException {
      return onTimeout;
    }
  }

  Future<void> tryAutoReconnect({required String reason}) async {
    if (_debugLog) {
      debugPrint(
        '[CONN] tryAutoReconnect reason=$reason '
        'bg=$_backgrounded inflight=$_attemptInFlight cancel=$_cancelRequested',
      );
    }
    if (_backgrounded) return;
    if (_attemptInFlight) return;

    // Background/pause flows intentionally set cancel=true to stop in-flight work.
    // A new foreground reconnect trigger (resume/startup/manual/bt-ready) must
    // clear that stale cancel marker, otherwise _reconnectWithBackoff bails
    // immediately and UI can remain stuck in "Connecting…".
    _cancelRequested = false;

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
      if (!isManual && !prefs.autoReconnect) {
        if (_debugLog) debugPrint('[CONN] autoReconnect disabled');
        return;
      }

      final lastConnectedDeviceId = prefs.lastConnectedDeviceId;
      var lastConnectedDevice = prefs.lastConnectedDevice;
      if (lastConnectedDeviceId == null ||
          lastConnectedDeviceId.trim().isEmpty) {
        if (_debugLog) debugPrint('[CONN] no lastConnectedDeviceId');
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

      // If already connected to the last connected device, do nothing.
      final current = ref.read(midiDeviceManagerProvider).connectedDevice;
      if (current?.id == lastConnectedDeviceId &&
          current?.isConnected == true) {
        final stillConnected = await _withTimeout(
          _midi.isStillConnected(lastConnectedDeviceId),
          timeout: const Duration(seconds: 2),
          onTimeout: false,
        );
        if (stillConnected == true) {
          if (_debugLog) {
            debugPrint('[CONN] stillConnected id=$lastConnectedDeviceId');
          }
          // Ensure UI matches reality even if the connected-device stream never re-emits.
          state = MidiConnectionState(
            phase: MidiConnectionPhase.connected,
            device: current,
          );
          return;
        }

        // Stale snapshot: clear it so UI reflects reality and reconnect proceeds.
        if (_debugLog) {
          debugPrint(
            '[CONN] stale snapshot; reconcile id=$lastConnectedDeviceId',
          );
        }
        unawaited(_midi.reconcileConnectedDevice(reason: 'tryAutoReconnect'));
      }

      // Preflight: we are about to attempt a connection; publish attempt=1.
      state = state.copyWith(
        phase: MidiConnectionPhase.connecting,
        message: isManual
            ? 'Connecting to last connected device…'
            : (reason == 'startup'
                  ? 'Reconnecting to last connected device…'
                  : 'Reconnecting…'),
        nextDelay: null,
        attempt: 1,
      );

      final ok =
          await _withTimeout(
            _ensureBluetoothAccessOrPublishUnavailable(),
            timeout: const Duration(seconds: 3),
            onTimeout: false,
          ) ??
          false;
      if (!ok) {
        if (_debugLog) debugPrint('[CONN] bluetooth access not ok');
        _cancelRetry();
        return;
      }

      // If BT is clearly off/unauthorized, fail fast with stable UX.
      var bt = ref.read(midiDeviceManagerProvider).bluetoothState;
      if (bt == BluetoothState.poweredOff ||
          bt == BluetoothState.unauthorized) {
        if (_debugLog) debugPrint('[CONN] bluetooth unavailable bt=$bt');
        _cancelRetry();
        state = state.copyWith(
          phase: MidiConnectionPhase.bluetoothUnavailable,
          unavailability: bt == BluetoothState.poweredOff
              ? BluetoothUnavailability.adapterOff
              : BluetoothUnavailability.permissionDenied,
          message: bt.displayName,
          nextDelay: null,
          attempt: 0,
        );
        return;
      }

      // If state is unknown, prime once (this often triggers the first real BT state),
      // then wait briefly for a non-unknown state.
      if (bt == BluetoothState.unknown) {
        try {
          await _withTimeout(
            ref.read(midiDeviceManagerProvider.notifier).ensureReady(),
            timeout: const Duration(seconds: 2),
            onTimeout: null,
          );
        } catch (_) {
          if (_debugLog) debugPrint('[CONN] bluetooth prime failed');
          // If we cannot prime, treat as not-ready and stop.
          _cancelRetry();
          state = state.copyWith(
            phase: MidiConnectionPhase.bluetoothUnavailable,
            unavailability: BluetoothUnavailability.notReady,
            message: 'Bluetooth is not ready yet.',
            nextDelay: null,
            attempt: 0,
          );
          return;
        }

        bt = await _awaitBluetoothState() ?? BluetoothState.unknown;
      }

      if (!_bluetoothReady(bt)) {
        if (_debugLog) debugPrint('[CONN] bluetooth not ready bt=$bt');
        _cancelRetry();
        final unavailableReason = switch (bt) {
          BluetoothState.poweredOff => BluetoothUnavailability.adapterOff,
          BluetoothState.unauthorized =>
            BluetoothUnavailability.permissionDenied,
          BluetoothState.unknown => BluetoothUnavailability.notReady,
          BluetoothState.poweredOn => BluetoothUnavailability.notReady,
        };

        state = state.copyWith(
          phase: MidiConnectionPhase.bluetoothUnavailable,
          unavailability: unavailableReason,
          message: bt.displayName,
          nextDelay: null,
          attempt: 0,
        );
        return;
      }

      await _reconnectWithBackoff(
        lastConnectedDeviceId,
        hint: lastConnectedDevice,
      );
    } finally {
      _attemptInFlight = false;
    }
  }

  Future<void> _reconnectWithBackoff(
    String deviceId, {
    MidiDevice? hint,
  }) async {
    _cancelRetry();
    if (_cancelRequested) return;
    _cancelRequested = false; // start fresh for this run

    var currentId = deviceId;
    var currentHint = hint;

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      if (_backgrounded) return;
      if (_cancelRequested) return;
      if (_debugLog) {
        debugPrint('[CONN] reconnect attempt=$attempt id=$currentId');
      }

      final target = await _withTimeout(
        _midi.findReconnectTarget(deviceId: currentId, hint: currentHint),
        timeout: _findTargetTimeout,
        onTimeout: null,
      );
      if (_backgrounded || _cancelRequested) return;

      if (target == null) {
        if (_debugLog) {
          debugPrint('[CONN] reconnect no target id=$currentId');
        }
      } else {
        if (target.id != currentId) {
          if (_debugLog) {
            debugPrint('[CONN] reconnect remap id=$currentId -> ${target.id}');
          }
          currentId = target.id;
          currentHint = target;
          unawaited(
            ref
                .read(midiPreferencesProvider.notifier)
                .setLastConnectedDevice(target),
          );
        }
      }
      if (_backgrounded || _cancelRequested) return;

      state = MidiConnectionState(
        phase: attempt == 1
            ? MidiConnectionPhase.connecting
            : MidiConnectionPhase.retrying,
        attempt: attempt,
        nextDelay: null,
        message: attempt == 1
            ? 'Reconnecting to last connected device…'
            : 'Reconnecting to last connected device (attempt $attempt)…',
      );

      final ok = target == null
          ? false
          : await _withTimeout(
                  _midi.reconnect(currentId),
                  timeout: _reconnectAttemptTimeout,
                  onTimeout: false,
                ) ??
                false;
      if (_debugLog) {
        debugPrint('[CONN] reconnect result ok=$ok attempt=$attempt');
      }
      if (_backgrounded || _cancelRequested) return;
      if (ok) {
        final published = await _awaitConnectedPublish(
          currentId,
          timeout: _connectedPublishTimeout,
        );
        if (_backgrounded || _cancelRequested) return;
        if (published) return;
        if (_debugLog) {
          debugPrint(
            '[CONN] reconnect missing connected publish id=$currentId; retry',
          );
        }
      }

      final delay = _backoffForAttempt(attempt);

      state = state.copyWith(
        phase: MidiConnectionPhase.retrying,
        attempt: attempt,
        nextDelay: delay,
        message: 'Retrying in ${delay.inSeconds}s…',
      );

      if (_backgrounded || _cancelRequested) return;
      await _sleep(delay);
      if (_backgrounded || _cancelRequested) return;
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

  Future<void> _sleep(Duration delay) {
    _cancelRetry();

    final completer = Completer<void>();
    _retrySleepCompleter = completer;

    _retryTimer = Timer(delay, () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    return completer.future;
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;

    final completer = _retrySleepCompleter;
    _retrySleepCompleter = null;

    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  /// Manual refresh from UI.
  /// - restartScan=true: "hard refresh" (stop/start scan)
  /// - restartScan=false: force device list refresh while scanning
  Future<void> refreshDevices({bool restartScan = true}) async {
    // If you're in backoff/retry UI, a manual refresh should cancel the timer.
    _cancelRetry();
    if (_debugLog) debugPrint('[CONN] refreshDevices restartScan=$restartScan');

    final ok = await _ensureBluetoothAccessOrPublishUnavailable();
    if (!ok) {
      throw MidiException('Bluetooth unavailable (${state.unavailability})');
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
    if (_debugLog) debugPrint('[CONN] startScanning');

    final ok = await _ensureBluetoothAccessOrPublishUnavailable();
    if (!ok) {
      throw MidiException('Bluetooth unavailable (${state.unavailability})');
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
    if (_debugLog) debugPrint('[CONN] connect id=${device.id}');

    final ok = await _ensureBluetoothAccessOrPublishUnavailable();
    if (!ok) {
      throw MidiException('Bluetooth unavailable (${state.unavailability})');
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
    if (_debugLog) debugPrint('[CONN] disconnect');
    await _midi.disconnect();
  }

  /// Manually trigger a reconnection attempt.
  Future<bool> reconnect() async {
    if (_debugLog) debugPrint('[CONN] manual reconnect');
    await tryAutoReconnect(reason: 'manual');

    final connected = ref.read(midiDeviceManagerProvider).connectedDevice;
    return connected?.isConnected == true;
  }

  Future<bool> _ensureBluetoothAccessOrPublishUnavailable() async {
    final access = await _midi.ensureBluetoothAccess();
    if (access.isReady) return true;

    final reason = switch (access.state) {
      BluetoothAccessState.permanentlyDenied =>
        BluetoothUnavailability.permissionPermanentlyDenied,
      BluetoothAccessState.denied => BluetoothUnavailability.permissionDenied,
      BluetoothAccessState.restricted =>
        BluetoothUnavailability.permissionPermanentlyDenied,
      _ => BluetoothUnavailability.notReady,
    };

    state = state.copyWith(
      phase: MidiConnectionPhase.bluetoothUnavailable,
      unavailability: reason,
      message: null,
      attempt: 0,
      nextDelay: null,
    );
    return false;
  }

  Future<BluetoothState?> _awaitBluetoothState({
    Duration timeout = const Duration(milliseconds: 800),
  }) async {
    BluetoothState current = ref.read(midiDeviceManagerProvider).bluetoothState;
    if (current != BluetoothState.unknown) return current;

    final completer = Completer<BluetoothState>();
    late final ProviderSubscription<BluetoothState> sub;

    sub = ref.listen<BluetoothState>(
      midiDeviceManagerProvider.select((s) => s.bluetoothState),
      (prev, next) {
        if (next == BluetoothState.unknown) return;
        if (!completer.isCompleted) completer.complete(next);
      },
      fireImmediately: true,
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

  Future<bool> _awaitConnectedPublish(
    String expectedDeviceId, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final current = ref.read(midiDeviceManagerProvider).connectedDevice;
    if (current?.id == expectedDeviceId && current?.isConnected == true) {
      return true;
    }

    final completer = Completer<bool>();
    late final ProviderSubscription<MidiDevice?> sub;

    sub = ref.listen<MidiDevice?>(
      midiDeviceManagerProvider.select((s) => s.connectedDevice),
      (prev, next) {
        final matched =
            next?.id == expectedDeviceId && next?.isConnected == true;
        if (matched && !completer.isCompleted) {
          completer.complete(true);
        }
      },
      fireImmediately: true,
    );

    try {
      return await completer.future.timeout(timeout, onTimeout: () => false);
    } finally {
      sub.close();
    }
  }
}
