import '../models/chord_candidate.dart';
import '../models/observed_voicing.dart';
import '../models/tonality.dart';
import 'candidate_features.dart';
import 'chord_analysis_profile.dart';
import 'ranking_policy.dart' as ranking_policy;
import 'ranking_rules.dart';

/// The outcome of comparing two candidates, with the rule that decided it.
class RankingDecision {
  /// Comparator result: negative if the first candidate ranks higher,
  /// positive if the second does.
  final int result;

  /// Name of the tie-break or override rule that decided, or null when raw
  /// cost decided.
  final String? decidedByRule;

  /// Cost difference between the two candidates (first minus second).
  final double costDelta;

  /// Whether [decidedByRule] was one of the hard rules (a cost-independent
  /// override) rather than a near-tie tie-breaker. Used by [ChordCandidateRanking.rank]
  /// to keep override winners ahead of the candidates they override when the
  /// pairwise relation contains a cycle.
  final bool decidedByHardRule;

  const RankingDecision({
    required this.result,
    required this.decidedByRule,
    required this.costDelta,
    this.decidedByHardRule = false,
  });
}

/// Ranks chord candidates using cost-based comparison with tie-breaking rules.
///
/// When explanation costs are within [nearTieWindow], applies heuristics to choose the
/// most musically appropriate interpretation (e.g., preferring root position,
/// diatonic chords, natural extensions, etc.). The ordered rule lists live in
/// `ranking_rules.dart`, the rule functions in `rules/`, and the features they
/// read in `candidate_features.dart`; this class is just the comparator and
/// the linearizer that turns pairwise decisions into a stable ranking.
///
/// NOTE: https://whatchord.earthmanmuons.com/articles/chord-recognition-algorithm.html documents the
/// ranking rules in detail. Update the article when rules, their order, or
/// nearTieWindow changes.
abstract final class ChordCandidateRanking {
  /// Cost difference threshold for engaging tie-breaker rules.
  static const double nearTieWindow = ranking_policy.nearTieWindow;

  /// Every stable decision name that can appear in
  /// [RankingDecision.decidedByRule].
  ///
  /// Consumers use this to keep their explanations synchronized with the
  /// analyzer's ranking policy.
  static final Set<String> decisionRuleNames = Set<String>.unmodifiable({
    'cost difference beyond tie-break range',
    for (final rule in hardRules) rule.name,
    for (final rule in tieBreakerRules) rule.name,
    'deterministic fallback: rootPc',
  });

  /// Compares two candidates. Returns -1 if a ranks higher, 1 if b ranks higher.
  static int compare(
    ChordCandidate a,
    ChordCandidate b, {
    required Tonality tonality,
    ObservedVoicing? voicing,
    ChordAnalysisProfile profile = ChordAnalysisProfile.current,
  }) {
    return _decide(
      a,
      b,
      CandidateFeatures.from(a, voicing: voicing),
      CandidateFeatures.from(b, voicing: voicing),
      tonality: tonality,
      tieRules: _tieRules(profile),
    ).result;
  }

  /// Same as [compare], but returns detailed information about which rule decided.
  /// Useful for debugging and explaining ranking decisions to users.
  static RankingDecision explain(
    ChordCandidate a,
    ChordCandidate b, {
    required Tonality tonality,
    ObservedVoicing? voicing,
    ChordAnalysisProfile profile = ChordAnalysisProfile.current,
  }) {
    return _decide(
      a,
      b,
      CandidateFeatures.from(a, voicing: voicing),
      CandidateFeatures.from(b, voicing: voicing),
      tonality: tonality,
      tieRules: _tieRules(profile),
    );
  }

  /// Whether a candidate at [candidateCost] is a near-tie with the top-ranked
  /// candidate at [chosenCost]. Lower is better.
  ///
  /// The window is one-sided, anchored to the chosen #1: any candidate at or
  /// below `chosenCost + nearTieWindow` qualifies. Because a hard rule can
  /// promote a higher-cost reading to #1, a near-tie can legitimately cost
  /// *less* than the chosen chord, so this must not clamp the difference to
  /// its absolute value.
  static bool isNearTie(double chosenCost, double candidateCost) =>
      candidateCost - chosenCost <= nearTieWindow;

