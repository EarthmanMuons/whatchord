import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/chord_analyzer.dart';
import '../engine/models/chord_candidate.dart';
import 'analysis_context_provider.dart';
import 'analysis_mode_provider.dart';
import 'chord_input_provider.dart';

final chordCandidatesProvider = Provider<List<ChordCandidate>>((ref) {
  final input = ref.watch(chordInputProvider);
  if (input == null) return const <ChordCandidate>[];

  final mode = ref.watch(analysisModeProvider);
  if (mode != AnalysisMode.chord) return const <ChordCandidate>[];

  final context = ref.watch(analysisContextProvider);
  return ChordAnalyzer.analyze(input, context: context);
});

final bestChordCandidateProvider = Provider<ChordCandidate?>((ref) {
  final candidates = ref.watch(chordCandidatesProvider);
  return candidates.isNotEmpty ? candidates.first : null;
});
