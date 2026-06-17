import '../models/chord_candidate.dart';
import '../models/observed_voicing.dart';
import '../models/tonality.dart';
import 'candidate_features.dart';
import 'ranking_rules.dart';

class RankingDecision {
  final int result;
  final String? decidedByRule;
  final double scoreDelta;

  /// Whether [decidedByRule] was one of the hard rules (a score-independent
  /// override) rather than a near-tie tie-breaker. Used by [ChordCandidateRanking.rank]
  /// to keep override winners ahead of the candidates they override when the
  /// pairwise relation contains a cycle.
  final bool decidedByHardRule;

  const RankingDecision({
    required this.result,
    required this.decidedByRule,
    required this.scoreDelta,
    this.decidedByHardRule = false,
  });
}

/// Ranks chord candidates using score-based comparison with tie-breaking rules.
///
/// When scores are within [nearTieWindow], applies heuristics to choose the
/// most musically appropriate interpretation (e.g., preferring root position,
/// diatonic chords, natural extensions, etc.). The rules themselves, their
/// order, and the features they read live in `ranking_rules.dart` and
/// `candidate_features.dart`; this class is just the comparator and the
/// linearizer that turns pairwise decisions into a stable ranking.
///
/// NOTE: docs/site/articles/under-the-hood.html documents the ranking rules in
/// detail. Update the article when rules, their order, or nearTieWindow changes.
abstract final class ChordCandidateRanking {
  /// Score difference threshold for engaging tie-breaker rules.
  /// A value of 0.20 allows rules to resolve ambiguous interpretations
  /// without overriding clear score differences.
  static const double nearTieWindow = 0.20;

  /// Compares two candidates. Returns -1 if a ranks higher, 1 if b ranks higher.
  static int compare(
    ChordCandidate a,
    ChordCandidate b, {
    required Tonality tonality,
    ObservedVoicing? voicing,
  }) {
    return _decide(
      a,
      b,
      CandidateFeatures.from(a, voicing: voicing),
      CandidateFeatures.from(b, voicing: voicing),
      tonality: tonality,
    ).result;
  }

  /// Same as [compare], but returns detailed information about which rule decided.
  /// Useful for debugging and explaining ranking decisions to users.
  static RankingDecision explain(
    ChordCandidate a,
    ChordCandidate b, {
    required Tonality tonality,
    ObservedVoicing? voicing,
  }) {
    return _decide(
      a,
      b,
      CandidateFeatures.from(a, voicing: voicing),
      CandidateFeatures.from(b, voicing: voicing),
      tonality: tonality,
    );
  }

  /// Whether a candidate scoring [candidateScore] is a near-tie with the
  /// top-ranked candidate scoring [bestScore].
  ///
  /// The window is one-sided, anchored to the chosen #1: any candidate at or
  /// above `bestScore - nearTieWindow` qualifies. Because a hard rule can
  /// promote a lower-scoring reading to #1, a near-tie can legitimately score
  /// *higher* than the chosen chord, so this must not clamp the difference to
  /// its absolute value.
  static bool isNearTie(double bestScore, double candidateScore) =>
      bestScore - candidateScore <= nearTieWindow;

  /// Returns the near-tie alternatives from a [ranked] candidate list: every
  /// candidate after the top pick that [isNearTie] with it. Returns empty when
  /// there are fewer than two candidates.
  ///
  /// The whole list is filtered rather than stopped at the first candidate
  /// outside the window, because [rank] order is not strictly monotonic in
  /// score (tie-breakers can reorder near-ties).
  static List<ChordCandidate> nearTieAlternatives(List<ChordCandidate> ranked) {
    if (ranked.length < 2) return const <ChordCandidate>[];
    final bestScore = ranked.first.score;
    return [
      for (var i = 1; i < ranked.length; i++)
        if (isNearTie(bestScore, ranked[i].score)) ranked[i],
    ];
  }

