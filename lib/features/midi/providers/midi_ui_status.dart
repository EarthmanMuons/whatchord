import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'midi_link_manager.dart';

@immutable
class MidiUiStatus {
  final MidiLinkPhase phase;
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

  bool get isConnected => phase == MidiLinkPhase.connected;
}

final midiUiStatusProvider = Provider<MidiUiStatus>((ref) {
  final link = ref.watch(midiLinkManagerProvider);

  return switch (link.phase) {
    MidiLinkPhase.connected => MidiUiStatus(
      phase: link.phase,
      label: 'Connected',
      detail: link.device?.name.trim().isNotEmpty == true
          ? 'Connected to ${link.device!.name.trim()}'
          : 'Connected',
      deviceName: link.device?.name,
      keepAwake: true,
    ),

    MidiLinkPhase.connecting => const MidiUiStatus(
      phase: MidiLinkPhase.connecting,
      label: 'Connecting…',
      detail: 'Connecting…',
      keepAwake: true,
    ),

    MidiLinkPhase.retrying => MidiUiStatus(
      phase: MidiLinkPhase.retrying,
      label: 'Reconnecting…',
      detail: link.nextDelay != null
          ? 'Reconnecting (next in ${link.nextDelay!.inSeconds}s)…'
          : 'Reconnecting…',
      keepAwake: true,
      attempt: link.attempt,
      nextDelay: link.nextDelay,
    ),

    MidiLinkPhase.bluetoothUnavailable => MidiUiStatus(
      phase: MidiLinkPhase.bluetoothUnavailable,
      label: 'Bluetooth unavailable',
      detail: link.message ?? 'Bluetooth unavailable',
      keepAwake: false,
      message: link.message,
    ),

    MidiLinkPhase.deviceUnavailable => MidiUiStatus(
      phase: MidiLinkPhase.deviceUnavailable,
      label: 'Device unavailable',
      detail: link.message ?? 'Device unavailable',
      keepAwake: false,
      message: link.message,
    ),

    MidiLinkPhase.error => MidiUiStatus(
      phase: MidiLinkPhase.error,
      label: 'Error',
      detail: link.message ?? 'Error',
      keepAwake: false,
      message: link.message,
    ),

    MidiLinkPhase.idle => const MidiUiStatus(
      phase: MidiLinkPhase.idle,
      label: 'Not connected',
      detail: 'Not connected',
      keepAwake: false,
    ),
  };
});
