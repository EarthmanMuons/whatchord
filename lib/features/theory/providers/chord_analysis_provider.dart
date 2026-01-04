import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/midi/midi.dart';

import '../engine/engine.dart';
import '../models/chord_analysis.dart';
import '../models/chord_symbol.dart';
import '../models/scale_degree.dart';
import '../providers/tonality_provider.dart';

final chordAnalysisProvider = Provider<ChordAnalysis>((ref) {
  return const ChordAnalysis(
    symbol: ChordSymbol(root: 'C', quality: 'maj', bass: 'E'),
    inversion: '1st inversion',
  );
});

final detectedScaleDegreeProvider = Provider<ScaleDegree?>((ref) {
  final tonality = ref.watch(selectedTonalityProvider);
  final analysis = ref.watch(chordAnalysisProvider);

  // Stub logic
  if (analysis.symbol.format().startsWith(tonality.label)) {
    return ScaleDegree.one;
  }
  return null;
});

/// Converts currently sounding MIDI notes into a minimal chord-analysis input.
final chordInputProvider = Provider<ChordInput?>((ref) {
  final state = ref.watch(midiNoteStateProvider);
  final sounding = state.soundingNotes;
  if (sounding.isEmpty) return null;

  // Determine bass from the lowest MIDI note number.
  final sorted = sounding.toList()..sort();
  final bassMidi = sorted.first;
  final bassPc = bassMidi % 12;

  // Compute 12-bit pitch-class mask.
  var mask = 0;
  for (final midi in sounding) {
    mask |= (1 << (midi % 12));
  }

  return ChordInput(pcMask: mask, bassPc: bassPc, noteCount: sounding.length);
});

/// Ranked candidates (best-first once Step 2 is implemented).
final chordCandidatesProvider = Provider<List<ChordCandidate>>((ref) {
  final input = ref.watch(chordInputProvider);
  if (input == null) return const <ChordCandidate>[];

  return ChordAnalyzer.analyze(input);
});

/// Quick debug string you can surface in dev UI while tuning.
final chordDebugStringProvider = Provider<String>((ref) {
  final input = ref.watch(chordInputProvider);
  if (input == null) return 'No notes';

  final maskHex = input.pcMask.toRadixString(16);
  return 'pcMask=0x$maskHex bassPc=${input.bassPc} notes=${input.noteCount}';
});
