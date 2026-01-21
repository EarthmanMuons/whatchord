import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/midi_connection.dart';
import '../models/midi_connection_status.dart';
import '../models/midi_unavailable_reason.dart';
import 'midi_connection_notifier.dart';

/// Provides UI-friendly presentation of MIDI connection information.
final midiConnectionStatusProvider = Provider<MidiConnectionStatus>((ref) {
  final connection = ref.watch(midiConnectionProvider);
  final name = connection.deviceDisplayName;

  return switch (connection.phase) {
    MidiConnectionPhase.connected => MidiConnectionStatus(
      phase: connection.phase,
      label: 'Connected',
      detail: name != null ? 'Connected to $name' : 'Connected',
      deviceName: name,
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

    MidiConnectionPhase.bluetoothUnavailable => () {
      final r = connection.unavailableReason;

      final isAndroid = Platform.isAndroid;
      final isPerm =
          r == MidiUnavailableReason.bluetoothPermissionPermanentlyDenied;

      final label = switch (r) {
        MidiUnavailableReason.bluetoothOff => 'Bluetooth is off',
        MidiUnavailableReason.bluetoothPermissionDenied ||
        MidiUnavailableReason.bluetoothPermissionPermanentlyDenied =>
          isAndroid
              ? 'Nearby devices permission required'
              : 'Bluetooth permission required',
        MidiUnavailableReason.bluetoothUnsupported => 'Bluetooth unsupported',
        MidiUnavailableReason.bluetoothNotReady ||
        null => 'Bluetooth unavailable',
      };

      final detail = switch (r) {
        MidiUnavailableReason.bluetoothOff =>
          'Turn on Bluetooth to discover and connect to MIDI devices.',
        MidiUnavailableReason.bluetoothPermissionDenied =>
          isAndroid
              ? 'Allow the Nearby devices permission to scan and connect to BLE MIDI devices.'
              : 'Allow Bluetooth access to discover and connect to BLE MIDI devices.',
        MidiUnavailableReason.bluetoothPermissionPermanentlyDenied =>
          isAndroid
              ? 'Enable the Nearby devices permission in system settings for this app.'
              : 'Enable Bluetooth access for this app in system settings.',
        MidiUnavailableReason.bluetoothUnsupported =>
          'This device does not support Bluetooth.',
        MidiUnavailableReason.bluetoothNotReady ||
        null => 'Bluetooth is not ready yet. Try again.',
      };

      return MidiConnectionStatus(
        phase: MidiConnectionPhase.bluetoothUnavailable,
        label: label,
        detail: detail,
        message: connection.message,
        unavailableReason: r,
        canOpenSettings: isPerm,
      );
    }(),

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
