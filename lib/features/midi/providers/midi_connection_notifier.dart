import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bluetooth_state.dart';
import '../models/midi_connection.dart';
import '../models/midi_device.dart';
import '../persistence/midi_preferences_notifier.dart';
import '../providers/midi_device_providers.dart';
import '../providers/midi_service_providers.dart';
import '../services/midi_service.dart';

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

  MidiService get _service => ref.read(midiServiceProvider);

  @override
  MidiConnectionState build() {
    // Keep connection state aligned with the connected device stream.
    ref.listen<AsyncValue<MidiDevice?>>(connectedMidiDeviceProvider, (
      prev,
      next,
    ) {
      final device = next.when(
        data: (d) => d,
        loading: () => null,
        error: (_, _) => null,
      );

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
    });

    // React to bluetooth availability changes.
    ref.listen<AsyncValue<BluetoothState>>(bluetoothStateProvider, (
      prev,
      next,
    ) {
      final bt = next.when(
        data: (d) => d,
        loading: () => null,
        error: (_, _) => null,
      );
      if (bt == null) return;

      final ready = _bluetoothReady(bt);
      if (!ready) {
        _cancelRetry();
        state = state.copyWith(
          phase: MidiConnectionPhase.bluetoothUnavailable,
          message: bt.displayName,
        );
        return;
      }

      // If bluetooth becomes ready while foregrounded, a future resume or manual
      // reconnect will handle it. We avoid “always-on” retries in background.
    });

    ref.onDispose(_cancelRetry);
    return const MidiConnectionState.idle();
  }

  void setBackgrounded(bool value) {
    _backgrounded = value;
    if (_backgrounded) {
      _cancelRetry();
    }
  }

  Future<void> tryAutoReconnect({required String reason}) async {
    if (_backgrounded) return;
    if (_attemptInFlight) return;

    // Only run the startup auto-reconnect sequence once per app run.
    if (reason == 'startup') {
      if (_startupAttempted) return;
      _startupAttempted = true;
    }

    // Rate-limit other auto triggers (resume, bt-ready, etc.).
    final now = DateTime.now();
    final last = _lastAutoReconnectAt;
    if (reason != 'startup' &&
        last != null &&
        now.difference(last) < const Duration(seconds: 5)) {
      return;
    }
    _lastAutoReconnectAt = now;

    _attemptInFlight = true;
    try {
      // Ensure service is initialized.
      final initialized = await ref.read(midiServiceInitProvider.future);
      if (!initialized) {
        state = state.copyWith(
          phase: MidiConnectionPhase.error,
          message: 'MIDI service failed to initialize',
          nextDelay: null,
        );
        return;
      }

      // Respect user preference.
      final prefs = ref.read(midiPreferencesProvider);
      if (!prefs.autoReconnect) return;

      final savedDeviceId = prefs.savedDeviceId;
      if (savedDeviceId == null || savedDeviceId.trim().isEmpty) {
        // Nothing to reconnect to. Keep the UI clean after a reset.
        _cancelRetry();

        // Only override state if we were showing reconnect-related phases.
        if (state.phase == MidiConnectionPhase.connecting ||
            state.phase == MidiConnectionPhase.retrying ||
            state.phase == MidiConnectionPhase.deviceUnavailable ||
            state.phase == MidiConnectionPhase.error) {
          state = const MidiConnectionState.idle();
        } else {
          // Clear any stale messaging/delay without forcing a phase change.
          state = state.copyWith(message: null, nextDelay: null, attempt: 0);
        }
        return;
      }

      // If already connected to the saved device, do nothing.
      final current = ref
          .read(connectedMidiDeviceProvider)
          .when(data: (d) => d, loading: () => null, error: (_, _) => null);
      if (current?.isConnected == true && current?.id == savedDeviceId) return;

      // Gate on bluetooth being ready.
      final bt = ref
          .read(bluetoothStateProvider)
          .when(data: (d) => d, loading: () => null, error: (_, _) => null);
      if (bt != null && !_bluetoothReady(bt)) {
        state = state.copyWith(
          phase: MidiConnectionPhase.bluetoothUnavailable,
          message: bt.displayName,
          nextDelay: null,
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

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      if (_backgrounded) return;

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

      final ok = await _service.reconnect(deviceId);

      if (ok) return;

      // If we can see the devices list, check whether the last device appears.
      bool? seen;
      if (attempt == 1 || attempt == _maxAttempts) {
        final devices = ref
            .read(availableMidiDevicesProvider)
            .when(data: (d) => d, loading: () => null, error: (_, _) => null);
        seen = devices?.any((d) => d.id == deviceId);
      }

      if (seen == false) {
        state = state.copyWith(
          phase: MidiConnectionPhase.deviceUnavailable,
          message: 'Saved device not found. Make sure it is powered on.',
        );
      }

      final delay = _backoffForAttempt(attempt);
      state = state.copyWith(
        phase: MidiConnectionPhase.retrying,
        attempt: attempt,
        nextDelay: delay,
        message: 'Retrying in ${delay.inSeconds}s…',
      );

      await _sleep(delay);
    }
  }

  bool _bluetoothReady(BluetoothState s) {
    return switch (s) {
      BluetoothState.on => true,
      BluetoothState.off => false,
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

  /// Cancels any pending retry and normalizes public state back to idle.
  /// Useful after "Forget last device" or "Clear MIDI data" actions.
  void resetToIdle() {
    _cancelRetry();
    _attemptInFlight = false;
    _lastAutoReconnectAt = null;
    _lastSavedDeviceId = null;
    state = const MidiConnectionState.idle();
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// Ensure service is initialized before performing action.
  Future<void> _ensureInitialized() async {
    final initialized = await ref.read(midiServiceInitProvider.future);
    if (!initialized) {
      throw const MidiException('Failed to initialize MIDI service');
    }
  }

  /// Start scanning for devices.
  Future<void> startScanning() async {
    await _ensureInitialized();
    await _service.startScanning();
  }

  /// Stop scanning for devices.
  Future<void> stopScanning() async {
    await _service.stopScanning();
  }

  /// Connect to a device and save it as the last connected device.
  Future<void> connect(MidiDevice device) async {
    await _ensureInitialized();

    // Cancel any backoff/retry loop; this is an explicit user action.
    _cancelRetry();

    // Publish "connecting" with the specific device so UI can render per-row spinners.
    state = MidiConnectionState(
      phase: MidiConnectionPhase.connecting,
      device: device,
      attempt: 1,
      nextDelay: null,
      message: 'Connecting…',
    );

    try {
      await _service.connect(device);
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
    await _service.disconnect();
  }

  /// Manually trigger a reconnection attempt.
  Future<bool> reconnect() async {
    await _ensureInitialized();
    final prefs = ref.read(midiPreferencesProvider);
    final savedDeviceId = prefs.savedDeviceId;

    if (savedDeviceId == null) return false;

    return _service.reconnect(savedDeviceId);
  }
}
