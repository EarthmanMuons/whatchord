import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/demo/demo.dart';

import '../models/bluetooth_unavailability.dart';
import '../models/midi_connection_status.dart';
import '../models/midi_connection.dart';
import 'midi_connection_notifier.dart';

/// Provides UI-friendly presentation of MIDI connection information.
final midiConnectionStatusProvider = Provider<MidiConnectionStatus>((ref) {
  final demoEnabled = ref.watch(demoModeProvider);
  if (demoEnabled) {
    return const MidiConnectionStatus(
      phase: MidiConnectionPhase.connected,
      title: 'Connected',
      subtitle: 'Connected to Demo MIDI',
      deviceName: 'Demo MIDI',
    );
  }

  final connectionState = ref.watch(midiConnectionStateProvider);
  final name = connectionState.deviceDisplayName;

  return switch (connectionState.phase) {
    MidiConnectionPhase.connected => MidiConnectionStatus(
      phase: connectionState.phase,
      title: 'Connected',
      subtitle: name != null ? 'Connected to $name' : 'Connected',
      deviceName: name,
    ),

    MidiConnectionPhase.connecting => const MidiConnectionStatus(
      phase: MidiConnectionPhase.connecting,
      title: 'Connecting…',
      subtitle: 'Connecting…',
    ),

    MidiConnectionPhase.retrying => MidiConnectionStatus(
      phase: MidiConnectionPhase.retrying,
      title: 'Reconnecting…',
      subtitle: connectionState.nextDelay != null
          ? 'Reconnecting (next in ${connectionState.nextDelay!.inSeconds}s)…'
          : 'Reconnecting…',
      attempt: connectionState.attempt,
      nextDelay: connectionState.nextDelay,
    ),

    MidiConnectionPhase.bluetoothUnavailable => () {
      final reason = connectionState.unavailability;
      final isPerm =
          reason == BluetoothUnavailability.permissionPermanentlyDenied;

      final label = switch (reason) {
        BluetoothUnavailability.adapterOff => 'Bluetooth is off',
        BluetoothUnavailability.permissionDenied ||
        BluetoothUnavailability.permissionPermanentlyDenied =>
          'Permissions required',
        BluetoothUnavailability.unsupported => 'Bluetooth unsupported',
        BluetoothUnavailability.notReady || null => 'Bluetooth unavailable',
      };

      final detail = switch (reason) {
        BluetoothUnavailability.adapterOff =>
          'Turn on Bluetooth to discover and connect to MIDI devices.',
        BluetoothUnavailability.permissionDenied =>
          Platform.isAndroid
              ? 'Allow the Nearby devices permission to scan and connect to Bluetooth MIDI devices.'
              : 'Allow Bluetooth access to discover and connect to Bluetooth MIDI devices.',
        BluetoothUnavailability.permissionPermanentlyDenied =>
          Platform.isAndroid
              ? 'Enable the Nearby devices permission in system settings for this app.'
              : 'Enable Bluetooth access for this app in system settings.',
        BluetoothUnavailability.unsupported =>
          'This device does not support Bluetooth.',
        BluetoothUnavailability.notReady ||
        null => 'Bluetooth is not ready yet. Try again.',
      };

      return MidiConnectionStatus(
        phase: MidiConnectionPhase.bluetoothUnavailable,
        title: label,
        subtitle: detail,
        diagnosticMessage: connectionState.message,
        unavailability: reason,
        canOpenSettings: isPerm,
      );
    }(),

    MidiConnectionPhase.deviceUnavailable => MidiConnectionStatus(
      phase: MidiConnectionPhase.deviceUnavailable,
      title: 'Device unavailable',
      subtitle: connectionState.message ?? 'Device unavailable',
      diagnosticMessage: connectionState.message,
    ),

    MidiConnectionPhase.error => MidiConnectionStatus(
      phase: MidiConnectionPhase.error,
      title: 'Error',
      subtitle: connectionState.message ?? 'Error',
      diagnosticMessage: connectionState.message,
    ),

    MidiConnectionPhase.idle => const MidiConnectionStatus(
      phase: MidiConnectionPhase.idle,
      title: 'Not connected',
      subtitle: 'Not connected',
    ),
  };
});
