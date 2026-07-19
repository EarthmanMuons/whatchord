// Closed-loop vs open-loop key detection probe.
//
// The app's auto mode writes the detected key back into the analysis
// context, so subsequent chords are ranked under the detector's own claim
// rather than the neutral context the fixtures were recorded with. This
// probe measures whether that feedback loop helps or hurts detection by
// replaying dev-split fixtures through the detector while re-ranking each
// event's candidates from its raw voicing:
//
//   open              recorded candidates (neutral context; baseline)
//   closed-adopted    context follows write-back adoption (streak of 2,
//                     mirroring KeyModeNotifier)
//   closed-immediate  context follows the latest claim with no streak gate
//                     (aggressive upper bound on feedback)
//
// Measured 2026-07-09 (research/whatkey/key-behavior-modes.md): the loop is
// inert in every behavior mode, ~0.4% top-1 identity churn and no metric
// movement, so write-back poses no feedback-stability risk. Kept as a
// diagnostic to re-run if the ranking's tonality tie-breakers or the
// detector presets ever change materially. Prints to stdout; read-only over
// research data (development splits only).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/whatchord.dart';
import 'package:whatkey/whatkey.dart';

import '../../tool/src/chord_id_engine.dart';
import '../../tool/whatkey/src/fixtures.dart';
import '../../tool/whatkey/src/scoring.dart';

final _analyzer = ChordAnalyzer();

// Kept out of the normal suite; run explicitly with:
//   flutter test test/probes/_whatkey_closed_loop_probe_test.dart --run-skipped
const _skip = 'diagnostic probe, not a regression test';

/// The stable/balanced/reactive behavior-mode presets
/// (research/whatkey/key-behavior-modes.md); reactive exercises the feedback
/// path hardest since its adopted context moves several times per piece.
final _modes = <String, HmmKeyDetector Function()>{
  'stable': HmmKeyDetector.new,
  'balanced': () => HmmKeyDetector(decayHalfLife: const Duration(seconds: 4)),
  'reactive': () => HmmKeyDetector(decayHalfLife: const Duration(seconds: 1)),
};

void main() {
  for (final mode in _modes.keys) {
    test('pop-jazz-v2, all fixtures, $mode', skip: _skip, () {
      _probe('research/whatkey/data/fixtures/pop-jazz-v2', mode: mode);
    });

    test('when-in-rome-v1, development split, $mode', skip: _skip, () {
      _probe(
        'research/whatkey/data/fixtures/when-in-rome-v1',
        splitFile: 'research/whatkey/data/splits/when-in-rome-v1.json',
        mode: mode,
      );
    });
  }
}

void _probe(String fixturesDir, {String? splitFile, String mode = 'stable'}) {
  final fixtureSet = FixtureSet.load(Directory(fixturesDir));
  var fixtures = fixtureSet.fixtures;
  if (splitFile != null) {
    final split = SplitFile.load(File(splitFile));
    split.validateAgainst(fixtureSet);
    // Dev split only: this probe never touches the test split.
    final titles = split.pieceTitles('development').toSet();
    fixtures = [
      for (final fixture in fixtures)
        if (titles.contains(fixture.title)) fixture,
    ];
  }
  stdout.writeln(
    'Closed-loop probe: ${fixtureSet.name}'
    '${splitFile == null ? ' (all fixtures)' : ' (development split)'}, '
    '${fixtures.length} pieces, $mode mode\n',
  );

  final newDetector = _modes[mode]!;
  final conditions = <String, _Condition>{
    'open': _Condition.open(),
    'closed-adopted': _Condition.closed(adoptionStreak: 2),
    'closed-immediate': _Condition.closed(adoptionStreak: 1),
  };
  final results = <String, _ConditionResult>{
    for (final entry in conditions.entries)
      entry.key: _run(entry.value, fixtures, newDetector),
  };

  _printSummaryTable(results);
  _printPerPieceDeltas(
    fixtures,
    baseline: results['open']!,
    contrast: results['closed-adopted']!,
    contrastName: 'closed-adopted',
  );
}

class _Condition {
  final bool reRank;

