import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bluetooth_state.dart';
import '../models/midi_device.dart';
import '../providers/midi_service_providers.dart';

final availableMidiDevicesProvider = StreamProvider<List<MidiDevice>>((ref) {
  return ref.watch(midiServiceProvider).availableDevices;
});

final connectedMidiDeviceProvider = StreamProvider<MidiDevice?>((ref) {
  return ref.watch(midiServiceProvider).connectedDeviceStream;
});

final bluetoothStateProvider = StreamProvider<BluetoothState>((ref) {
  return ref.watch(midiServiceProvider).bluetoothState;
});
