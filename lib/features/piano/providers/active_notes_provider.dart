import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/input/input.dart';
import 'package:whatchord/features/midi/midi.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../models/active_note.dart';

final activeNotesProvider = Provider<List<ActiveNote>>((ref) {
  final midis = ref.watch(soundingNotesSortedProvider);
  if (midis.isEmpty) return const <ActiveNote>[];

  final sustained = ref.watch(midiNoteStateProvider.select((s) => s.sustained));

  // Generic pitch-class names (fallback in non-chord modes).
  final pcNames = ref.watch(pitchClassNamesProvider);

  // Role-aware chord spellings (empty map outside chord mode / no best chord).
  final chordNamesByPc = ref.watch(chordMemberSpellingsByPcProvider);

  return List<ActiveNote>.unmodifiable([
    for (final midi in midis)
      ActiveNote(
        midiNote: midi,
        label: chordNamesByPc[midi % 12] ?? pcNames[midi % 12],
        isSustained: sustained.contains(midi),
      ),
  ]);
});
