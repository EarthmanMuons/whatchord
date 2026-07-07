import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/key/key.dart';

import '../tool/src/chord_id_engine.dart';
import '../tool/src/whatkey/whatkey_fixtures.dart';
import '../tool/src/whatkey/whatkey_scoring.dart';

Map<String, Object?> _eventJson(
  int index, {
  String? localKey,
  List<String>? acceptableKeys,
  int durationMs = 2000,
}) => {
  'index': index,
  'timestampMs': index * 2000,
  'durationMs': durationMs,
  'midiNotes': [48, 60, 64, 67],
  'pcMask': 0x91,
  'bassPc': 0,
  'noteCount': 4,
  'candidates': [
    {
      'rootPc': 0,
      'bassPc': 0,
      'quality': 'major',
      'extensions': <String>[],
      'presentIntervalsMask': 0x91,
      'cost': 0.0,
    },
  ],
  'labels': {'localKey': localKey, 'acceptableKeys': ?acceptableKeys},
};

LabeledFixture _fixture(List<Map<String, Object?>> events) {
  final dir = Directory.systemTemp.createTempSync('whatkey-scoring-test');
  addTearDown(() => dir.deleteSync(recursive: true));
  File('${dir.path}/manifest.json').writeAsStringSync(
    jsonEncode({
      'schema': 'whatkey-manifest/1',
      'set': 'test-set',
      'context': 'C:maj',
      'source': {'type': 'test'},
      'fixtures': [
        {
          'file': 'fixture.json',
          'id': 'test-set/fixture',
          'events': events.length,
        },
      ],
    }),
  );
  File('${dir.path}/fixture.json').writeAsStringSync(
    jsonEncode({
      'schema': 'whatkey-fixture/1',
      'id': 'test-set/fixture',
      'title': 'fixture',
      'labels': {},
      'events': events,
    }),
  );
  return FixtureSet.load(dir).fixtures.single;
}

KeyEstimateFrame _claim(String wire) {
  final estimate = KeyEstimate(tonality: parseTonality(wire), confidence: 1);
  return KeyEstimateFrame(ranked: [estimate], claim: estimate);
}

const _abstain = KeyEstimateFrame.abstain([]);

