import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bluetooth_state.dart';
import '../models/midi_device.dart';
import '../models/midi_message.dart';
import '../providers/midi_preferences_provider.dart';
import '../services/flutter_midi_service.dart';
import '../services/midi_service.dart';

/// Provider for the active MIDI service.
final midiServiceProvider = Provider<MidiService>((ref) {
  final service = FlutterMidiService();

  // Ensure disposal
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider that manages MIDI service initialization.
final midiServiceInitProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(midiServiceProvider);

  try {
    return await service.initialize();
  } catch (e) {
    debugPrint('MIDI initialization failed: $e');
    return false;
  }
});

/// Stream of available MIDI devices.
final availableMidiDevicesProvider = StreamProvider<List<MidiDevice>>((ref) {
  final service = ref.watch(midiServiceProvider);
  return service.availableDevices;
});

/// Stream of raw MIDI data packets.
final midiDataStreamProvider = StreamProvider<Uint8List>((ref) {
  final service = ref.watch(midiServiceProvider);
  return service.midiDataStream;
});

/// Stream of parsed MIDI messages.
final midiMessageStreamProvider = StreamProvider<MidiMessage>((ref) {
  final service = ref.watch(midiServiceProvider);

  // Expand each raw packet into zero or more MidiMessage values.
  return service.midiDataStream.expand(MidiParser.parseMany);
});

/// Stream of Bluetooth adapter state.
final bluetoothStateStreamProvider = StreamProvider<BluetoothState>((ref) {
  final service = ref.watch(midiServiceProvider);
  return service.bluetoothState;
});

/// Provider for the currently connected MIDI device.
final connectedMidiDeviceProvider = StreamProvider<MidiDevice?>((ref) {
  final service = ref.watch(midiServiceProvider);
  return service.connectedDeviceStream;
});

/// Provider for MIDI connection actions.
final midiConnectionActionsProvider = Provider<MidiConnectionActions>((ref) {
  return MidiConnectionActions(ref);
});

class MidiConnectionActions {
  final Ref _ref;

  const MidiConnectionActions(this._ref);

  MidiService get _service => _ref.read(midiServiceProvider);

  /// Ensure service is initialized before performing action.
  Future<void> _ensureInitialized() async {
    final initialized = await _ref.read(midiServiceInitProvider.future);
    if (!initialized) {
      throw const MidiException('Failed to initialize MIDI service');
    }
  }

  /// Start scanning for devices.
  Future<void> startScanning() async {
    await _ensureInitialized();
    await _service.startScanning();
  }

  /// Stop scanning for devices.
  Future<void> stopScanning() async {
    await _service.stopScanning();
  }

  /// Connect to a device and save it as the last connected device.
  Future<void> connect(MidiDevice device) async {
    await _ensureInitialized();
    await _service.connect(device);
  }

  /// Disconnect from the current device.
  Future<void> disconnect() async {
    await _service.disconnect();
  }

  /// Manually trigger a reconnection attempt.
  Future<bool> reconnect() async {
    await _ensureInitialized();
    final prefs = _ref.read(midiPreferencesProvider);
    final lastDeviceId = prefs.lastDeviceId;

    if (lastDeviceId == null) return false;

    return _service.reconnect(lastDeviceId);
  }
}