  /// Returns the alternatives from a [ranked] candidate list: the non-chosen
  /// readings close enough in cost to surface alongside the top pick.
  ///
  /// The near-tie cost window is anchored to the top pick, but [rank] order is
  /// not strictly monotonic in cost: tie-breakers can place a candidate
  /// outside the window above one that is inside it. To keep the surfaced
  /// alternatives coherent, include every ranked candidate through the last
  /// candidate that qualifies by cost.
  static List<ChordCandidate> alternatives(List<ChordCandidate> ranked) {
    final count = alternativeCount(ranked);
    if (count == 0) return const <ChordCandidate>[];
    return ranked.sublist(1, count + 1);
  }

  /// Number of ranked candidates after #1 that belong to the alternatives
  /// group.
  static int alternativeCount(List<ChordCandidate> ranked) {
    if (ranked.length < 2) return 0;
    final chosenCost = ranked.first.cost;
    var lastNearTieIndex = -1;
    for (var i = 1; i < ranked.length; i++) {
      if (isNearTie(chosenCost, ranked[i].cost)) lastNearTieIndex = i;
    }
    return lastNearTieIndex < 1 ? 0 : lastNearTieIndex;
  }

  /// Orders [items] into a deterministic total ranking.
  ///
  /// [compare] is intentionally not transitive: hard rules and the near-tie
  /// window override raw cost, so for some candidate sets the pairwise
  /// relation contains cycles (a > b > c > a). A plain `List.sort` is undefined
  /// on such a comparator and can bury a strong candidate below a weaker one.
  ///
  /// This linearizes the relation instead. Wherever [compare] is already a
  /// consistent order it reproduces that order exactly. Where it cycles, the
  /// cycle is broken deterministically: a candidate that loses a hard-rule edge
  /// to another remaining candidate is held back (so an override winner is
  /// never placed below the candidate it overrode), then the remaining tie is
  /// resolved by pairwise win count, cost, and finally root pitch class.
  ///
  /// [candidateOf] extracts the [ChordCandidate] from each item so callers can
  /// rank wrappers (e.g. candidate/debug pairs) directly.
  static List<T> rank<T>(
    List<T> items,
    ChordCandidate Function(T) candidateOf, {
    required Tonality tonality,
    ObservedVoicing? voicing,
    ChordAnalysisProfile profile = ChordAnalysisProfile.current,
  }) {
    final n = items.length;
    if (n <= 1) return List<T>.of(items);

    final cands = [for (final it in items) candidateOf(it)];
    final tieRules = _tieRules(profile);

    // Features (including any voicing evidence) are computed once per candidate
    // here, rather than rebuilt for each of the O(n^2) pairwise decisions below.
    final feats = [
      for (final c in cands) CandidateFeatures.from(c, voicing: voicing),
    ];

    // Seed order: cost asc, then root pitch class asc. This both resolves
    // ties between mutually-equal candidates and seeds the cycle tie-break.
    final seeded = List<int>.generate(n, (i) => i)
      ..sort((a, b) {
        final byCost = cands[a].cost.compareTo(cands[b].cost);
        if (byCost != 0) return byCost;
        return cands[a].identity.rootPc.compareTo(cands[b].identity.rootPc);
      });

    // Per-candidate bitmask of which hard rules could possibly fire with it as
    // an operand (computed once, O(n * rules)). A rule needs one candidate in
    // each role, so it can only fire on a pair when both candidates pass its
    // gate; the pairwise pass then evaluates just `gateMasks[i] & gateMasks[j]`
    // rather than all rules. Rules without a gate are always set, preserving the
    // original behavior. (Rule count stays well under 32 so the mask is safe
    // even under dart2js 32-bit bitwise semantics.)
    final gateMasks = List<int>.generate(n, (k) {
      var mask = 0;
      for (var r = 0; r < hardRules.length; r++) {
        final gate = hardRules[r].gate;
        if (gate == null || gate(cands[k], feats[k], tonality)) {
          mask |= 1 << r;
        }
      }
      return mask;
    });

    // Precompute the pairwise relation once (O(n^2) decisions) so the
    // linearization itself is cheap integer/bool lookups.
    final beats = List.generate(n, (_) => List<bool>.filled(n, false));
    final hardBeats = List.generate(n, (_) => List<bool>.filled(n, false));
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        if (i == j) continue;
        final mask = gateMasks[i] & gateMasks[j];
        // When no hard rule can fire (empty shared mask) and the cost gap is
        // beyond the tie window, the lower cost decides. Skip the full _decide (and
        // its RankingDecision allocation) for those pairs; this is the bulk of
        // them and is output-identical to what _decide would have returned.
        if (mask == 0 &&
            (cands[i].cost - cands[j].cost).abs() > nearTieWindow) {
          if (cands[i].cost < cands[j].cost) beats[i][j] = true;
          continue;
        }
        final d = _decide(
          cands[i],
          cands[j],
          feats[i],
          feats[j],
          tonality: tonality,
          hardRuleMask: mask,
          tieRules: tieRules,
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
    required List<NamedRule> tieRules,
    int? hardRuleMask,
  }) {
    // Negative when a is cheaper (better) than b, so the result mapping below
    // (costDelta > 0 => a ranks after b) still holds.
    final costDelta = a.cost - b.cost;

    // [hardRuleMask], when provided, has a bit set only for rules that could
    // fire on this pair (see [rank]); the rest would return null. Iterate just
    // the set bits (lowest first, preserving rule order) so a pair sharing one
    // or two rules does not scan the whole list. When null (direct
    // [compare]/[explain] calls), every rule runs.
    if (hardRuleMask == null) {
      for (final rule in hardRules) {
        final r = rule.apply(a, b, fa, fb, tonality);
        if (r != null && r != 0) {
          return RankingDecision(
            result: r,
            decidedByRule: rule.name,
            costDelta: costDelta,
            decidedByHardRule: true,
          );
        }
      }
    } else {
      var bits = hardRuleMask;
      while (bits != 0) {
        final i = (bits & -bits).bitLength - 1;
        bits &= bits - 1;
        final r = hardRules[i].apply(a, b, fa, fb, tonality);
        if (r != null && r != 0) {
          return RankingDecision(
            result: r,
            decidedByRule: hardRules[i].name,
            costDelta: costDelta,
            decidedByHardRule: true,
          );
        }
      }
    }

    if (costDelta.abs() > nearTieWindow) {
      final result = costDelta > 0 ? 1 : -1;
      // Named for the pairwise gap to the adjacent candidate, distinct from the
      // one-sided near-tie membership (see isNearTie). The cost difference here
      // exceeds nearTieWindow, so tie-breakers are not engaged.
      return RankingDecision(
        result: result,
        decidedByRule: 'cost difference beyond tie-break range',
        costDelta: costDelta,
      );
    }

    for (final rule in tieRules) {
      final r = rule.apply(a, b, fa, fb, tonality);
      if (r != null && r != 0) {
        return RankingDecision(
          result: r,
          decidedByRule: rule.name,
          costDelta: costDelta,
        );
      }
    }

    final finalResult = a.identity.rootPc.compareTo(b.identity.rootPc);
    return RankingDecision(
      result: finalResult,
      decidedByRule: 'deterministic fallback: rootPc',
      costDelta: costDelta,
    );
  }

  static List<NamedRule> _tieRules(ChordAnalysisProfile profile) =>
      switch (profile) {
        ChordAnalysisProfile.current => tieBreakerRules,
        ChordAnalysisProfile.whatKeyPaper2026 =>
          whatKeyPaper2026TieBreakerRules,
      };
}
