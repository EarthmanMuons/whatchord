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

  static const Object _unset = Object();

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
    Object? device = _unset, // MidiDevice? or null
    int? attempt,
    Object? nextDelay = _unset, // Duration? or null
    Object? message = _unset, // String? or null
    Object? unavailability = _unset, // BluetoothUnavailability? or null
  }) {
    return MidiConnectionState(
      phase: phase ?? this.phase,
      device: identical(device, _unset) ? this.device : device as MidiDevice?,
      attempt: attempt ?? this.attempt,
      nextDelay: identical(nextDelay, _unset)
          ? this.nextDelay
          : nextDelay as Duration?,
      message: identical(message, _unset) ? this.message : message as String?,
      unavailability: identical(unavailability, _unset)
          ? this.unavailability
          : unavailability as BluetoothUnavailability?,
    );
  }
}
