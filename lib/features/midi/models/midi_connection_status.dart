import 'package:meta/meta.dart';

import 'bluetooth_unavailability.dart';
import 'midi_connection.dart';
import 'midi_device.dart';

/// UI-friendly presentation model for MIDI connection status.
///
/// Derived from [MidiConnectionState] with user-facing labels and
/// simplified state representation. Used by status widgets and settings UI.
@immutable
class MidiConnectionStatus {
  final MidiConnectionPhase phase;
  final String title;
  final String? subtitle;

  final BluetoothUnavailability? unavailability;
  final bool canOpenSettings;

  final int? attempt;
  final Duration? nextDelay;
  final String? diagnosticMessage;
  final String? deviceName;
  final MidiTransportType? deviceTransport;

  const MidiConnectionStatus({
    required this.phase,
    required this.title,
    this.subtitle,
    this.unavailability,
    this.canOpenSettings = false,
    this.attempt,
    this.nextDelay,
    this.diagnosticMessage,
    this.deviceName,
    this.deviceTransport,
  });

  bool get isConnected => phase == MidiConnectionPhase.connected;
}
