import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/demo/demo.dart' show demoModeProvider;

import '../adapters/demo_input_adapter.dart';
import '../adapters/midi_input_adapter.dart';
import '../models/input_note_event.dart';

final inputNoteEventsProvider = StreamProvider<InputNoteEvent>((ref) {
  final demoEnabled = ref.watch(demoModeProvider);

  final source = demoEnabled ? demoNoteEventsSource : midiNoteEventsSource;
  return ref.watch(source);
});
