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
//     [--profiles krumhanslKessler|temperley|albrechtShanahan] \
//     [--weighting duration|flat] [--decay-half-life-seconds N] \
//     [--min-events N] [--margin-floor X] [--out <dir>]

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

  final detector = options.buildDetector();
  final pieces = <PieceScore>[];
  for (final fixture in fixtures) {
    detector.reset();
    final frames = [
      for (final event in fixture.events) detector.onEvent(event),
    ];
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
    'detector': {
      'name': detector.name,
      'configuration': detector.configuration,
    },
    'provisionalDefinitions':
        'Modulation-lag censoring, spurious-switch alignment, and the '
        'global-key operationalization are provisional pending protocol '
        'freeze; see PROTOCOL.md "Deferred to freeze".',
    'summary': summary,
    'perPiece': [for (final piece in pieces) piece.toJson()],
  };

  final outDir = Directory(options.outDir)..createSync(recursive: true);
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
    ..writeln(
      'set: ${fixtures['set']}'
      '${split == null ? ' (all fixtures)' : ' split=${split['name']}'}',
    )
    ..writeln('detector: ${detector['name']} ${detector['configuration']}')
    ..writeln(
      'engine: ${report['engineCommit']}'
      '${report['engineLibDirty'] == true ? ' (lib dirty)' : ''}',
    )
    ..writeln()
    ..writeln(const JsonEncoder.withIndent('  ').convert(summary))
    ..writeln()
    ..writeln(
      'piece | events | cover | exact | mirex | ttfc | sw | spur | amb-ok',
    );
  for (final piece in pieces) {
    buffer.writeln(
      [
        piece.title,
        piece.events,
        piece.coverage.toStringAsFixed(2),
        piece.labeledClaimed == 0
            ? '-'
            : piece.exactOnClaimed.toStringAsFixed(2),
        piece.labeledClaimed == 0
            ? '-'
            : piece.mirexOnClaimed.toStringAsFixed(2),
        piece.timeToFirstClaim ?? '-',
        piece.switches,
        piece.spuriousSwitches,
        piece.ambiguousEvents == 0
            ? '-'
            : '${piece.ambiguousOk}/${piece.ambiguousEvents}',
      ].join(' | '),
    );
  }
  return buffer.toString();
}

String _git(List<String> arguments) =>
    (Process.runSync('git', arguments).stdout as String).trim();

class _Options {
  final String fixturesDir;
  final String? splitFile;
  final String split;
  final KeyProfilePair profiles;
  final bool durationWeighted;
  final int decayHalfLifeSeconds;
  final int minEvents;
  final double marginFloor;
  final String outDir;

  _Options._({
    required this.fixturesDir,
    required this.splitFile,
    required this.split,
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
      profiles: KeyProfilePair.values.byName(
        values.remove('profiles') ?? 'albrechtShanahan',
      ),
      durationWeighted: (values.remove('weighting') ?? 'duration') != 'flat',
      decayHalfLifeSeconds: int.parse(
        values.remove('decay-half-life-seconds') ?? '30',
      ),
      minEvents: int.parse(values.remove('min-events') ?? '3'),
      marginFloor: double.parse(values.remove('margin-floor') ?? '0.05'),
      outDir:
          values.remove('out') ??
          'build/whatkey-harness/${_basename(fixturesDir)}-'
              '${splitFile == null ? 'all' : split}',
    );
    if (values.isNotEmpty) {
      throw ArgumentError('Unknown flags: ${values.keys.toList()}');
    }
    return options;
  }

  static String _basename(String path) =>
      path.split('/').where((part) => part.isNotEmpty).last;
}
