import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/theory_domain.dart';
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

final nearTieChordCandidatesProvider = Provider<List<ChordCandidate>>((ref) {
  final candidates = ref.watch(chordCandidatesProvider);
  if (candidates.length < 2) return const <ChordCandidate>[];

  final best = candidates.first;
  final out = <ChordCandidate>[];

  for (var i = 1; i < candidates.length; i++) {
    final c = candidates[i];
    final scoreDelta = best.score - c.score;

    // Once we exceed the window, later candidates will not qualify.
    if (scoreDelta.abs() > ChordCandidateRanking.nearTieWindow) break;

    out.add(c);
  }

  return out;
});
