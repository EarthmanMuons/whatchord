import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/demo/demo.dart';

import '../models/ble_unavailability.dart';
import '../models/midi_connection_status.dart';
import '../models/midi_connection.dart';
import 'midi_connection_notifier.dart';

/// Provides UI-friendly presentation of MIDI connection information.
final midiConnectionStatusProvider = Provider<MidiConnectionStatus>((ref) {
  final demoEnabled = ref.watch(demoModeProvider);
  if (demoEnabled) {
    return const MidiConnectionStatus(
      phase: MidiConnectionPhase.connected,
      label: 'Connected',
      detail: 'Connected to Demo MIDI',
      deviceName: 'Demo MIDI',
    );
  }

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
      final reason = connection.unavailability;
      final isPerm = reason == BleUnavailability.permissionPermanentlyDenied;

      final label = switch (reason) {
        BleUnavailability.adapterOff => 'Bluetooth is off',
        BleUnavailability.permissionDenied ||
        BleUnavailability.permissionPermanentlyDenied => 'Permissions required',
        BleUnavailability.unsupported => 'Bluetooth unsupported',
        BleUnavailability.notReady || null => 'Bluetooth unavailable',
      };

      final detail = switch (reason) {
        BleUnavailability.adapterOff =>
          'Turn on Bluetooth to discover and connect to MIDI devices.',
        BleUnavailability.permissionDenied =>
          Platform.isAndroid
              ? 'Allow the Nearby devices permission to scan and connect to BLE MIDI devices.'
              : 'Allow Bluetooth access to discover and connect to BLE MIDI devices.',
        BleUnavailability.permissionPermanentlyDenied =>
          Platform.isAndroid
              ? 'Enable the Nearby devices permission in system settings for this app.'
              : 'Enable Bluetooth access for this app in system settings.',
        BleUnavailability.unsupported =>
          'This device does not support Bluetooth.',
        BleUnavailability.notReady ||
        null => 'Bluetooth is not ready yet. Try again.',
      };

      return MidiConnectionStatus(
        phase: MidiConnectionPhase.bluetoothUnavailable,
        label: label,
        detail: detail,
        message: connection.message,
        unavailability: reason,
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
