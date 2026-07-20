// Track B spelling headroom (design doc Track B; log entry 2026-07-20-06).
//
// Compares the engine's member spelling against the score's actual spelling
// (DCML note-table tpc, line of fifths with 0 = C), per event, under three
// contexts: the set's neutral context, the closed-loop inferred key (the
// production path), and the annotated local key (oracle diagnostic).
//
// Spelling is scored only on events whose identity the arm got right at
// root+quality (so spelling errors are not confounded by wrong identities),
// and only for pitch classes the score spells one way within the span
// (conflicting spellings are counted and skipped). Each pitch class is
// spelled the way the app's display path spells it: the root via
// spellChordRoot, role-classified tones via spellPitchClass, unexplained
// tones via noteNameForPitchClass.
//
// Usage mirrors cue_eval.dart (--fixtures/--labels/--split-file/--split/
// --behavior/--out).

import 'dart:convert';
import 'dart:io';

import 'package:whatchord/whatchord.dart';
import 'package:whatkey/whatkey.dart';

import '../src/chord_id_engine.dart';
import '../whatkey/src/fixtures.dart';

const _take = 10000;
const _minNotes = 3;
const _arms = ['neutral', 'inferred', 'annotated'];

final _analyzer = ChordAnalyzer();

const _letterTpc = {'F': -1, 'C': 0, 'G': 1, 'D': 2, 'A': 3, 'E': 4, 'B': 5};

int? _nameToTpc(String name) {
  if (name.isEmpty) return null;
  final normalized = name
      .replaceAll('♭', 'b')
      .replaceAll('♯', '#')
      .replaceAll('\u{1D12B}', 'bb')
      .replaceAll('\u{1D12A}', '##');
  var tpc = _letterTpc[normalized[0].toUpperCase()];
  if (tpc == null) return null;
  for (final accidental in normalized.substring(1).split('')) {
    if (accidental == '#') {
      tpc = tpc! + 7;
    } else if (accidental == 'b') {
      tpc = tpc! - 7;
    } else {
      return null;
    }
  }
  return tpc;
}

String _tpcToName(int tpc) {
  final letter = 'FCGDAEB'[(tpc + 1) % 7];
  // Floor division: Dart's ~/ truncates toward zero, wrong for flat-side tpc.
  final accidentals = ((tpc + 1) - ((tpc + 1) % 7)) ~/ 7;
  return letter + (accidentals > 0 ? '#' * accidentals : 'b' * -accidentals);
}

