import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/core/utils/utils.dart' show pcMaskFromMidiNotes;
import 'package:what_chord/features/midi/midi.dart';

import '../engine/models/chord_input.dart';

/// Converts currently sounding MIDI notes into a minimal [ChordInput].
/// Adapter boundary: keeps the analysis engine (features/theory/engine) MIDI-agnostic.
final chordInputProvider = Provider<ChordInput?>((ref) {
  final midis = ref.watch(soundingMidiNotesSortedProvider);
  if (midis.isEmpty) return null;

  final pcMask = pcMaskFromMidiNotes(midis);

  final bassMidi = midis.first;
  final bassPc = bassMidi % 12;

  return ChordInput(pcMask: pcMask, bassPc: bassPc, noteCount: midis.length);
});
