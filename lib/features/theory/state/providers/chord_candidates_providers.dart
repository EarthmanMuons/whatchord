import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/theory_domain.dart';
import 'analysis_context_provider.dart';
import 'analysis_mode_provider.dart';
import 'chord_input_provider.dart';

const _rankingDetailsCandidateLimit = 12;

final chordCandidatesProvider = Provider<List<ChordCandidate>>((ref) {
  final input = ref.watch(chordInputProvider);
  if (input == null) return const <ChordCandidate>[];

  final mode = ref.watch(analysisModeProvider);
  if (mode != AnalysisMode.chord) return const <ChordCandidate>[];

  final context = ref.watch(analysisContextProvider);
  final voicing = ref.watch(observedVoicingProvider);
  return ChordAnalyzer.analyze(input, context: context, voicing: voicing);
});

final bestChordCandidateProvider = Provider<ChordCandidate?>((ref) {
  final candidates = ref.watch(chordCandidatesProvider);
  return candidates.isNotEmpty ? candidates.first : null;
});

final alternativeChordCandidatesProvider = Provider<List<ChordCandidate>>((
  ref,
) {
  final candidates = ref.watch(chordCandidatesProvider);
  return ChordCandidateRanking.alternatives(candidates);
});

final rankedChordCandidateDebugProvider = Provider<List<RankedCandidateDebug>>((
  ref,
) {
  final input = ref.watch(chordInputProvider);
  if (input == null) return const <RankedCandidateDebug>[];

  final mode = ref.watch(analysisModeProvider);
  if (mode != AnalysisMode.chord) return const <RankedCandidateDebug>[];

  final context = ref.watch(analysisContextProvider);
  final voicing = ref.watch(observedVoicingProvider);
  return ChordAnalyzer.analyzeDebug(
    input,
    context: context,
    voicing: voicing,
    take: _rankingDetailsCandidateLimit,
  );
});
