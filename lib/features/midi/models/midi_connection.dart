import 'package:meta/meta.dart';

import 'bluetooth_unavailability.dart';
import 'midi_device.dart';

enum MidiConnectionPhase {
  idle,
  connecting,
  retrying,
  connected,
  bluetoothUnavailable,
  deviceUnavailable,
  error,
}

/// Internal connection state with full workflow details.
///
/// Tracks retry attempts, delays, and internal phases. For UI presentation,
/// see [MidiConnectionStatus] (computed via [midiConnectionStatusProvider]).
@immutable
class MidiConnectionState {
  final MidiConnectionPhase phase;
  final MidiDevice? device;
  final int attempt; // 1-based
  final Duration? nextDelay;
  final String? message;
  final BluetoothUnavailability? unavailability;

  const MidiConnectionState({
    required this.phase,
    this.device,
    this.attempt = 0,
    this.nextDelay,
    this.message,
    this.unavailability,
  });

  const MidiConnectionState.idle() : this(phase: MidiConnectionPhase.idle);

  bool get isIdle => phase == MidiConnectionPhase.idle;

  bool get isAttemptingConnection =>
      phase == MidiConnectionPhase.connecting ||
      phase == MidiConnectionPhase.retrying;

  bool get isConnected => phase == MidiConnectionPhase.connected;

  String? get deviceDisplayName => device?.displayName;

  MidiConnectionState copyWith({
    MidiConnectionPhase? phase,
    MidiDevice? device,
    int? attempt,
    Duration? nextDelay,
    String? message,
    BluetoothUnavailability? unavailability,
  }) {
    return MidiConnectionState(
      phase: phase ?? this.phase,
      device: device ?? this.device,
      attempt: attempt ?? this.attempt,
      nextDelay: nextDelay ?? this.nextDelay,
      message: message ?? this.message,
      unavailability: unavailability ?? this.unavailability,
    );
  }
}
