import 'package:meta/meta.dart';

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

@immutable
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

  bool get isIdle => phase == MidiConnectionPhase.idle;

  bool get isBusy =>
      phase == MidiConnectionPhase.connecting ||
      phase == MidiConnectionPhase.retrying;

  bool get isConnected => phase == MidiConnectionPhase.connected;

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
