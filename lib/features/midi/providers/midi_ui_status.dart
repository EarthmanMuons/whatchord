import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'midi_connection_manager.dart';

@immutable
class MidiUiStatus {
  final MidiConnectionPhase phase;
  final String label; // short, pill/title-friendly
  final String? detail; // optional, settings subtitle-friendly
  final bool keepAwake;

  final int? attempt; // retry attempt #
  final Duration? nextDelay; // next retry delay
  final String? message; // error/capability reason
  final String? deviceName; // when connected

  const MidiUiStatus({
    required this.phase,
    required this.label,
    this.detail,
    required this.keepAwake,
    this.attempt,
    this.nextDelay,
    this.message,
    this.deviceName,
  });

  bool get isConnected => phase == MidiConnectionPhase.connected;
}

final midiUiStatusProvider = Provider<MidiUiStatus>((ref) {
  final connection = ref.watch(midiConnectionManagerProvider);

  return switch (connection.phase) {
    MidiConnectionPhase.connected => MidiUiStatus(
      phase: connection.phase,
      label: 'Connected',
      detail: connection.device?.name.trim().isNotEmpty == true
          ? 'Connected to ${connection.device!.name.trim()}'
          : 'Connected',
      deviceName: connection.device?.name,
      keepAwake: true,
    ),

    MidiConnectionPhase.connecting => const MidiUiStatus(
      phase: MidiConnectionPhase.connecting,
      label: 'Connecting…',
      detail: 'Connecting…',
      keepAwake: true,
    ),

    MidiConnectionPhase.retrying => MidiUiStatus(
      phase: MidiConnectionPhase.retrying,
      label: 'Reconnecting…',
      detail: connection.nextDelay != null
          ? 'Reconnecting (next in ${connection.nextDelay!.inSeconds}s)…'
          : 'Reconnecting…',
      keepAwake: true,
      attempt: connection.attempt,
      nextDelay: connection.nextDelay,
    ),

    MidiConnectionPhase.bluetoothUnavailable => MidiUiStatus(
      phase: MidiConnectionPhase.bluetoothUnavailable,
      label: 'Bluetooth unavailable',
      detail: connection.message ?? 'Bluetooth unavailable',
      keepAwake: false,
      message: connection.message,
    ),

    MidiConnectionPhase.deviceUnavailable => MidiUiStatus(
      phase: MidiConnectionPhase.deviceUnavailable,
      label: 'Device unavailable',
      detail: connection.message ?? 'Device unavailable',
      keepAwake: false,
      message: connection.message,
    ),

    MidiConnectionPhase.error => MidiUiStatus(
      phase: MidiConnectionPhase.error,
      label: 'Error',
      detail: connection.message ?? 'Error',
      keepAwake: false,
      message: connection.message,
    ),

    MidiConnectionPhase.idle => const MidiUiStatus(
      phase: MidiConnectionPhase.idle,
      label: 'Not connected',
      detail: 'Not connected',
      keepAwake: false,
    ),
  };
});
