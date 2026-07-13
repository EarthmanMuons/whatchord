import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/theory/theory.dart';

import 'helpers/theory_test_helpers.dart';

// Guards ChordAnalyzer.rankingPruneMargin. The prune drops candidates priced
// more than the margin above the cheapest raw reading before the O(n^2) ranking,
// on the premise that such a reading can never surface (neither the chosen #1
// nor an alternative). This test measures the actual surfaced gap on the
// unpruned engine and fails if any voicing produces a gap at or above the
// margin, which would mean the prune is silently dropping a reading a musician
// would have seen. If a future pricing/ranking change trips this, raise the
// margin (or reconsider the change) rather than ship a quietly shrinking
// alternatives set.
void main() {
  late double productionMargin;

  setUp(() {
    // Disable pruning so analyze() returns every candidate, letting us observe
    // the true surfaced gap. The cache is keyed without the margin, so clear it.
    productionMargin = ChordAnalyzer.rankingPruneMargin;
    ChordAnalyzer.rankingPruneMargin = double.infinity;
    ChordAnalyzer.clearCache();
  });

  tearDown(() {
    ChordAnalyzer.rankingPruneMargin = productionMargin;
    ChordAnalyzer.clearCache();
  });

  test('no surfaced candidate sits at or beyond the prune margin', () {
    final ctx = makeAnalysisContext();

    var worstGap = 0.0;
    var worstKey = '';
    var tested = 0;

    void check(ChordInput input, String key) {
      tested++;
      final gap = _surfacedGap(input, ctx);
      if (gap > worstGap) {
        worstGap = gap;
        worstKey = key;
      }
    }

    // 1) The reviewed-oracle corpus: real, vetted, deliberately tricky voicings.
    for (final entry in _oracleVoicings()) {
      check(entry.value, entry.key);
    }

    // 2) An adversarial dense sweep (7-12 notes). Dense voicings have no clean
    // template fit, so costs compress and the non-monotonic linearization
    // sandwiches deep readings into the surfaced band; this is where the widest
    // gaps appear. Seeded for determinism. Kept to a modest sample per size for
    // runtime; the widest known gap comes from the worst-case mask checked
    // explicitly below.
    final rng = math.Random(20240629);
    for (var size = 7; size <= 11; size++) {
      for (var s = 0; s < 30; s++) {
        final pcs = <int>{};
        while (pcs.length < size) {
          pcs.add(rng.nextInt(12));
        }
        var mask = 0;
        for (final p in pcs) {
          mask |= 1 << p;
        }
        final bass = pcs.reduce(math.min);
        check(
          ChordInput(pcMask: mask, bassPc: bass, noteCount: size),
          _keyOf(mask, bass),
        );
      }
    }
    // The full chromatic cluster on every bass, plus the known worst-case mask.
    for (var bass = 0; bass < 12; bass++) {
      check(
        ChordInput(pcMask: 0xFFF, bassPc: bass, noteCount: 12),
        _keyOf(0xFFF, bass),
      );
    }
    // 0-1-3-4-6-8-10-11: the widest gap (2.858) found while sizing the margin.
    const worstMask = 0xDDB;
    for (var bass = 0; bass < 12; bass++) {
      if ((worstMask & (1 << bass)) == 0) continue;
      check(
        ChordInput(pcMask: worstMask, bassPc: bass, noteCount: 8),
        _keyOf(worstMask, bass),
      );
    }

    expect(
      worstGap,
      lessThan(productionMargin),
      reason:
          'Widest surfaced gap was ${worstGap.toStringAsFixed(3)} at $worstKey '
          'across $tested voicings, but ChordAnalyzer.rankingPruneMargin is '
          '$productionMargin. A candidate priced this far above the cheapest '
          'raw reading still surfaces, so the prune would drop it. Raise '
          'rankingPruneMargin above the observed gap (with headroom) or revisit '
          'the change that widened it.',
    );
  });
}

/// The widest gap between the cheapest raw cost and the highest-cost *surfaced*
/// candidate (the #1 plus its alternatives), for a single voicing on the
/// unpruned engine.
double _surfacedGap(ChordInput input, AnalysisContext ctx) {
  final ranked = ChordAnalyzer.analyze(input, context: ctx, take: 100000);
  if (ranked.isEmpty) return 0;
  final costs = [for (final c in ranked) c.cost];
  // Candidate costs are explanation costs (lower is better); the prune anchors on the
  // cheapest reading and drops anything priced more than margin above it.
  final minCost = costs.reduce(math.min);
  final best = costs.first;

  // Mirror ChordCandidateRanking.alternativeCount: the surfaced set runs through
  // the last candidate within nearTieWindow of the #1, including any deeper
  // readings the linearization placed above it.
  var lastNearTie = 0;
  for (var i = 1; i < costs.length; i++) {
    if (costs[i] - best <= ChordCandidateRanking.nearTieWindow) {
      lastNearTie = i;
    }
  }
  var maxSurfaced = best;
  for (var i = 0; i <= lastNearTie; i++) {
    maxSurfaced = math.max(maxSurfaced, costs[i]);
  }
  return maxSurfaced - minCost;
}

/// Loads the reviewed-oracle voicings, decoded from their case keys (a key like
/// `0-4-7-10_b0` is pitch classes {0,4,7,10} with bass pitch class 0).
Iterable<MapEntry<String, ChordInput>> _oracleVoicings() sync* {
  final file = File('tool/chord_oracle_reviewed.json');
  if (!file.existsSync()) return;
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  for (final key in json.keys) {
    final parts = key.split('_b');
    final pcs = parts[0].split('-').map(int.parse);
    var mask = 0;
    var count = 0;
    for (final pc in pcs) {
      mask |= 1 << pc;
      count++;
    }
    yield MapEntry(
      key,
      ChordInput(pcMask: mask, bassPc: int.parse(parts[1]), noteCount: count),
    );
  }
}

String _keyOf(int mask, int bass) {
  final pcs = [
    for (var p = 0; p < 12; p++)
      if ((mask & (1 << p)) != 0) p,
  ];
  return '${pcs.join("-")}_b$bass';
}
