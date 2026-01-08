import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/midi_connection_status.dart';
import 'midi_connection_notifier.dart';

/// Provides UI-friendly presentation of MIDI connection information.
final midiConnectionStatusProvider = Provider<MidiConnectionStatus>((ref) {
  final connection = ref.watch(midiConnectionNotifierProvider);

  return switch (connection.phase) {
    MidiConnectionPhase.connected => MidiConnectionStatus(
      phase: connection.phase,
      label: 'Connected',
      detail: connection.device?.name.trim().isNotEmpty == true
          ? 'Connected to ${connection.device!.name.trim()}'
          : 'Connected',
      deviceName: connection.device?.name,
    ),

    MidiConnectionPhase.connecting => const MidiConnectionStatus(
      phase: MidiConnectionPhase.connecting,
      label: 'Connecting…',
      detail: 'Connecting…',
    ),

    MidiConnectionPhase.retrying => MidiConnectionStatus(
      phase: MidiConnectionPhase.retrying,
      label: 'Reconnecting…',
      detail: connection.nextDelay != null
          ? 'Reconnecting (next in ${connection.nextDelay!.inSeconds}s)…'
          : 'Reconnecting…',
      attempt: connection.attempt,
      nextDelay: connection.nextDelay,
    ),

    MidiConnectionPhase.bluetoothUnavailable => MidiConnectionStatus(
      phase: MidiConnectionPhase.bluetoothUnavailable,
      label: 'Bluetooth unavailable',
      detail: connection.message ?? 'Bluetooth unavailable',
      message: connection.message,
    ),

    MidiConnectionPhase.deviceUnavailable => MidiConnectionStatus(
      phase: MidiConnectionPhase.deviceUnavailable,
      label: 'Device unavailable',
      detail: connection.message ?? 'Device unavailable',
      message: connection.message,
    ),

    MidiConnectionPhase.error => MidiConnectionStatus(
      phase: MidiConnectionPhase.error,
      label: 'Error',
      detail: connection.message ?? 'Error',
      message: connection.message,
    ),

    MidiConnectionPhase.idle => const MidiConnectionStatus(
      phase: MidiConnectionPhase.idle,
      label: 'Not connected',
      detail: 'Not connected',
    ),
  };
});
