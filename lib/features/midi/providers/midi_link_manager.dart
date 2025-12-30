import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bluetooth_state.dart';
import '../models/midi_device.dart';
import '../persistence/midi_preferences.dart';
import '../services/midi_service.dart';
import 'midi_providers.dart';

enum MidiLinkPhase {
  idle,
  connecting,
  retrying,
  connected,
  bluetoothUnavailable,
  deviceUnavailable,
  error,
}

class MidiLinkState {
  final MidiLinkPhase phase;
  final MidiDevice? device;
  final int attempt; // 1-based
  final Duration? nextDelay;
  final String? message;

  const MidiLinkState({
    required this.phase,
    this.device,
    this.attempt = 0,
    this.nextDelay,
    this.message,
  });

  const MidiLinkState.idle() : this(phase: MidiLinkPhase.idle);

  MidiLinkState copyWith({
    MidiLinkPhase? phase,
    MidiDevice? device,
    int? attempt,
    Duration? nextDelay,
    String? message,
  }) {
    return MidiLinkState(
      phase: phase ?? this.phase,
      device: device ?? this.device,
      attempt: attempt ?? this.attempt,
      nextDelay: nextDelay ?? this.nextDelay,
      message: message ?? this.message,
    );
  }
}

final midiLinkManagerProvider =
    NotifierProvider<MidiLinkManager, MidiLinkState>(MidiLinkManager.new);

class MidiLinkManager extends Notifier<MidiLinkState> {
  static const int _maxAttempts = 5;
  static const Duration _maxBackoff = Duration(seconds: 16);

  Timer? _retryTimer;
  bool _backgrounded = false;
  bool _attemptInFlight = false;

  MidiService get _service => ref.read(midiServiceProvider);

  @override
  MidiLinkState build() {
    // Keep link state aligned with the connected device stream.
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
        state = MidiLinkState(phase: MidiLinkPhase.connected, device: device);
        return;
      }

      // If we were connected and became disconnected, fall back to idle.
      if (state.phase == MidiLinkPhase.connected) {
        state = const MidiLinkState.idle();
      }
    });

    // React to bluetooth availability changes.
    ref.listen<AsyncValue<BluetoothState>>(bluetoothStateStreamProvider, (
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
          phase: MidiLinkPhase.bluetoothUnavailable,
          message: bt.displayName,
        );
        return;
      }

      // If bluetooth becomes ready while foregrounded, a future resume or manual
      // reconnect will handle it. We avoid “always-on” retries in background.
    });

    ref.onDispose(_cancelRetry);
    return const MidiLinkState.idle();
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

    _attemptInFlight = true;
    try {
      // Ensure service is initialized.
      final initialized = await ref.read(midiServiceInitProvider.future);
      if (!initialized) {
        state = state.copyWith(
          phase: MidiLinkPhase.error,
          message: 'MIDI service failed to initialize',
        );
        return;
      }

      // Respect user preference.
      final MidiPreferences prefs = await ref.read(
        midiPreferencesProvider.future,
      );
      if (!prefs.getAutoReconnect()) return;

      final lastDeviceId = prefs.getLastDeviceId();
      if (lastDeviceId == null) return;

      // If already connected to the last device, do nothing.
      final current = ref
          .read(connectedMidiDeviceProvider)
          .when(data: (d) => d, loading: () => null, error: (_, _) => null);
      if (current?.isConnected == true && current?.id == lastDeviceId) return;

      // Gate on bluetooth being ready.
      final bt = ref
          .read(bluetoothStateStreamProvider)
          .when(data: (d) => d, loading: () => null, error: (_, _) => null);
      if (bt != null && !_bluetoothReady(bt)) {
        state = state.copyWith(
          phase: MidiLinkPhase.bluetoothUnavailable,
          message: bt.displayName,
        );
        return;
      }

      await _reconnectWithBackoff(lastDeviceId);
    } finally {
      _attemptInFlight = false;
    }
  }

  Future<void> _reconnectWithBackoff(String deviceId) async {
    _cancelRetry();

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      if (_backgrounded) return;

      state = MidiLinkState(
        phase: attempt == 1 ? MidiLinkPhase.connecting : MidiLinkPhase.retrying,
        attempt: attempt,
        message: attempt == 1
            ? 'Reconnecting…'
            : 'Reconnecting (attempt $attempt)…',
      );

      final ok = await _service.reconnect(deviceId);
      if (ok) {
        // connectedMidiDeviceProvider listener will transition us to connected.
        return;
      }

      // If we can see the devices list, check whether the last device appears.
      final devices = ref
          .read(availableMidiDevicesProvider)
          .when(data: (d) => d, loading: () => null, error: (_, _) => null);
      final seen = devices?.any((d) => d.id == deviceId) ?? false;
      if (!seen) {
        // Surface a more helpful message; we still respect the finite attempt count.
        state = state.copyWith(
          phase: MidiLinkPhase.deviceUnavailable,
          message: 'Last device not found. Make sure it is powered on.',
        );
      }

      if (attempt == _maxAttempts) {
        state = state.copyWith(
          phase: MidiLinkPhase.deviceUnavailable,
          message: 'Unable to reconnect. You can try again or pick a device.',
        );
        return;
      }

      final delay = _backoffForAttempt(attempt);
      state = state.copyWith(
        phase: MidiLinkPhase.retrying,
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

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }
}
