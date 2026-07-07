// Offline WhatKey evaluation harness (research/whatkey/PROTOCOL.md).
//
// Replays fixture sets through a causal key detector and reports the protocol
// metrics. Runs the development split by default; the test split requires an
// explicit --split test, and every test-split run needs a dated entry in
// research/whatkey/log/.
//
// Usage:
//   dart run tool/whatkey_harness.dart --fixtures <set-dir> \
//     [--split-file <split.json>] [--split development|test] \
//     [--profiles krumhanslKessler|temperley|temperleyKostkaPayne|
//                 albrechtShanahan] \
//     [--weighting duration|flat] [--decay-half-life-seconds N] \
//     [--min-events N] [--margin-floor X] [--out <dir>] \
//     [--claims-file <claims.json>]
//
// With --claims-file (see tool/whatkey_external_baseline.py), detector flags
// are ignored and the externally produced global claims are scored as a
// constant claim per event through the same metrics.

import 'dart:convert';
import 'dart:io';

import 'package:whatchord/features/key/key.dart';

import 'src/whatkey/whatkey_fixtures.dart';
import 'src/whatkey/whatkey_scoring.dart';

void main(List<String> arguments) {
  final options = _Options.parse(arguments);

  final fixtureSet = FixtureSet.load(Directory(options.fixturesDir));
  var fixtures = fixtureSet.fixtures;
  if (options.splitFile != null) {
    final split = SplitFile.load(File(options.splitFile!));
    split.validateAgainst(fixtureSet);
    final titles = split.pieceTitles(options.split).toSet();
    fixtures = [
      for (final fixture in fixtures)
        if (titles.contains(fixture.title)) fixture,
    ];
    if (options.split == 'test') {
      stderr.writeln(
        'WARNING: evaluating the TEST split. The protocol requires a dated '
        'log entry in research/whatkey/log/ for this run.',
      );
    }
  }
  if (fixtures.isEmpty) {
    stderr.writeln('No fixtures selected.');
    exitCode = 1;
    return;
  }

  final claims = options.claimsFile == null
      ? null
      : ClaimsFile.load(File(options.claimsFile!));
  final detector = claims == null ? options.buildDetector() : null;
  final detectorInfo =
      claims?.detector ??
      {'name': detector!.name, 'configuration': detector.configuration};

  final pieces = <PieceScore>[];
  for (final fixture in fixtures) {
    List<KeyEstimateFrame> frames;
    if (claims != null) {
      frames = claims.framesFor(fixture);
    } else {
      detector!.reset();
      frames = [for (final event in fixture.events) detector.onEvent(event)];
    }
    pieces.add(PieceScore.compute(fixture, frames));
  }
  final summary = summarize(pieces);

  final report = <String, Object?>{
    'schema': 'whatkey-harness-report/1',
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'engineCommit': _git(['rev-parse', 'HEAD']),
    'engineLibDirty': _git(['status', '--porcelain', '--', 'lib']).isNotEmpty,
    'fixtures': {
      'set': fixtureSet.name,
      'directory': options.fixturesDir,
      'source': fixtureSet.source,
      'engineCommit': fixtureSet.manifest['engineCommit'],
    },
    'split': options.splitFile == null
        ? null
        : {'file': options.splitFile, 'name': options.split},
    'detector': detectorInfo,
    'provisionalDefinitions':
        'Modulation-lag censoring, spurious-switch alignment, and the '
        'global-key operationalization are provisional pending protocol '
        'freeze; see PROTOCOL.md "Deferred to freeze".',
    'summary': summary,
    'perPiece': [for (final piece in pieces) piece.toJson()],
  };

  final outDir = Directory(
    options.outDir ??
        'build/whatkey-harness/${_basename(options.fixturesDir)}-'
            '${options.splitFile == null ? 'all' : options.split}'
            '${claims == null ? '' : '-${detectorInfo['name']}'}',
  )..createSync(recursive: true);
  File('${outDir.path}/report.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(report)}\n',
  );
  final text = _textReport(report, pieces);
  File('${outDir.path}/report.txt').writeAsStringSync(text);
  stdout.write(text);
  stderr.writeln('Report -> ${outDir.path}');
}