void main(List<String> args) {
  final options = _parseArgs(args);
  final fixtureSet = FixtureSet.load(Directory(options['fixtures']!));
  final labels =
      jsonDecode(File(options['labels']!).readAsStringSync())
          as Map<String, dynamic>;
  final pieces = (labels['pieces'] as Map).cast<String, dynamic>();

  final splitFile = SplitFile.load(File(options['split-file']!));
  splitFile.validateAgainst(fixtureSet);
  final titles = splitFile
      .pieceTitles(options['split'] ?? 'development')
      .toSet();
  final selected = [
    for (final fixture in fixtureSet.fixtures)
      if (titles.contains(fixture.title)) fixture,
  ];

  final behavior = KeyBehavior.values.byName(options['behavior'] ?? 'stable');
  final neutral = _contextFor(fixtureSet.manifest['context'] as String);

  final perPiece = <Map<String, dynamic>>[];
  final pooled = {
    for (final arm in _arms)
      arm: {
        'identityCorrect': 0,
        'tones': 0,
        'tonesCorrect': 0,
        'roots': 0,
        'rootsCorrect': 0,
        'eventsAllCorrect': 0,
      },
  };
  var pooledN = 0, conflictedPcs = 0, unmappedNames = 0;
  final confusions = {for (final arm in _arms) arm: <String, int>{}};

  for (final fixture in selected) {
    final entries = (pieces[fixture.id] as List).cast<Map>();
    final detector = HmmKeyDetector(decayHalfLife: behavior.emissionHalfLife);
    Tonality? inferred;
    var n = 0;
    final pieceTones = {for (final arm in _arms) arm: 0};
    final pieceTonesCorrect = {for (final arm in _arms) arm: 0};

    for (var i = 0; i < fixture.events.length; i++) {
      final event = fixture.events[i];
      final entry = entries[i].cast<String, dynamic>();
      final inferredBefore = inferred;
      inferred = detector.onEvent(event).claim?.tonality ?? inferred;
      if (event.input.noteCount < _minNotes) continue;
      if (entry['category'] != 'ok') continue;
      final expected = (entry['expected'] as Map).cast<String, dynamic>();
      final expectedQuality = expected['quality'] as String?;
      if (expectedQuality == null) continue;
      final expectedRootPc = expected['rootPc'] as int;
      final spelling = (entry['spelling'] as Map? ?? const {})
          .cast<String, dynamic>();
      if (spelling.isEmpty) continue;

      n++;
      pooledN++;
      for (final arm in _arms) {
        final tonality = switch (arm) {
          'neutral' => neutral.tonality,
          'inferred' => inferredBefore ?? neutral.tonality,
          _ => parseTonality(entry['localKey'] as String),
        };
        final ranked = _analyzer.analyze(
          event.input,
          context: _contextForTonality(tonality),
          voicing: event.voicing,
          take: _take,
        );
        final identity = ranked.first.identity;
        if (identity.rootPc != expectedRootPc ||
            identity.quality.name != expectedQuality) {
          continue;
        }
        final tallies = pooled[arm]!;
        tallies['identityCorrect'] = tallies['identityCorrect']! + 1;

        final rootName = spellChordRoot(identity, tonality: tonality);
        var allCorrect = true;
        var scoredAny = false;
        for (var pc = 0; pc < 12; pc++) {
          if (event.input.pcMask & (1 << pc) == 0) continue;
          final truth = (spelling['$pc'] as List?)?.cast<int>();
          if (truth == null) continue;
          if (truth.length != 1) {
            conflictedPcs++;
            continue;
          }
          final interval = (pc - identity.rootPc) % 12;
          final role = identity.toneRolesByInterval[interval];
          final name = pc == identity.rootPc
              ? rootName
              : role != null
              ? spellPitchClass(
                  pc,
                  tonality: tonality,
                  chordRootName: rootName,
                  role: role,
                )
              : noteNameForPitchClass(pc, tonality: tonality);
          final got = _nameToTpc(name);
          if (got == null) {
            unmappedNames++;
            continue;
          }
          scoredAny = true;
          tallies['tones'] = tallies['tones']! + 1;
          pieceTones[arm] = pieceTones[arm]! + 1;
          final correct = got == truth.single;
          if (correct) {
            tallies['tonesCorrect'] = tallies['tonesCorrect']! + 1;
            pieceTonesCorrect[arm] = pieceTonesCorrect[arm]! + 1;
          } else {
            allCorrect = false;
            final key = '${_tpcToName(got)}->${_tpcToName(truth.single)}';
            confusions[arm]![key] = (confusions[arm]![key] ?? 0) + 1;
          }
          if (pc == identity.rootPc) {
            tallies['roots'] = tallies['roots']! + 1;
            if (correct) {
              tallies['rootsCorrect'] = tallies['rootsCorrect']! + 1;
            }
          }
        }
        if (scoredAny && allCorrect) {
          tallies['eventsAllCorrect'] = tallies['eventsAllCorrect']! + 1;
        }
      }
    }
    if (n == 0) continue;
    perPiece.add({
      'id': fixture.id,
      'n': n,
      for (final arm in _arms)
        arm: pieceTones[arm]! == 0
            ? null
            : pieceTonesCorrect[arm]! / pieceTones[arm]!,
    });
  }

  final report = {
    'schema': 'chord-context-spelling/1',
    'set': fixtureSet.name,
    'configuration': {
      'fixtures': options['fixtures'],
      'labels': options['labels'],
      'splitFile': options['split-file'],
      'split': options['split'] ?? 'development',
      'take': _take,
      'minNotes': _minNotes,
      'behavior': behavior.name,
    },
    'pooled': {
      'n': pooledN,
      'conflictedPcs': conflictedPcs,
      'unmappedNames': unmappedNames,
      for (final arm in _arms) arm: pooled[arm],
    },
    'confusions': {
      for (final arm in _arms)
        arm: Map.fromEntries(
          (confusions[arm]!.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .take(20),
        ),
    },
    'perPiece': perPiece,
  };
  final outDir = Directory(options['out']!)..createSync(recursive: true);
  File(
    '${outDir.path}/report.json',
  ).writeAsStringSync('${const JsonEncoder.withIndent(' ').convert(report)}\n');

  String pct(int a, int b) =>
      b == 0 ? 'n/a' : '${(a / b * 100).toStringAsFixed(2)}%';
  stdout.writeln(
    'spelling headroom [${behavior.name}]: ${fixtureSet.name} '
    '(${perPiece.length} pieces, n=$pooledN scoreable events, '
    '$conflictedPcs conflicted pcs skipped)',
  );
  for (final arm in _arms) {
    final tallies = pooled[arm]!;
    stdout.writeln(
      '  $arm: identity ${pct(tallies['identityCorrect']!, pooledN)}  '
      'tones ${pct(tallies['tonesCorrect']!, tallies['tones']!)}  '
      'roots ${pct(tallies['rootsCorrect']!, tallies['roots']!)}  '
      'events-all-correct '
      '${pct(tallies['eventsAllCorrect']!, tallies['identityCorrect']!)}',
    );
    final top = confusions[arm]!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (top.isNotEmpty) {
      stdout.writeln(
        '    top confusions: '
        '${top.take(6).map((e) => '${e.key} x${e.value}').join(', ')}',
      );
    }
  }
}

Map<String, String> _parseArgs(List<String> args) {
  final options = <String, String>{};
  for (var i = 0; i < args.length; i += 2) {
    if (!args[i].startsWith('--') || i + 1 >= args.length) {
      throw ArgumentError('Expected --flag value pairs, got: ${args[i]}');
    }
    options[args[i].substring(2)] = args[i + 1];
  }
  for (final required in ['fixtures', 'labels', 'split-file', 'out']) {
    if (!options.containsKey(required)) {
      throw ArgumentError('Missing required --$required');
    }
  }
  return options;
}

AnalysisContext _contextFor(String wire) =>
    _contextForTonality(parseTonality(wire));

AnalysisContext _contextForTonality(Tonality tonality) {
  final keySignature = KeySignature.fromTonality(tonality);
  return AnalysisContext(
    tonality: tonality,
    keySignature: keySignature,
    spellingPolicy: NoteSpellingPolicy(preferFlats: keySignature.prefersFlats),
  );
}
