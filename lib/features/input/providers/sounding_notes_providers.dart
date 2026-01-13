import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/demo/demo.dart';
import 'package:what_chord/features/midi/midi.dart';

/// The one provider the rest of the app should use for "what notes are down".
final soundingNotesProvider = Provider<Set<int>>((ref) {
  final demoEnabled = ref.watch(demoModeProvider);
  final notes = demoEnabled
      ? ref.watch(demoSoundingNotesProvider)
      : ref.watch(midiSoundingNotesProvider);

  return UnmodifiableSetView(notes);
});

/// Sorted sounding notes (e.g. bassMidi = first),
final soundingNotesSortedProvider = Provider<UnmodifiableListView<int>>((ref) {
  final notes = ref.watch(soundingNotesProvider);
  final sorted = notes.toList()..sort();
  return UnmodifiableListView(sorted);
});
