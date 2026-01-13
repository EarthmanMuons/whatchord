import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/core/input/sounding_notes_providers.dart';

import '../engine/models/chord_input.dart';
import '../engine/utils/pitch_class_mask.dart';

/// Converts currently sounding notes into a minimal [ChordInput].
final chordInputProvider = Provider<ChordInput?>((ref) {
  final midis = ref.watch(soundingNotesSortedProvider);
  if (midis.isEmpty) return null;

  final pcMask = pcMaskFromMidiNotes(midis);

  final bassMidi = midis.first;
  final bassPc = bassMidi % 12;

  return ChordInput(pcMask: pcMask, bassPc: bassPc, noteCount: midis.length);
});
