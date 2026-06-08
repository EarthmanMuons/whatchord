import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/demo/demo.dart';
import 'package:whatchord/features/lookup/lookup.dart';

import '../adapters/demo_input_adapter.dart';
import '../adapters/midi_input_adapter.dart';

/// Live input notes only (demo or MIDI), excluding manual lookup. The keyboard
/// watches this so it stays put when the lookup pad slides over it, rather than
/// re-centering on the lookup voicing.
final liveSoundingNoteNumbersProvider = Provider<Set<int>>((ref) {
  final demoEnabled = ref.watch(demoModeProvider);

  final notes = demoEnabled
      ? ref.watch(demoNoteNumbersSource)
      : ref.watch(midiNoteNumbersSource);

  return UnmodifiableSetView(notes);
});

/// The unified source of truth for "what note numbers are currently down,"
/// regardless of input source. Lookup, demo, and live MIDI are mutually
/// exclusive; lookup and demo override live MIDI when active.
final soundingNoteNumbersProvider = Provider<Set<int>>((ref) {
  if (ref.watch(lookupActiveProvider)) {
    return UnmodifiableSetView(ref.watch(lookupNoteNumbersProvider));
  }

  return ref.watch(liveSoundingNoteNumbersProvider);
});

/// Sorted sounding note numbers (e.g. bassMidi = first),
final soundingNoteNumbersSortedProvider = Provider<UnmodifiableListView<int>>((
  ref,
) {
  final notes = ref.watch(soundingNoteNumbersProvider);
  final sorted = notes.toList()..sort();
  return UnmodifiableListView(sorted);
});