  /// Consecutive identical claims before the context adopts the claimed key;
  /// 2 matches KeyModeNotifier's write-back, 1 adopts instantly.
  final int adoptionStreak;

  _Condition.open() : reRank = false, adoptionStreak = 0;
  _Condition.closed({required this.adoptionStreak}) : reRank = true;
}

class _ConditionResult {
  final List<PieceScore> pieces;
  final Map<String, Object?> summary;
  final int reRankedEvents;
  final int changedTopIdentity;

  _ConditionResult(
    this.pieces,
    this.summary,
    this.reRankedEvents,
    this.changedTopIdentity,
  );
}

_ConditionResult _run(
  _Condition condition,
  List<LabeledFixture> fixtures,
  HmmKeyDetector Function() newDetector,
) {
  final pieces = <PieceScore>[];
  var reRanked = 0;
  var changedTop = 0;

  for (final fixture in fixtures) {
    final detector = newDetector();
    final frames = <KeyEstimateFrame>[];

    // Write-back state, mirroring KeyModeNotifier: the context only moves
    // when a claim persists for the adoption streak, and it stays at the
    // last adopted key through abstentions.
    var adopted = fixture.events.first.tonality;
    Tonality? streakTonality;
    var streak = 0;

    for (final event in fixture.events) {
      var fed = event;
      if (condition.reRank) {
        fed = _reRanked(event, adopted);
        reRanked += 1;
        if (!_sameIdentity(fed.identity, event.identity)) changedTop += 1;
      }
      final frame = detector.onEvent(fed);
      frames.add(frame);

      final claim = frame.claim?.tonality;
      if (claim == null) {
        streakTonality = null;
        streak = 0;
      } else if (claim == streakTonality) {
        streak += 1;
      } else {
        streakTonality = claim;
        streak = 1;
      }
      if (condition.reRank && streak >= condition.adoptionStreak) {
        adopted = normalizeTonalityForKeySignature(streakTonality!);
      }
    }
    pieces.add(PieceScore.compute(fixture, frames));
  }
  return _ConditionResult(pieces, summarize(pieces), reRanked, changedTop);
}

/// Identity comparison ignoring tone roles, which fixtures do not serialize
/// (ChordIdentity.== would otherwise never match a re-analyzed identity).
bool _sameIdentity(ChordIdentity a, ChordIdentity b) =>
    a.rootPc == b.rootPc &&
    a.bassPc == b.bassPc &&
    a.quality == b.quality &&
    a.extensions.length == b.extensions.length &&
    a.extensions.containsAll(b.extensions) &&
    a.presentIntervalsMask == b.presentIntervalsMask;

/// Rebuilds the event as live capture would have seen it with [tonality]
/// selected: candidates re-ranked from the raw voicing under that context,
/// and the event tonality updated to match.
ChordEvent _reRanked(ChordEvent event, Tonality tonality) {
  final keySignature = KeySignature.fromTonality(tonality);
  final context = AnalysisContext(
    tonality: tonality,
    keySignature: keySignature,
    spellingPolicy: NoteSpellingPolicy(preferFlats: keySignature.prefersFlats),
  );
  final ranked = _analyzer.analyze(
    event.input,
    context: context,
    voicing: event.voicing,
  );
  if (ranked.isEmpty) return event;
  return ChordEvent(
    timestamp: event.timestamp,
    input: event.input,
    voicing: event.voicing,
    candidates: [ranked.first, ...ChordCandidateRanking.alternatives(ranked)],
    tonality: tonality,
    duration: event.duration,
  );
}

