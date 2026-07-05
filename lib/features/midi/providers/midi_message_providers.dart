import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/midi_message.dart';
import 'midi_ble_service_provider.dart';

/// Stream of parsed MIDI messages.
final midiMessageProvider = StreamProvider<MidiMessage>((ref) {
  final ble = ref.watch(midiBleServiceProvider);
  return ble.onMidiMessages;
});
