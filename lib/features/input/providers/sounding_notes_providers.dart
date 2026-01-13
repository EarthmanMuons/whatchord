import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/demo/demo.dart' show demoModeProvider;

import '../adapters/demo_input_adapter.dart';
import '../adapters/midi_input_adapter.dart';

/// The unified source of truth for "what notes are currently down," regardless of input source.
final soundingNotesProvider = Provider<Set<int>>((ref) {
  final demoEnabled = ref.watch(demoModeProvider);

  final notes = demoEnabled
      ? ref.watch(demoNotesSource)
      : ref.watch(midiNotesSource);

  return UnmodifiableSetView(notes);
});

/// Sorted sounding notes (e.g. bassMidi = first),
final soundingNotesSortedProvider = Provider<UnmodifiableListView<int>>((ref) {
  final notes = ref.watch(soundingNotesProvider);
  final sorted = notes.toList()..sort();
  return UnmodifiableListView(sorted);
});
