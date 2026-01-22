import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/midi_message.dart';
import 'midi_manager.dart';

/// Stream of raw MIDI data packets.
final midiRawDataProvider = StreamProvider<Uint8List>((ref) {
  return ref.watch(_midiRawStreamProvider);
});

/// Stream of parsed MIDI messages.
final midiMessageProvider = StreamProvider<MidiMessage>((ref) {
  final raw = ref.watch(_midiRawStreamProvider);
  return raw.expand(MidiParser.parseMany);
});

final _midiRawStreamProvider = Provider<Stream<Uint8List>>((ref) {
  final midi = ref.watch(midiCommandProvider);
  return midi.onMidiDataReceived?.map(
        (packet) => Uint8List.fromList(packet.data),
      ) ??
      const Stream<Uint8List>.empty();
});
