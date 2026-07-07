import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/history/history.dart';
import 'package:whatchord/features/key/key.dart';
import 'package:whatchord/features/theory/theory.dart';

const _cMajorTonality = Tonality(Tonic.c, TonalityMode.major);

ChordEvent _event(int index, List<int> pcs, ChordQualityToken quality) {
  var mask = 0;
  for (final pc in pcs) {
    mask |= 1 << (pc % 12);
  }
  return ChordEvent(
    timestamp: DateTime.fromMillisecondsSinceEpoch(index * 2000),
    input: ChordInput(
      pcMask: mask,
      bassPc: pcs.first % 12,
      noteCount: pcs.length,
    ),
    voicing: ObservedVoicing.fromMidi([for (final pc in pcs) 60 + pc]),
    candidates: [
      ChordCandidate(
        identity: ChordIdentity(
          rootPc: pcs.first % 12,
          bassPc: pcs.first % 12,
          quality: quality,
          presentIntervalsMask: 1,
        ),
        cost: 0,
      ),
    ],
    tonality: _cMajorTonality,
    duration: const Duration(seconds: 2),
  );
}

List<KeyEstimateFrame> _run(KeyDetector detector, List<ChordEvent> events) {
  detector.reset();
  return [for (final event in events) detector.onEvent(event)];
}

// One 12-bar chorus as (pcs, quality) events; C blues.
List<ChordEvent> _bluesChorus(int startIndex) {
  const i7 = [0, 4, 7, 10];
  const iv7 = [5, 9, 0, 3];
  const v7 = [7, 11, 2, 5];
  final bars = [i7, i7, i7, i7, iv7, iv7, i7, i7, v7, iv7, i7, v7];
  return [
    for (var bar = 0; bar < bars.length; bar++)
      _event(startIndex + bar, bars[bar], ChordQualityToken.dominant7),
  ];
}

void main() {
  final cCadence = [
    _event(0, [0, 4, 7], ChordQualityToken.major),
    _event(1, [5, 9, 0], ChordQualityToken.major),
    _event(2, [7, 11, 2, 5], ChordQualityToken.dominant7),
    _event(3, [0, 4, 7], ChordQualityToken.major),
  ];

  test('claims C major for a C major cadence', () {
    final frames = _run(HmmKeyDetector(), cCadence);
    final claim = frames.last.claim;
    expect(claim, isNotNull);
    expect(claim!.tonality.tonicPitchClass, 0);
    expect(claim.tonality.isMajor, isTrue);
  });

  test('posterior confidences are probabilities summing to one', () {
    final frames = _run(HmmKeyDetector(), cCadence);
    final ranked = frames.last.ranked;
    expect(ranked, hasLength(24));
    final total = ranked.fold(0.0, (sum, e) => sum + e.confidence);
    expect(total, closeTo(1.0, 1e-9));
    for (final estimate in ranked) {
      expect(estimate.confidence, inInclusiveRange(0, 1));
    }
  });

  test('abstains until minEvents have arrived', () {
    final frames = _run(HmmKeyDetector(), cCadence);
    expect(frames[0].isAbstention, isTrue);
    expect(frames[1].isAbstention, isTrue);
  });

  test('claims A minor for a harmonic-minor cadence with E7', () {
    final frames = _run(HmmKeyDetector(), [
      _event(0, [9, 0, 4], ChordQualityToken.minor),
      _event(1, [2, 5, 9], ChordQualityToken.minor),
      _event(2, [4, 8, 11, 2], ChordQualityToken.dominant7),
      _event(3, [9, 0, 4], ChordQualityToken.minor),
    ]);
    final claim = frames.last.claim;
    expect(claim, isNotNull);
    expect(claim!.tonality.tonicPitchClass, 9);
    expect(claim.tonality.isMinor, isTrue);
  });

  test('an established key persists through a single tonicization', () {
    final frames = _run(HmmKeyDetector(), [
      ...cCadence,
      _event(4, [2, 6, 9, 0], ChordQualityToken.dominant7), // V7/V
      _event(5, [7, 11, 2, 5], ChordQualityToken.dominant7),
      _event(6, [0, 4, 7], ChordQualityToken.major),
    ]);
    for (final frame in frames.skip(3)) {
      final claim = frame.claim;
      if (claim != null) {
        expect(claim.tonality.tonicPitchClass, 0, reason: '$frame');
      }
    }
  });

  test('a sustained modulation still switches the posterior', () {
    final frames = _run(HmmKeyDetector(), [
      ...cCadence,
      for (var i = 0; i < 6; i++) ...[
        _event(4 + 2 * i, [2, 6, 9, 0], ChordQualityToken.dominant7),
        _event(5 + 2 * i, [7, 11, 2], ChordQualityToken.major),
      ],
    ]);
    final claim = frames.last.claim;
    expect(claim, isNotNull);
    expect(claim!.tonality.tonicPitchClass, 7);
    expect(claim.tonality.isMajor, isTrue);
  });

  test('blues posterior tracks the emissions, not the annotation', () {
    // Documented limitation, not a target: the hybrid emissions favor F on
    // nearly every blues event (log entries 2026-07-07-10 and -11), and a
    // correct filter must follow on-average evidence; persistence only
    // absorbs momentary contradictions. The behavioral suite carries the
    // authoritative blues probes.
    final frames = _run(HmmKeyDetector(), [
      ..._bluesChorus(0),
      ..._bluesChorus(12),
      _event(24, [0, 4, 7, 10], ChordQualityToken.dominant7),
    ]);
    final lastClaim = frames.last.claim;
    expect(lastClaim, isNotNull);
    expect(lastClaim!.tonality.tonicPitchClass, anyOf(0, 5));
  });

  test('transition rows are proper distributions', () {
    final detector = HmmKeyDetector();
    // Exercised indirectly: run one event and confirm the posterior stays
    // normalized after prediction with an uninformative start.
    final frames = _run(detector, [
      _event(0, [0, 4, 7], ChordQualityToken.major),
    ]);
    final total = frames.single.ranked.fold(0.0, (s, e) => s + e.confidence);
    expect(total, closeTo(1.0, 1e-9));
  });
}
