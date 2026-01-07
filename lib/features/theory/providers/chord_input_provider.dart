import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/midi/midi.dart';

import '../engine/models/chord_input.dart';

/// Converts currently sounding MIDI notes into a minimal [ChordInput].
/// Adapter boundary: keeps the analysis engine (features/theory/engine) MIDI-agnostic.
final chordInputProvider = Provider<ChordInput?>((ref) {
  final sounding = ref.watch(soundingMidiNotesProvider);
  if (sounding.isEmpty) return null;

  final sorted = sounding.toList()..sort();
  final bassMidi = sorted.first;
  final bassPc = bassMidi % 12;

  var mask = 0;
  for (final midi in sounding) {
    mask |= (1 << (midi % 12));
  }

  return ChordInput(pcMask: mask, bassPc: bassPc, noteCount: sounding.length);
});
