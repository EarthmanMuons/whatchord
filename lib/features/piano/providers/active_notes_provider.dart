import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/theory/theory.dart'
    show pitchClassNamesProvider;
import 'package:what_chord/features/midi/midi.dart' show midiNoteStateProvider;

import '../models/active_note.dart';

final activeNotesProvider = Provider<List<ActiveNote>>((ref) {
  final state = ref.watch(midiNoteStateProvider);
  final pcNames = ref.watch(pitchClassNamesProvider);

  final notes = <ActiveNote>[];
  final activeSorted = state.soundingNotes.toList()..sort();

  for (final midi in activeSorted) {
    notes.add(
      ActiveNote(
        midiNote: midi,
        label: pcNames[midi % 12],
        isSustained: state.sustained.contains(midi),
      ),
    );
  }

  return notes;
});
