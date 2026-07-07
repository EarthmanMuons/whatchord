// Metric scaffolding for the WhatKey harness, per research/whatkey/PROTOCOL.md.
//
// Pinned rules implemented here: top-1 event-weighted scoring; the
// selective-prediction frame (coverage and accuracy-on-claimed as a pair,
// abstentions are never errors); switches counted between consecutive claims
// only; ambiguous-labeled events accept abstention or any acceptable key and
// stay out of accuracy pools.
//
// Provisional (deferred-to-freeze) definitions, implemented in their simplest
// form and reported as such: modulation lag is censored at the next annotated
// change or piece end; a switch is spurious when the annotated local key did
// not change between the two claims' events; global key reports both the
// final-event claim and the duration-weighted majority claim against the first
// annotated local key.

import 'package:whatchord/features/key/key.dart';

import 'whatkey_fixtures.dart';

/// MIREX near-miss weighting (see PROTOCOL.md references).
double mirexWeight(KeyLabel claim, KeyLabel truth) {
  if (claim.matches(truth)) return 1.0;
  final interval = (claim.tonicPc - truth.tonicPc + 12) % 12;
  if (claim.isMinor == truth.isMinor && (interval == 7 || interval == 5)) {
    return 0.5;
  }
  if (!truth.isMinor && claim.isMinor && interval == 9) return 0.3;
  if (truth.isMinor && !claim.isMinor && interval == 3) return 0.3;
  if (interval == 0) return 0.2;
  return 0.0;
}

class PieceScore {
  final String id;
  final String title;
  final int events;

  final int claimed;
  final int labeledClaimed;
  final double exactOnClaimed;
  final double mirexOnClaimed;

  final int ambiguousEvents;
  final int ambiguousOk;

  final int? timeToFirstClaim;
  final int switches;
  final int spuriousSwitches;

  final int annotatedChanges;
  final List<int> modulationLags;
  final int censoredModulations;

  final KeyLabel? globalTruth;
  final double? globalFinalMirex;
  final double? globalMajorityMirex;

  PieceScore._({
    required this.id,
    required this.title,
    required this.events,
    required this.claimed,
    required this.labeledClaimed,
    required this.exactOnClaimed,
    required this.mirexOnClaimed,
    required this.ambiguousEvents,
    required this.ambiguousOk,
    required this.timeToFirstClaim,
    required this.switches,
    required this.spuriousSwitches,
    required this.annotatedChanges,
    required this.modulationLags,
    required this.censoredModulations,
    required this.globalTruth,
    required this.globalFinalMirex,
    required this.globalMajorityMirex,
  });

  double get coverage => events == 0 ? 0 : claimed / events;

