import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bluetooth_state.dart';
import '../models/midi_device.dart';
import '../providers/midi_service_providers.dart';

/// Stream of available MIDI devices.
final availableMidiDevicesProvider = StreamProvider<List<MidiDevice>>((ref) {
  final service = ref.watch(midiServiceProvider);
  return service.availableDevices;
});

/// Stream of the currently connected device.
final connectedMidiDeviceProvider = StreamProvider<MidiDevice?>((ref) {
  final service = ref.watch(midiServiceProvider);
  return service.connectedDeviceStream;
});

/// Stream of Bluetooth adapter state.
final bluetoothStateProvider = StreamProvider<BluetoothState>((ref) {
  final service = ref.watch(midiServiceProvider);
  return service.bluetoothState;
});
