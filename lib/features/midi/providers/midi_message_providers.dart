import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/midi_message.dart';
import '../services/flutter_midi_service.dart';

/// Stream of raw MIDI data packets.
final midiRawDataProvider = StreamProvider<Uint8List>((ref) {
  ref.watch(midiControllerProvider);

  final midi = ref.watch(midiCommandProvider);
  final stream = midi.onMidiDataReceived?.map(
    (packet) => Uint8List.fromList(packet.data),
  );

  return stream ?? const Stream<Uint8List>.empty();
});

/// Stream of parsed MIDI messages.
final midiMessageProvider = StreamProvider<MidiMessage>((ref) {
  ref.watch(midiControllerProvider);

  final midi = ref.watch(midiCommandProvider);
  final raw =
      midi.onMidiDataReceived?.map(
        (packet) => Uint8List.fromList(packet.data),
      ) ??
      const Stream<Uint8List>.empty();

  return raw.expand(MidiParser.parseMany);
});