void _printSummaryTable(Map<String, _ConditionResult> results) {
  String num2(Object? value) =>
      value == null ? '-' : (value as num).toStringAsFixed(2);
  String dist(Map<String, Object?> d) =>
      d['n'] == 0 ? '-' : 'med ${d['median']}, p90 ${d['p90']}';

  Object? dig(Map<String, Object?> summary, List<String> path) {
    Object? node = summary;
    for (final key in path) {
      node = (node as Map<String, Object?>)[key];
    }
    return node;
  }

  final metrics = <(String, String Function(_ConditionResult))>[
    (
      'coverage (mean/piece)',
      (r) => num2(dig(r.summary, ['coverage', 'meanPerPiece'])),
    ),
    (
      'exact on claimed (mean/piece)',
      (r) => num2(dig(r.summary, ['accuracyOnClaimed', 'meanExactPerPiece'])),
    ),
    (
      'mirex on claimed (mean/piece)',
      (r) => num2(dig(r.summary, ['accuracyOnClaimed', 'meanMirexPerPiece'])),
    ),
    (
      'global mirex, final claim',
      (r) => num2(dig(r.summary, ['globalKey', 'meanFinalMirex'])),
    ),
    (
      'global mirex, majority claim',
      (r) => num2(dig(r.summary, ['globalKey', 'meanMajorityMirex'])),
    ),
    (
      'time to first claim',
      (r) => dist(dig(r.summary, ['timeToFirstClaim']) as Map<String, Object?>),
    ),
    (
      'switches per piece',
      (r) => dist(dig(r.summary, ['switchesPerPiece']) as Map<String, Object?>),
    ),
    (
      'spurious switches per piece',
      (r) => dist(
        dig(r.summary, ['spuriousSwitchesPerPiece']) as Map<String, Object?>,
      ),
    ),
    (
      'modulations matched',
      (r) =>
          '${dig(r.summary, ['modulation', 'matched'])}'
          '/${dig(r.summary, ['modulation', 'annotatedChanges'])}',
    ),
    (
      'modulation lag',
      (r) => dist(
        dig(r.summary, ['modulation', 'lagEvents']) as Map<String, Object?>,
      ),
    ),
    (
      'top-1 identity changed',
      (r) => r.reRankedEvents == 0
          ? '-'
          : '${r.changedTopIdentity}/${r.reRankedEvents} '
                '(${(100 * r.changedTopIdentity / r.reRankedEvents).toStringAsFixed(1)}%)',
    ),
  ];

  final names = results.keys.toList();
  final labelWidth = metrics
      .map((m) => m.$1.length)
      .reduce((a, b) => a > b ? a : b);
  final columns = {
    for (final name in names)
      name: [name, for (final metric in metrics) metric.$2(results[name]!)],
  };
  final widths = {
    for (final name in names)
      name: columns[name]!.map((c) => c.length).reduce((a, b) => a > b ? a : b),
  };

  final header = StringBuffer('  ${''.padRight(labelWidth)}');
  for (final name in names) {
    header.write('  ${name.padLeft(widths[name]!)}');
  }
  stdout.writeln(header);
  for (final (index, metric) in metrics.indexed) {
    final line = StringBuffer('  ${metric.$1.padRight(labelWidth)}');
    for (final name in names) {
      line.write('  ${columns[name]![index + 1].padLeft(widths[name]!)}');
    }
    stdout.writeln(line);
  }
  stdout.writeln();
}

void _printPerPieceDeltas(
  List<LabeledFixture> fixtures, {
  required _ConditionResult baseline,
  required _ConditionResult contrast,
  required String contrastName,
}) {
  final deltas = <(String, double, double, double)>[];
  for (var i = 0; i < fixtures.length; i++) {
    final open = baseline.pieces[i];
    final closed = contrast.pieces[i];
    if (open.labeledClaimed == 0 && closed.labeledClaimed == 0) continue;
    final delta = closed.exactOnClaimed - open.exactOnClaimed;
    if (delta.abs() < 0.005 &&
        (closed.coverage - open.coverage).abs() < 0.005) {
      continue;
    }
    deltas.add((
      fixtures[i].title,
      delta,
      open.exactOnClaimed,
      closed.exactOnClaimed,
    ));
  }
  deltas.sort((a, b) => a.$2.compareTo(b.$2));

  if (deltas.isEmpty) {
    stdout.writeln('No per-piece exact/coverage changes ($contrastName).');
    return;
  }
  stdout.writeln('Per-piece exact-on-claimed changes (open -> $contrastName)');
  for (final (title, delta, open, closed) in deltas) {
    stdout.writeln(
      '  ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(2)}'
      '  ${open.toStringAsFixed(2)} -> ${closed.toStringAsFixed(2)}'
      '  $title',
    );
  }
}
