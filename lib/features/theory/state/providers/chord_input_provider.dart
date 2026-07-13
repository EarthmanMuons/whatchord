import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatchord_theory/whatchord_theory.dart';

import 'package:whatchord/features/input/input.dart';
import 'package:whatchord/features/lookup/lookup.dart';

/// Converts currently sounding notes into a minimal [ChordInput].
final chordInputProvider = Provider<ChordInput?>((ref) {
  final midis = ref.watch(soundingNoteNumbersSortedProvider);
  if (midis.isEmpty) return null;

  final pcMask = _pcMaskFrom(midis);

  final bassMidi = midis.first;
  final bassPc = bassMidi % 12;

  return ChordInput(pcMask: pcMask, bassPc: bassPc, noteCount: midis.length);
});

/// Voicing evidence for the current notes, or null when there is none to act
/// on.
///
/// Only real octaves carry usable evidence. Manual lookup synthesizes octaves
/// for the user, so it supplies no voicing.
final observedVoicingProvider = Provider<ObservedVoicing?>((ref) {
  if (ref.watch(lookupActiveProvider)) return null;

  final midis = ref.watch(soundingNoteNumbersSortedProvider);
  if (midis.length < 2) return null;

  return ObservedVoicing.fromMidi(midis);
});

// Converts a collection of notes into a pitch-class bitmask (bits 0..11).
int _pcMaskFrom(Iterable<int> notes) {
  var mask = 0;
  for (final n in notes) {
    mask |= 1 << (n % 12);
  }
  return mask;
}
