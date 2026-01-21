import 'package:meta/meta.dart';

import 'midi_connection.dart';
import 'midi_unavailable_reason.dart';

/// Presentation model for MIDI connection UI.
@immutable
class MidiConnectionStatus {
  final MidiConnectionPhase phase;
  final String label;
  final String? detail;

  final MidiUnavailableReason? unavailableReason;
  final bool canOpenSettings;

  final int? attempt;
  final Duration? nextDelay;
  final String? message;
  final String? deviceName;

  const MidiConnectionStatus({
    required this.phase,
    required this.label,
    this.detail,
    this.unavailableReason,
    this.canOpenSettings = false,
    this.attempt,
    this.nextDelay,
    this.message,
    this.deviceName,
  });

  bool get isConnected => phase == MidiConnectionPhase.connected;
}