void main() {
  const cMajor = KeyLabel(0, isMinor: false);
  const aMinor = KeyLabel(9, isMinor: true);

  group('mirexWeight', () {
    test('exact match scores 1.0', () {
      expect(mirexWeight(cMajor, cMajor), 1.0);
      expect(mirexWeight(aMinor, aMinor), 1.0);
    });

    test('perfect fifth in either direction scores 0.5', () {
      const gMajor = KeyLabel(7, isMinor: false);
      const fMajor = KeyLabel(5, isMinor: false);
      expect(mirexWeight(gMajor, cMajor), 0.5);
      expect(mirexWeight(fMajor, cMajor), 0.5);
      expect(mirexWeight(KeyLabel(4, isMinor: true), aMinor), 0.5);
      expect(mirexWeight(KeyLabel(2, isMinor: true), aMinor), 0.5);
    });

    test('relative major/minor scores 0.3 both ways', () {
      expect(mirexWeight(aMinor, cMajor), 0.3);
      expect(mirexWeight(cMajor, aMinor), 0.3);
    });

    test('parallel major/minor scores 0.2', () {
      expect(mirexWeight(KeyLabel(0, isMinor: true), cMajor), 0.2);
      expect(mirexWeight(KeyLabel(9, isMinor: false), aMinor), 0.2);
    });

    test('unrelated keys score 0.0', () {
      expect(mirexWeight(KeyLabel(1, isMinor: false), cMajor), 0.0);
      expect(mirexWeight(KeyLabel(6, isMinor: true), cMajor), 0.0);
    });

    test('fifth relation requires matching mode', () {
      expect(mirexWeight(KeyLabel(7, isMinor: true), cMajor), 0.0);
    });
  });

  group('KeyLabel', () {
    test('parses wire format', () {
      expect(KeyLabel.parse('C:maj').matches(cMajor), isTrue);
      expect(KeyLabel.parse('A:min').matches(aMinor), isTrue);
      expect(
        KeyLabel.parse('F#:min').matches(KeyLabel(6, isMinor: true)),
        isTrue,
      );
      expect(
        KeyLabel.parse('Bb:maj').matches(KeyLabel(10, isMinor: false)),
        isTrue,
      );
    });
  });

  group('PieceScore', () {
    test('coverage and accuracy-on-claimed treat abstention as no error', () {
      final fixture = _fixture([
        for (var i = 0; i < 4; i++) _eventJson(i, localKey: 'C:maj'),
      ]);
      final score = PieceScore.compute(fixture, [
        _abstain,
        _claim('C:maj'),
        _claim('G:maj'),
        _claim('C:maj'),
      ]);

      expect(score.coverage, 0.75);
      expect(score.labeledClaimed, 3);
      expect(score.exactOnClaimed, closeTo(2 / 3, 1e-9));
      expect(score.mirexOnClaimed, closeTo((1 + 0.5 + 1) / 3, 1e-9));
      expect(score.timeToFirstClaim, 1);
    });

    test('switches are counted between consecutive claims only', () {
      final fixture = _fixture([
        for (var i = 0; i < 4; i++) _eventJson(i, localKey: 'C:maj'),
      ]);
      final sameAcrossAbstain = PieceScore.compute(fixture, [
        _claim('C:maj'),
        _abstain,
        _claim('C:maj'),
        _abstain,
      ]);
      expect(sameAcrossAbstain.switches, 0);

      final changedAcrossAbstain = PieceScore.compute(fixture, [
        _claim('C:maj'),
        _abstain,
        _claim('G:maj'),
        _abstain,
      ]);
      expect(changedAcrossAbstain.switches, 1);
      // Annotation never changed, so the switch is spurious.
      expect(changedAcrossAbstain.spuriousSwitches, 1);
    });

    test(
      'modulation lag counts events until the detector reaches the new key',
      () {
        final fixture = _fixture([
          _eventJson(0, localKey: 'C:maj'),
          _eventJson(1, localKey: 'C:maj'),
          _eventJson(2, localKey: 'G:maj'),
          _eventJson(3, localKey: 'G:maj'),
          _eventJson(4, localKey: 'G:maj'),
        ]);
        final matched = PieceScore.compute(fixture, [
          _claim('C:maj'),
          _claim('C:maj'),
          _claim('C:maj'),
          _claim('G:maj'),
          _claim('G:maj'),
        ]);
        expect(matched.annotatedChanges, 1);
        expect(matched.modulationLags, [1]);
        expect(matched.censoredModulations, 0);
        // The C->G switch at the annotated change is not spurious.
        expect(matched.spuriousSwitches, 0);

        final censored = PieceScore.compute(fixture, [
          for (var i = 0; i < 5; i++) _claim('C:maj'),
        ]);
        expect(censored.modulationLags, isEmpty);
        expect(censored.censoredModulations, 1);
      },
    );

    test('ambiguous events accept abstention or acceptable keys and stay out '
        'of accuracy pools', () {
      final fixture = _fixture([
        _eventJson(0, acceptableKeys: ['A:min', 'C:maj']),
        _eventJson(1, acceptableKeys: ['A:min', 'C:maj']),
        _eventJson(2, acceptableKeys: ['A:min', 'C:maj']),
      ]);
      final score = PieceScore.compute(fixture, [
        _abstain,
        _claim('A:min'),
        _claim('D:maj'),
      ]);
      expect(score.ambiguousEvents, 3);
      expect(score.ambiguousOk, 2);
      expect(score.labeledClaimed, 0);
    });

    test('global key scores final and duration-weighted majority claims', () {
      final fixture = _fixture([
        _eventJson(0, localKey: 'C:maj', durationMs: 4000),
        _eventJson(1, localKey: 'C:maj', durationMs: 4000),
        _eventJson(2, localKey: 'C:maj', durationMs: 1000),
      ]);
      final score = PieceScore.compute(fixture, [
        _claim('C:maj'),
        _claim('C:maj'),
        _claim('G:maj'),
      ]);
      expect(score.globalTruth?.matches(cMajor), isTrue);
      expect(score.globalFinalMirex, 0.5);
      expect(score.globalMajorityMirex, 1.0);
    });
  });
}
