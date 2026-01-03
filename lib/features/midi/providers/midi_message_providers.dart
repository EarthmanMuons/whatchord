import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/midi_message.dart';
import '../providers/midi_service_providers.dart';

/// Stream of raw MIDI data packets.
final midiRawDataProvider = StreamProvider<Uint8List>((ref) {
  final service = ref.watch(midiServiceProvider);
  return service.midiDataStream;
});

/// Stream of parsed MIDI messages.
final midiMessageProvider = StreamProvider<MidiMessage>((ref) {
  final service = ref.watch(midiServiceProvider);
  return service.midiDataStream.expand(MidiParser.parseMany);
});
