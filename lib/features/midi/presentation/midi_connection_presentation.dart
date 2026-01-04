import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/midi_connection_notifier.dart';

/// Presentation model for MIDI connection UI.
@immutable
class MidiConnectionPresentation {
  final MidiConnectionPhase phase;
  final String label; // short, pill/title-friendly
  final String? detail; // optional, settings subtitle-friendly

  final int? attempt; // retry attempt #
  final Duration? nextDelay; // next retry delay
  final String? message; // error/capability reason
  final String? deviceName; // when connected

  const MidiConnectionPresentation({
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

/// Provides UI-friendly presentation of MIDI connection state.
final midiConnectionPresentationProvider = Provider<MidiConnectionPresentation>(
  (ref) {
    final connection = ref.watch(midiConnectionNotifierProvider);

    return switch (connection.phase) {
      MidiConnectionPhase.connected => MidiConnectionPresentation(
        phase: connection.phase,
        label: 'Connected',
        detail: connection.device?.name.trim().isNotEmpty == true
            ? 'Connected to ${connection.device!.name.trim()}'
            : 'Connected',
        deviceName: connection.device?.name,
      ),

      MidiConnectionPhase.connecting => const MidiConnectionPresentation(
        phase: MidiConnectionPhase.connecting,
        label: 'Connecting…',
        detail: 'Connecting…',
      ),

      MidiConnectionPhase.retrying => MidiConnectionPresentation(
        phase: MidiConnectionPhase.retrying,
        label: 'Reconnecting…',
        detail: connection.nextDelay != null
            ? 'Reconnecting (next in ${connection.nextDelay!.inSeconds}s)…'
            : 'Reconnecting…',
        attempt: connection.attempt,
        nextDelay: connection.nextDelay,
      ),

      MidiConnectionPhase.bluetoothUnavailable => MidiConnectionPresentation(
        phase: MidiConnectionPhase.bluetoothUnavailable,
        label: 'Bluetooth unavailable',
        detail: connection.message ?? 'Bluetooth unavailable',
        message: connection.message,
      ),

      MidiConnectionPhase.deviceUnavailable => MidiConnectionPresentation(
        phase: MidiConnectionPhase.deviceUnavailable,
        label: 'Device unavailable',
        detail: connection.message ?? 'Device unavailable',
        message: connection.message,
      ),

      MidiConnectionPhase.error => MidiConnectionPresentation(
        phase: MidiConnectionPhase.error,
        label: 'Error',
        detail: connection.message ?? 'Error',
        message: connection.message,
      ),

      MidiConnectionPhase.idle => const MidiConnectionPresentation(
        phase: MidiConnectionPhase.idle,
        label: 'Not connected',
        detail: 'Not connected',
      ),
    };
  },
);
