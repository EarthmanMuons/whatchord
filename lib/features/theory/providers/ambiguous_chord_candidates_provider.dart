import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/chord_candidate_ranking.dart';
import '../engine/models/chord_candidate.dart';
import 'chord_analysis_providers.dart';

final ambiguousChordCandidatesProvider = Provider<List<ChordCandidate>>((ref) {
  final candidates = ref.watch(chordCandidatesProvider);
  if (candidates.length < 2) return const <ChordCandidate>[];

  final best = candidates.first;
  final out = <ChordCandidate>[];

  for (var i = 1; i < candidates.length; i++) {
    final c = candidates[i];

    // Near-tie check against the winner's score.
    final scoreDelta = best.score - c.score;
    if (scoreDelta.abs() > ChordCandidateRanking.nearTieWindow) break;

    out.add(c);
    if (out.length == 3) break;
  }

  return out;
});
