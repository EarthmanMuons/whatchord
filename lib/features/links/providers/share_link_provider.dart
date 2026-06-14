import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/input/input.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../models/chord_link.dart';

/// A shareable website link for the current voicing and tonality, or null when
/// nothing is sounding (so the share affordance can disable itself).
final shareLinkProvider = Provider<Uri?>((ref) {
  final notes = ref.watch(soundingNoteNumbersSortedProvider);
  if (notes.isEmpty) return null;

  return ChordLink.build(
    orderedNotes: notes.toList(),
    tonality: ref.watch(selectedTonalityProvider),
  );
});