  /// Orders [items] into a deterministic total ranking.
  ///
  /// [compare] is intentionally not transitive: hard rules and the near-tie
  /// window override raw score, so for some candidate sets the pairwise
  /// relation contains cycles (a > b > c > a). A plain `List.sort` is undefined
  /// on such a comparator and can bury a strong candidate below a weaker one.
  ///
  /// This linearizes the relation instead. Wherever [compare] is already a
  /// consistent order it reproduces that order exactly. Where it cycles, the
  /// cycle is broken deterministically: a candidate that loses a hard-rule edge
  /// to another remaining candidate is held back (so an override winner is
  /// never placed below the candidate it overrode), then the remaining tie is
  /// resolved by pairwise win count, score, and finally root pitch class.
  ///
  /// [candidateOf] extracts the [ChordCandidate] from each item so callers can
  /// rank wrappers (e.g. scored candidates carrying debug data) directly.
  static List<T> rank<T>(
    List<T> items,
    ChordCandidate Function(T) candidateOf, {
    required Tonality tonality,
    ObservedVoicing? voicing,
  }) {
    final n = items.length;
    if (n <= 1) return List<T>.of(items);

    final cands = [for (final it in items) candidateOf(it)];

    // Features (including any voicing evidence) are computed once per candidate
    // here, rather than rebuilt for each of the O(n^2) pairwise decisions below.
    final feats = [
      for (final c in cands) CandidateFeatures.from(c, voicing: voicing),
    ];

    // Seed order: score desc, then root pitch class asc. This both resolves
    // ties between mutually-equal candidates and seeds the cycle tie-break.
    final seeded = List<int>.generate(n, (i) => i)
      ..sort((a, b) {
        final byScore = cands[b].score.compareTo(cands[a].score);
        if (byScore != 0) return byScore;
        return cands[a].identity.rootPc.compareTo(cands[b].identity.rootPc);
      });

    // Precompute the pairwise relation once (O(n^2) decisions) so the
    // linearization itself is cheap integer/bool lookups.
    final beats = List.generate(n, (_) => List<bool>.filled(n, false));
    final hardBeats = List.generate(n, (_) => List<bool>.filled(n, false));
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        if (i == j) continue;
        final d = _decide(
          cands[i],
          cands[j],
          feats[i],
          feats[j],
          tonality: tonality,
        );
        if (d.result < 0) {
          beats[i][j] = true;
          if (d.decidedByHardRule) hardBeats[i][j] = true;
        }
      }
    }

    final remaining = seeded.toList();
    final result = <T>[];
    while (remaining.isNotEmpty) {
      final pos = _selectTopPosition(remaining, beats, hardBeats);
      result.add(items[remaining[pos]]);
      remaining.removeAt(pos);
    }
    return result;
  }

  /// Index within [remaining] (kept in seed order) of the next item to place.
  static int _selectTopPosition(
    List<int> remaining,
    List<List<bool>> beats,
    List<List<bool>> hardBeats,
  ) {
    final m = remaining.length;

    // A maximal element is beaten by no other remaining candidate. The first
    // one in seed order wins, which keeps the result stable.
    for (var a = 0; a < m; a++) {
      final i = remaining[a];
      var isBeaten = false;
      for (var b = 0; b < m; b++) {
        if (a == b) continue;
        if (beats[remaining[b]][i]) {
          isBeaten = true;
          break;
        }
      }
      if (!isBeaten) return a;
    }

    // No maximal element: the remaining set contains a cycle. Hold back any
    // candidate dominated by a hard-rule edge, then pick the one that beats the
    // most others (Copeland), falling back to seed order.
    var bestPos = -1;
    var bestWins = -1;
    for (var a = 0; a < m; a++) {
      final i = remaining[a];
      var heldBack = false;
      for (var b = 0; b < m; b++) {
        if (a == b) continue;
        if (hardBeats[remaining[b]][i]) {
          heldBack = true;
          break;
        }
      }
      if (heldBack) continue;

      var wins = 0;
      for (var b = 0; b < m; b++) {
        if (a == b) continue;
        if (beats[i][remaining[b]]) wins++;
      }
      if (wins > bestWins) {
        bestWins = wins;
        bestPos = a;
      }
    }

    // Every remaining candidate held back implies a hard-rule cycle, which the
    // rule set should never produce; fall back to seed order.
    return bestPos == -1 ? 0 : bestPos;
  }

  static RankingDecision _decide(
    ChordCandidate a,
    ChordCandidate b,
    CandidateFeatures fa,
    CandidateFeatures fb, {
    required Tonality tonality,
  }) {
    final delta = b.score - a.score;

    for (final rule in hardRules) {
      final r = rule.apply(a, b, fa, fb, tonality);
      if (r != null && r != 0) {
        return RankingDecision(
          result: r,
          decidedByRule: rule.name,
          scoreDelta: delta,
          decidedByHardRule: true,
        );
      }
    }

    if (delta.abs() > nearTieWindow) {
      final result = delta > 0 ? 1 : -1;
      // Named for the pairwise gap to the adjacent candidate, distinct from the
      // one-sided near-tie membership (see isNearTie). The score difference here
      // exceeds nearTieWindow, so tie-breakers are not engaged.
      return RankingDecision(
        result: result,
        decidedByRule: 'score difference beyond tie-break range',
        scoreDelta: delta,
      );
    }

    for (final rule in tieBreakerRules) {
      final r = rule.apply(a, b, fa, fb, tonality);
      if (r != null && r != 0) {
        return RankingDecision(
          result: r,
          decidedByRule: rule.name,
          scoreDelta: delta,
        );
      }
    }

    final finalResult = a.identity.rootPc.compareTo(b.identity.rootPc);
    return RankingDecision(
      result: finalResult,
      decidedByRule: 'deterministic fallback: rootPc',
      scoreDelta: delta,
    );
  }
}