String _textReport(Map<String, Object?> report, List<PieceScore> pieces) {
  final buffer = StringBuffer();
  final fixtures = report['fixtures'] as Map<String, Object?>;
  final detector = report['detector'] as Map<String, Object?>;
  final split = report['split'] as Map<String, Object?>?;
  final summary = report['summary'] as Map<String, Object?>;

  buffer
    ..writeln('WhatKey harness report')
    ..writeln('=' * 60)
    ..writeln(
      'set:       ${fixtures['set']}'
      '${split == null ? ' (all fixtures)' : ' (${split['name']} split)'}',
    )
    ..writeln('detector:  ${detector['name']}')
    ..writeln('config:    ${detector['configuration']}')
    ..writeln(
      'engine:    ${report['engineCommit']}'
      '${report['engineLibDirty'] == true ? ' (lib dirty)' : ''}',
    )
    ..writeln('generated: ${report['generatedAt']}')
    ..writeln()
    ..writeln(_summaryBlock(summary))
    ..writeln('Per piece')
    ..writeln(
      '  events: chord events\n'
      '  cover: fraction of events with a key claim\n'
      '  exact: exact-match accuracy on claimed events\n'
      '  mirex: MIREX-weighted accuracy on claimed events\n'
      '  ttfc: events before the first claim\n'
      '  sw: key switches\n'
      '  spur: spurious switches\n'
      '  amb-ok: ambiguous events handled acceptably\n',
    )
    ..write(_pieceTable(pieces));
  return buffer.toString();
}

String _summaryBlock(Map<String, Object?> summary) {
  final coverage = summary['coverage'] as Map<String, Object?>;
  final accuracy = summary['accuracyOnClaimed'] as Map<String, Object?>;
  final ttfc = summary['timeToFirstClaim'] as Map<String, Object?>;
  final switches = summary['switchesPerPiece'] as Map<String, Object?>;
  final spurious = summary['spuriousSwitchesPerPiece'] as Map<String, Object?>;
  final modulation = summary['modulation'] as Map<String, Object?>;
  final lag = modulation['lagEvents'] as Map<String, Object?>;
  final globalKey = summary['globalKey'] as Map<String, Object?>;

  String num2(Object? value) =>
      value == null ? '-' : (value as num).toStringAsFixed(2);
  String dist(Map<String, Object?> d) => d['n'] == 0
      ? '-'
      : 'median ${_trimNum(d['median'])}, p90 ${_trimNum(d['p90'])}';
  String pieces(Object? count) => '$count piece${count == 1 ? '' : 's'}';

  final lines = <(String, String, String)>[
    ('Coverage (mean per piece)', num2(coverage['meanPerPiece']), ''),
    (
      'Accuracy on claimed, exact (mean per piece)',
      num2(accuracy['meanExactPerPiece']),
      '${pieces(accuracy['piecesWithClaims'])} with claims',
    ),
    (
      'Accuracy on claimed, MIREX (mean per piece)',
      num2(accuracy['meanMirexPerPiece']),
      '',
    ),
    (
      'Global key MIREX, final claim',
      num2(globalKey['meanFinalMirex']),
      '${pieces(globalKey['scoredPieces'])} scored',
    ),
    (
      'Global key MIREX, majority claim',
      num2(globalKey['meanMajorityMirex']),
      '',
    ),
    (
      'Time to first claim (events)',
      dist(ttfc),
      '${pieces(ttfc['neverClaimedPieces'])} never claim',
    ),
    ('Switches per piece', dist(switches), ''),
    ('Spurious switches per piece', dist(spurious), ''),
    (
      'Modulations matched',
      '${modulation['matched']}/${modulation['annotatedChanges']}',
      '${modulation['censored']} censored',
    ),
    ('Modulation lag (events)', dist(lag), ''),
  ];

  final buffer = StringBuffer()
    ..writeln(
      'Summary (${summary['pieces']} pieces, '
      '${summary['events']} events)',
    );
  final labelWidth = lines
      .map((line) => line.$1.length)
      .reduce((a, b) => a > b ? a : b);
  final valueWidth = lines
      .map((line) => line.$2.length)
      .reduce((a, b) => a > b ? a : b);
  for (final (label, value, note) in lines) {
    buffer.writeln(
      '  ${label.padRight(labelWidth)}  ${value.padLeft(valueWidth)}'
      '${note.isEmpty ? '' : '  ($note)'}',
    );
  }
  return buffer.toString();
}

