import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/demo/demo.dart' show demoModeProvider;
import 'package:whatchord/features/midi/midi.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../models/sounding_note.dart';
import 'sounding_note_numbers_providers.dart';

final sustainedNoteNumbersProvider = Provider<Set<int>>((ref) {
  final demoEnabled = ref.watch(demoModeProvider);
  if (demoEnabled) return const <int>{};
  return ref.watch(midiNoteStateProvider.select((s) => s.sustained));
});

final soundingNotesProvider = Provider<List<SoundingNote>>((ref) {
  final midis = ref.watch(soundingNoteNumbersSortedProvider);
  if (midis.isEmpty) return const <SoundingNote>[];

  final sustained = ref.watch(sustainedNoteNumbersProvider);

  // Generic pitch-class names (fallback in non-chord modes).
  final pcNames = ref.watch(pitchClassNamesProvider);

  // Role-aware chord spellings (empty map outside chord mode / no best chord).
  final chordNamesByPc = ref.watch(chordMemberSpellingsByPcProvider);

  return List<SoundingNote>.unmodifiable([
    for (final midi in midis)
      SoundingNote(
        noteNumber: midi,
        label: chordNamesByPc[midi % 12] ?? pcNames[midi % 12],
        isSustained: sustained.contains(midi),
      ),
  ]);
});
