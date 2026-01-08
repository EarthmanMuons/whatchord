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

class MidiConnectionState {
  final MidiConnectionPhase phase;
  final MidiDevice? device;
  final int attempt; // 1-based
  final Duration? nextDelay;
  final String? message;

  const MidiConnectionState({
    required this.phase,
    this.device,
    this.attempt = 0,
    this.nextDelay,
    this.message,
  });

  const MidiConnectionState.idle() : this(phase: MidiConnectionPhase.idle);

  MidiConnectionState copyWith({
    MidiConnectionPhase? phase,
    MidiDevice? device,
    int? attempt,
    Duration? nextDelay,
    String? message,
  }) {
    return MidiConnectionState(
      phase: phase ?? this.phase,
      device: device ?? this.device,
      attempt: attempt ?? this.attempt,
      nextDelay: nextDelay ?? this.nextDelay,
      message: message ?? this.message,
    );
  }
}
