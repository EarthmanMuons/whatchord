import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord_app/features/demo/demo.dart';
import 'package:whatchord_app/features/lookup/lookup.dart';

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
/// regardless of input source. Lookup and demo override live MIDI when active.
/// A lookup pad with notes always wins; an empty pad opened during a tour does
/// not blank the card, so the demo keeps driving it until the first note is
/// tapped (which ends the tour).
final soundingNoteNumbersProvider = Provider<Set<int>>((ref) {
  if (ref.watch(lookupActiveProvider)) {
    final lookupNotes = ref.watch(lookupNoteNumbersProvider);
    if (lookupNotes.isNotEmpty || !ref.watch(demoModeProvider)) {
      return UnmodifiableSetView(lookupNotes);
    }
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
