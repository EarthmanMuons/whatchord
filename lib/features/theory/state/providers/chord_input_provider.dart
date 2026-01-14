import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/input/input.dart';

import '../../domain/theory_domain.dart';

/// Converts currently sounding notes into a minimal [ChordInput].
final chordInputProvider = Provider<ChordInput?>((ref) {
  final midis = ref.watch(soundingNotesSortedProvider);
  if (midis.isEmpty) return null;

  final pcMask = _pcMaskFrom(midis);

  final bassMidi = midis.first;
  final bassPc = bassMidi % 12;

  return ChordInput(pcMask: pcMask, bassPc: bassPc, noteCount: midis.length);
});

// Converts a collection of notes into a pitch-class bitmask (bits 0..11).
int _pcMaskFrom(Iterable<int> notes) {
  var mask = 0;
  for (final n in notes) {
    mask |= 1 << (n % 12);
  }
  return mask;
}