  /// Scores [frames] against the fixture's labels.
  ///
  /// With [evaluateMask], coverage, accuracy, and ambiguous-event metrics are
  /// computed over the masked-in events only (the matched-coverage
  /// comparison); streaming metrics (time-to-first-claim, switches, lag,
  /// global key) always use the full stream, since restricting them has no
  /// meaning.
  static PieceScore compute(
    LabeledFixture fixture,
    List<KeyEstimateFrame> frames, {
    List<bool>? evaluateMask,
  }) {
    assert(frames.length == fixture.events.length);
    assert(evaluateMask == null || evaluateMask.length == frames.length);
    final labels = fixture.labels;

    var evaluated = 0;
    var claimed = 0;
    var labeledClaimed = 0;
    var exactSum = 0.0;
    var mirexSum = 0.0;
    var ambiguousEvents = 0;
    var ambiguousOk = 0;
    int? timeToFirstClaim;

    final claims = <({int index, KeyLabel key})>[];
    for (var i = 0; i < frames.length; i++) {
      final claim = frames[i].claim;
      final truth = labels[i].localKey;
      if (claim != null) {
        timeToFirstClaim ??= i;
        claims.add((index: i, key: KeyLabel.of(claim.tonality)));
      }

      if (evaluateMask != null && !evaluateMask[i]) continue;
      evaluated += 1;
      if (labels[i].localKey == null && labels[i].acceptableKeys.isNotEmpty) {
        ambiguousEvents += 1;
        final ok =
            claim == null ||
            labels[i].acceptableKeys.any(
              (key) => key.matches(KeyLabel.of(claim.tonality)),
            );
        if (ok) ambiguousOk += 1;
      }
      if (claim == null) continue;
      claimed += 1;
      if (truth != null) {
        final claimKey = KeyLabel.of(claim.tonality);
        labeledClaimed += 1;
        exactSum += claimKey.matches(truth) ? 1 : 0;
        mirexSum += mirexWeight(claimKey, truth);
      }
    }

    var switches = 0;
    var spuriousSwitches = 0;
    for (var c = 1; c < claims.length; c++) {
      if (claims[c].key.matches(claims[c - 1].key)) continue;
      switches += 1;
      // Provisional: spurious means the annotation did not change across the
      // window AND the switch does not land on the annotated key. The second
      // condition keeps a lagged catch-up switch (annotation changed earlier,
      // detector arrives late) from being charged as spurious.
      final previousTruth = labels[claims[c - 1].index].localKey;
      final currentTruth = labels[claims[c].index].localKey;
      if (previousTruth != null &&
          currentTruth != null &&
          previousTruth.matches(currentTruth) &&
          !claims[c].key.matches(currentTruth)) {
        spuriousSwitches += 1;
      }
    }

    final changes = <({int index, KeyLabel newKey})>[];
    for (var i = 1; i < labels.length; i++) {
      final previous = labels[i - 1].localKey;
      final current = labels[i].localKey;
      if (previous != null && current != null && !previous.matches(current)) {
        changes.add((index: i, newKey: current));
      }
    }
    final modulationLags = <int>[];
    var censored = 0;
    for (var c = 0; c < changes.length; c++) {
      final horizon = c + 1 < changes.length
          ? changes[c + 1].index
          : frames.length;
      var matched = false;
      for (final claim in claims) {
        if (claim.index < changes[c].index) continue;
        if (claim.index >= horizon) break;
        if (claim.key.matches(changes[c].newKey)) {
          modulationLags.add(claim.index - changes[c].index);
          matched = true;
          break;
        }
      }
      if (!matched) censored += 1;
    }

    final globalTruth = labels
        .map((label) => label.localKey)
        .firstWhere((key) => key != null, orElse: () => null);
    double? globalFinalMirex;
    double? globalMajorityMirex;
    if (globalTruth != null && claims.isNotEmpty) {
      globalFinalMirex = mirexWeight(claims.last.key, globalTruth);
      final weightByKey = <String, double>{};
      final keyByName = <String, KeyLabel>{};
      for (final claim in claims) {
        final ms = fixture.events[claim.index].duration.inMilliseconds;
        weightByKey.update(
          claim.key.toString(),
          (weight) => weight + ms,
          ifAbsent: () => ms.toDouble(),
        );
        keyByName[claim.key.toString()] = claim.key;
      }
      final majority = weightByKey.entries.reduce(
        (a, b) => b.value > a.value ? b : a,
      );
      globalMajorityMirex = mirexWeight(keyByName[majority.key]!, globalTruth);
    }

    return PieceScore._(
      id: fixture.id,
      title: fixture.title,
      events: evaluated,
      claimed: claimed,
      labeledClaimed: labeledClaimed,
      exactOnClaimed: labeledClaimed == 0 ? 0 : exactSum / labeledClaimed,
      mirexOnClaimed: labeledClaimed == 0 ? 0 : mirexSum / labeledClaimed,
      ambiguousEvents: ambiguousEvents,
      ambiguousOk: ambiguousOk,
      timeToFirstClaim: timeToFirstClaim,
      switches: switches,
      spuriousSwitches: spuriousSwitches,
      annotatedChanges: changes.length,
      modulationLags: modulationLags,
      censoredModulations: censored,
      globalTruth: globalTruth,
      globalFinalMirex: globalFinalMirex,
      globalMajorityMirex: globalMajorityMirex,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'events': events,
    'claimed': claimed,
    'coverage': coverage,
    'labeledClaimed': labeledClaimed,
    'exactOnClaimed': exactOnClaimed,
    'mirexOnClaimed': mirexOnClaimed,
    'ambiguousEvents': ambiguousEvents,
    'ambiguousOk': ambiguousOk,
    'timeToFirstClaim': timeToFirstClaim,
    'switches': switches,
    'spuriousSwitches': spuriousSwitches,
    'annotatedChanges': annotatedChanges,
    'modulationLags': modulationLags,
    'censoredModulations': censoredModulations,
    'globalTruth': globalTruth?.toString(),
    'globalFinalMirex': globalFinalMirex,
    'globalMajorityMirex': globalMajorityMirex,
  };
}

/// Per-piece aggregation per the protocol's reporting rules: means for
/// accuracy-like metrics, median and p90 for latency- and count-like metrics,
/// n everywhere.
Map<String, Object?> summarize(List<PieceScore> pieces) {
  final withClaims = pieces.where((p) => p.labeledClaimed > 0).toList();
  final lags = [for (final p in pieces) ...p.modulationLags];
  final neverClaimed = pieces.where((p) => p.timeToFirstClaim == null).length;
  final globalScored = pieces.where((p) => p.globalFinalMirex != null).toList();

  return {
    'pieces': pieces.length,
    'events': pieces.fold<int>(0, (sum, p) => sum + p.events),
    'coverage': {
      'meanPerPiece': _mean([for (final p in pieces) p.coverage]),
    },
    'accuracyOnClaimed': {
      'piecesWithClaims': withClaims.length,
      'meanExactPerPiece': _mean([
        for (final p in withClaims) p.exactOnClaimed,
      ]),
      'meanMirexPerPiece': _mean([
        for (final p in withClaims) p.mirexOnClaimed,
      ]),
    },
    'timeToFirstClaim': {
      'neverClaimedPieces': neverClaimed,
      ..._distribution([
        for (final p in pieces)
          if (p.timeToFirstClaim != null) p.timeToFirstClaim!.toDouble(),
      ]),
    },
    'switchesPerPiece': _distribution([
      for (final p in pieces) p.switches.toDouble(),
    ]),
    'spuriousSwitchesPerPiece': _distribution([
      for (final p in pieces) p.spuriousSwitches.toDouble(),
    ]),
    'modulation': {
      'annotatedChanges': pieces.fold<int>(
        0,
        (sum, p) => sum + p.annotatedChanges,
      ),
      'matched': lags.length,
      'censored': pieces.fold<int>(0, (sum, p) => sum + p.censoredModulations),
      'lagEvents': _distribution([for (final lag in lags) lag.toDouble()]),
    },
    'globalKey': {
      'scoredPieces': globalScored.length,
      'meanFinalMirex': _mean([
        for (final p in globalScored) p.globalFinalMirex!,
      ]),
      'meanMajorityMirex': _mean([
        for (final p in globalScored) p.globalMajorityMirex!,
      ]),
    },
  };
}

double? _mean(List<double> values) =>
    values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;

Map<String, Object?> _distribution(List<double> values) {
  if (values.isEmpty) return {'n': 0, 'median': null, 'p90': null};
  final sorted = [...values]..sort();
  return {
    'n': sorted.length,
    'median': _percentile(sorted, 0.5),
    'p90': _percentile(sorted, 0.9),
  };
}

/// Nearest-rank percentile over an ascending [sorted] list.
double _percentile(List<double> sorted, double p) {
  final rank = (p * sorted.length).ceil().clamp(1, sorted.length);
  return sorted[rank - 1];
}

/// Re-applies a margin floor to frames produced with `marginFloor: 0`.
///
/// The margin floor is a post-hoc threshold: claims never feed back into the
/// detector's histogram, so one floor-zero pass plus this function yields the
/// whole coverage-accuracy curve without re-running the detector.
List<KeyEstimateFrame> applyMarginFloor(
  List<KeyEstimateFrame> frames,
  double floor,
) => [
  for (final frame in frames)
    frame.claim != null && _margin(frame) < floor
        ? KeyEstimateFrame.abstain(frame.ranked)
        : frame,
];

double _margin(KeyEstimateFrame frame) => frame.ranked.length < 2
    ? double.infinity
    : frame.ranked[0].confidence - frame.ranked[1].confidence;
