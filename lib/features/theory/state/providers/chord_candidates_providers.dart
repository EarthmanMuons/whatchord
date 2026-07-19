import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatchord/whatchord.dart';

import 'analysis_context_provider.dart';
import 'analysis_mode_provider.dart';
import 'chord_analyzer_provider.dart';
import 'chord_input_provider.dart';

const _rankingDetailsCandidateLimit = 5;

final chordCandidatesProvider = Provider<List<ChordCandidate>>((ref) {
  final input = ref.watch(chordInputProvider);
  if (input == null) return const <ChordCandidate>[];

  final mode = ref.watch(analysisModeProvider);
  if (mode != AnalysisMode.chord) return const <ChordCandidate>[];

  final context = ref.watch(analysisContextProvider);
  final voicing = ref.watch(observedVoicingProvider);
  final analyzer = ref.watch(chordAnalyzerProvider);
  return analyzer.analyze(input, context: context, voicing: voicing);
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

final rankedChordCandidateDebugProvider = Provider<List<ExplainedCandidate>>((
  ref,
) {
  final input = ref.watch(chordInputProvider);
  if (input == null) return const <ExplainedCandidate>[];

  final mode = ref.watch(analysisModeProvider);
  if (mode != AnalysisMode.chord) return const <ExplainedCandidate>[];

  final context = ref.watch(analysisContextProvider);
  final voicing = ref.watch(observedVoicingProvider);
  return ref
      .watch(chordAnalyzerProvider)
      .explain(
        input,
        context: context,
        voicing: voicing,
        take: _rankingDetailsCandidateLimit,
      );
});
