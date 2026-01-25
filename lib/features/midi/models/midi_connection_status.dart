import 'package:meta/meta.dart';

import 'ble_unavailability.dart';
import 'midi_connection.dart';

/// UI-friendly presentation model for MIDI connection status.
///
/// Derived from [MidiConnectionState] with user-facing labels and
/// simplified state representation. Used by status widgets and settings UI.
@immutable
class MidiConnectionStatus {
  final MidiConnectionPhase phase;
  final String label;
  final String? detail;

  final BleUnavailability? unavailability;
  final bool canOpenSettings;

  final int? attempt;
  final Duration? nextDelay;
  final String? message;
  final String? deviceName;

  const MidiConnectionStatus({
    required this.phase,
    required this.label,
    this.detail,
    this.unavailability,
    this.canOpenSettings = false,
    this.attempt,
    this.nextDelay,
    this.message,
    this.deviceName,
  });

  bool get isConnected => phase == MidiConnectionPhase.connected;
}
