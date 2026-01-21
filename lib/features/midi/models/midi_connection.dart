import 'package:meta/meta.dart';

import 'midi_device.dart';
import 'midi_unavailable_reason.dart';

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
  final MidiUnavailableReason? unavailableReason;

  const MidiConnectionState({
    required this.phase,
    this.device,
    this.attempt = 0,
    this.nextDelay,
    this.message,
    this.unavailableReason,
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
    MidiUnavailableReason? unavailableReason,
  }) {
    return MidiConnectionState(
      phase: phase ?? this.phase,
      device: device ?? this.device,
      attempt: attempt ?? this.attempt,
      nextDelay: nextDelay ?? this.nextDelay,
      message: message ?? this.message,
      unavailableReason: unavailableReason ?? this.unavailableReason,
    );
  }
}
