import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/input/input.dart';
import 'package:whatchord/features/lookup/lookup.dart';

import '../../domain/theory_domain.dart';

/// Converts currently sounding notes into a minimal [ChordInput].
final chordInputProvider = Provider<ChordInput?>((ref) {
  final midis = ref.watch(soundingNoteNumbersSortedProvider);
  if (midis.isEmpty) return null;

  final pcMask = _pcMaskFrom(midis);

  final bassMidi = midis.first;
  final bassPc = bassMidi % 12;

  return ChordInput(pcMask: pcMask, bassPc: bassPc, noteCount: midis.length);
});

/// Register/spread evidence for the current voicing, or null when there is none
/// to act on.
///
/// During manual lookup the octaves are synthesized for the user, so the
/// voicing is flagged as not intentional: it still flows through (its ordering
/// may feed future signals) but register-magnitude evidence is skipped.
final observedVoicingProvider = Provider<ObservedVoicing?>((ref) {
  final midis = ref.watch(soundingNoteNumbersSortedProvider);
  if (midis.length < 2) return null;

  final intentional = !ref.watch(lookupActiveProvider);
  return ObservedVoicing.fromMidi(midis, intentionalRegisters: intentional);
});

// Converts a collection of notes into a pitch-class bitmask (bits 0..11).
int _pcMaskFrom(Iterable<int> notes) {
  var mask = 0;
  for (final n in notes) {
    mask |= 1 << (n % 12);
  }
  return mask;
}
