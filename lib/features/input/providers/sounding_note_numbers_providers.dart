import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/demo/demo.dart' show demoModeProvider;

import '../adapters/demo_input_adapter.dart';
import '../adapters/midi_input_adapter.dart';

/// The unified source of truth for "what note numbers are currently down,"
/// regardless of input source.
final soundingNoteNumbersProvider = Provider<Set<int>>((ref) {
  final demoEnabled = ref.watch(demoModeProvider);

  final notes = demoEnabled
      ? ref.watch(demoNoteNumbersSource)
      : ref.watch(midiNoteNumbersSource);

  return UnmodifiableSetView(notes);
});

/// Sorted sounding note numbers (e.g. bassMidi = first),
final soundingNoteNumbersSortedProvider = Provider<UnmodifiableListView<int>>((
  ref,
) {
  final notes = ref.watch(soundingNoteNumbersProvider);
  final sorted = notes.toList()..sort();
  return UnmodifiableListView(sorted);
});
