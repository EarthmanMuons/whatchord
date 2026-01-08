import 'package:meta/meta.dart';

import '../providers/midi_connection_notifier.dart';

/// Presentation model for MIDI connection UI.
@immutable
class MidiConnectionStatus {
  final MidiConnectionPhase phase;
  final String label; // short, pill/title-friendly
  final String? detail; // optional, settings subtitle-friendly

  final int? attempt; // retry attempt #
  final Duration? nextDelay; // next retry delay
  final String? message; // error/capability reason
  final String? deviceName; // when connected

  const MidiConnectionStatus({
    required this.phase,
    required this.label,
    this.detail,
    this.attempt,
    this.nextDelay,
    this.message,
    this.deviceName,
  });

  bool get isConnected => phase == MidiConnectionPhase.connected;
}
