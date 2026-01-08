import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/theory/theory.dart'
    show pitchClassNamesProvider;
import 'package:what_chord/features/midi/midi.dart'
    show midiNoteStateProvider, soundingMidiNotesSortedProvider;

import '../models/active_note.dart';

final activeNotesProvider = Provider<List<ActiveNote>>((ref) {
  final midis = ref.watch(soundingMidiNotesSortedProvider);
  final sustained = ref.watch(midiNoteStateProvider.select((s) => s.sustained));
  final pcNames = ref.watch(pitchClassNamesProvider);

  if (midis.isEmpty) return const <ActiveNote>[];

  return List<ActiveNote>.unmodifiable([
    for (final midi in midis)
      ActiveNote(
        midiNote: midi,
        label: pcNames[midi % 12],
        isSustained: sustained.contains(midi),
      ),
  ]);
});