String _pieceTable(List<PieceScore> pieces) {
  final header = [
    'piece',
    'events',
    'cover',
    'exact',
    'mirex',
    'ttfc',
    'sw',
    'spur',
    'amb-ok',
  ];
  final rows = <List<String>>[
    header,
    for (final piece in pieces)
      [
        piece.title,
        '${piece.events}',
        piece.coverage.toStringAsFixed(2),
        piece.labeledClaimed == 0
            ? '-'
            : piece.exactOnClaimed.toStringAsFixed(2),
        piece.labeledClaimed == 0
            ? '-'
            : piece.mirexOnClaimed.toStringAsFixed(2),
        '${piece.timeToFirstClaim ?? '-'}',
        '${piece.switches}',
        '${piece.spuriousSwitches}',
        piece.ambiguousEvents == 0
            ? '-'
            : '${piece.ambiguousOk}/${piece.ambiguousEvents}',
      ],
  ];

  final widths = [
    for (var column = 0; column < header.length; column++)
      rows.map((row) => row[column].length).reduce((a, b) => a > b ? a : b),
  ];
  final buffer = StringBuffer();
  for (final (index, row) in rows.indexed) {
    final cells = [
      // Title column left-aligned, numeric columns right-aligned.
      row[0].padRight(widths[0]),
      for (var column = 1; column < row.length; column++)
        row[column].padLeft(widths[column]),
    ];
    buffer.writeln('  ${cells.join('  ')}'.trimRight());
    if (index == 0) {
      buffer.writeln(
        '  ${[for (final width in widths) '-' * width].join('  ')}',
      );
    }
  }
  return buffer.toString();
}

/// Renders whole numbers without a trailing ".0".
String _trimNum(Object? value) {
  final number = value as num;
  return number == number.truncate()
      ? '${number.truncate()}'
      : number.toStringAsFixed(1);
}

String _git(List<String> arguments) =>
    (Process.runSync('git', arguments).stdout as String).trim();

class _Options {
  final String fixturesDir;
  final String? splitFile;
  final String split;
  final String? claimsFile;
  final KeyProfilePair profiles;
  final bool durationWeighted;
  final int decayHalfLifeSeconds;
  final int minEvents;
  final double marginFloor;
  final String? outDir;

  _Options._({
    required this.fixturesDir,
    required this.splitFile,
    required this.split,
    required this.claimsFile,
    required this.profiles,
    required this.durationWeighted,
    required this.decayHalfLifeSeconds,
    required this.minEvents,
    required this.marginFloor,
    required this.outDir,
  });

  KeyDetector buildDetector() => ProfileCorrelationKeyDetector(
    profiles: profiles,
    durationWeighted: durationWeighted,
    decayHalfLife: decayHalfLifeSeconds == 0
        ? null
        : Duration(seconds: decayHalfLifeSeconds),
    minEvents: minEvents,
    marginFloor: marginFloor,
  );

  static _Options parse(List<String> arguments) {
    final values = <String, String>{};
    for (var i = 0; i < arguments.length; i += 2) {
      final flag = arguments[i];
      if (!flag.startsWith('--') || i + 1 >= arguments.length) {
        throw ArgumentError('Expected --flag value pairs, got: $flag');
      }
      values[flag.substring(2)] = arguments[i + 1];
    }

    final fixturesDir = values.remove('fixtures');
    if (fixturesDir == null) {
      throw ArgumentError('--fixtures <set-dir> is required');
    }
    final splitFile = values.remove('split-file');
    final splitName = values.remove('split');
    if (splitName != null && splitFile == null) {
      throw ArgumentError('--split requires --split-file');
    }
    final split = splitName ?? 'development';
    if (split != 'development' && split != 'test') {
      throw ArgumentError('--split must be development or test');
    }
    final options = _Options._(
      fixturesDir: fixturesDir,
      splitFile: splitFile,
      split: split,
      claimsFile: values.remove('claims-file'),
      profiles: KeyProfilePair.values.byName(
        values.remove('profiles') ?? 'albrechtShanahan',
      ),
      durationWeighted: (values.remove('weighting') ?? 'duration') != 'flat',
      decayHalfLifeSeconds: int.parse(
        values.remove('decay-half-life-seconds') ?? '30',
      ),
      minEvents: int.parse(values.remove('min-events') ?? '3'),
      marginFloor: double.parse(values.remove('margin-floor') ?? '0.05'),
      outDir: values.remove('out'),
    );
    if (values.isNotEmpty) {
      throw ArgumentError('Unknown flags: ${values.keys.toList()}');
    }
    return options;
  }
}

String _basename(String path) =>
    path.split('/').where((part) => part.isNotEmpty).last;
