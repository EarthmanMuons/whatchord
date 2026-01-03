import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bluetooth_state.dart';
import '../models/midi_device.dart';
import '../providers/midi_service_providers.dart';

/// Stream of available MIDI devices.
final availableMidiDevicesProvider = StreamProvider<List<MidiDevice>>((ref) {
  final service = ref.watch(midiServiceProvider);
  return service.availableDevices;
});

/// Synchronous view of the latest available MIDI devices list.
/// Falls back to an empty list if the stream hasn't emitted yet.
final availableMidiDevicesListProvider = Provider<List<MidiDevice>>((ref) {
  return ref.watch(availableMidiDevicesProvider).asData?.value ?? const [];
});

/// Stream of the currently connected device.
final connectedMidiDeviceProvider = StreamProvider<MidiDevice?>((ref) {
  final service = ref.watch(midiServiceProvider);
  return service.connectedDeviceStream;
});

/// Synchronous view of the latest connected device.
final connectedMidiDeviceValueProvider = Provider<MidiDevice?>((ref) {
  return ref.watch(connectedMidiDeviceProvider).asData?.value;
});

/// Whether we are currently connected (based on the connected-device stream).
final isMidiConnectedProvider = Provider<bool>((ref) {
  final device = ref.watch(connectedMidiDeviceValueProvider);
  return device?.isConnected == true;
});

/// Stream of Bluetooth adapter state.
final bluetoothStateProvider = StreamProvider<BluetoothState>((ref) {
  final service = ref.watch(midiServiceProvider);
  return service.bluetoothState;
});
