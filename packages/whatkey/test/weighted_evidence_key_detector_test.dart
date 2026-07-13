import 'package:test/test.dart';

import 'package:whatchord/whatchord.dart';
import 'package:whatkey/whatkey.dart';

const _cMajorTonality = Tonality(Tonic.c, TonalityMode.major);

ChordEvent _event(
  int index,
  List<int> pcs,
  ChordQualityToken quality, {
  double alternativeCostGap = double.infinity,
}) {
  var mask = 0;
  for (final pc in pcs) {
    mask |= 1 << (pc % 12);
  }
  final identity = ChordIdentity(
    rootPc: pcs.first % 12,
    bassPc: pcs.first % 12,
    quality: quality,
    presentIntervalsMask: 1,
  );
  return ChordEvent(
    timestamp: DateTime.fromMillisecondsSinceEpoch(index * 2000),
    input: ChordInput(
      pcMask: mask,
      bassPc: pcs.first % 12,
      noteCount: pcs.length,
    ),
    voicing: ObservedVoicing.fromMidi([for (final pc in pcs) 60 + pc]),
    candidates: [
      ChordCandidate(identity: identity, cost: 0),
      if (alternativeCostGap.isFinite)
        ChordCandidate(
          identity: ChordIdentity(
            rootPc: (pcs.first + 3) % 12,
            bassPc: pcs.first % 12,
            quality: ChordQualityToken.major,
            presentIntervalsMask: 1,
          ),
          cost: alternativeCostGap,
        ),
    ],
    tonality: _cMajorTonality,
    duration: const Duration(seconds: 2),
  );
}

List<KeyEstimateFrame> _run(
  WeightedEvidenceKeyDetector detector,
  List<ChordEvent> events,
) {
  detector.reset();
  return [for (final event in events) detector.onEvent(event)];
}

void main() {
  final cCadence = [
    _event(0, [0, 4, 7], ChordQualityToken.major),
    _event(1, [5, 9, 0], ChordQualityToken.major),
    _event(2, [7, 11, 2, 5], ChordQualityToken.dominant7),
    _event(3, [0, 4, 7], ChordQualityToken.major),
  ];

  test('claims C major for a C major cadence', () {
    final frames = _run(WeightedEvidenceKeyDetector(), cCadence);
    final claim = frames.last.claim;
    expect(claim, isNotNull);
    expect(claim!.tonality.tonicPitchClass, 0);
    expect(claim.tonality.isMajor, isTrue);
  });

  test('abstains until minEvents have arrived', () {
    final frames = _run(WeightedEvidenceKeyDetector(), cCadence);
    expect(frames[0].isAbstention, isTrue);
    expect(frames[1].isAbstention, isTrue);
    expect(frames[2].isAbstention, isFalse);
  });

  test('claims A minor for a harmonic-minor cadence with E7', () {
    final frames = _run(WeightedEvidenceKeyDetector(), [
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

  test('E7 in A minor scores as diatonic dominant, not chromatic', () {
    // Under a natural-minor-only scale, E7's G# would take a chromatic
    // penalty in A minor. With the harmonic-minor union it is diatonic and
    // carries the dominant bonus, so a lone E7 must rank A minor at the top
    // alongside A major (where it is also V7), never below it.
    final frames = _run(WeightedEvidenceKeyDetector(minEvents: 1), [
      _event(0, [4, 8, 11, 2], ChordQualityToken.dominant7),
    ]);
    final ranked = frames.single.ranked;
    final aMinorRank = ranked.indexWhere(
      (e) => e.tonality.tonicPitchClass == 9 && e.tonality.isMinor,
    );
    final aMajorRank = ranked.indexWhere(
      (e) => e.tonality.tonicPitchClass == 9 && e.tonality.isMajor,
    );
    expect(aMinorRank, lessThanOrEqualTo(1));
    expect(
      ranked[aMinorRank].confidence,
      closeTo(ranked[aMajorRank].confidence, 1e-9),
    );
  });

  test(
    'dead-tie identities carry no weight when confidence weighting is on',
    () {
      // The C cadence, but every identity reported as a dead tie.
      final ambiguous = [
        _event(0, [0, 4, 7], ChordQualityToken.major, alternativeCostGap: 0),
        _event(1, [5, 9, 0], ChordQualityToken.major, alternativeCostGap: 0),
        _event(
          2,
          [7, 11, 2, 5],
          ChordQualityToken.dominant7,
          alternativeCostGap: 0,
        ),
        _event(3, [0, 4, 7], ChordQualityToken.major, alternativeCostGap: 0),
      ];
      final weighted = _run(WeightedEvidenceKeyDetector(), ambiguous);
      expect(weighted.every((frame) => frame.isAbstention), isTrue);

      final unweighted = _run(
        WeightedEvidenceKeyDetector(confidenceWeighted: false),
        ambiguous,
      );
      expect(unweighted.last.isAbstention, isFalse);
    },
  );

  test('decay lets the claim follow a modulation to the dominant', () {
    final frames = _run(WeightedEvidenceKeyDetector(), [
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

  test('a dominant-quality tonic is home evidence, not only V-of-IV', () {
    // A lone C7: without the tonic bonus, F major scores +9 (diatonic root,
    // all tones diatonic, dominant-on-V) while C major scores +1 (root
    // diatonic, Bb chromatic). The bonus must narrow that structural gap.
    final event = _event(0, [0, 4, 7, 10], ChordQualityToken.dominant7);
    double gap(WeightedEvidenceKeyDetector detector) {
      detector.reset();
      final ranked = detector.onEvent(event).ranked;
      double confidence(int pc) => ranked
          .firstWhere(
            (e) => e.tonality.tonicPitchClass == pc && e.tonality.isMajor,
          )
          .confidence;
      return confidence(5) - confidence(0);
    }

    final without = gap(WeightedEvidenceKeyDetector(minEvents: 1));
    final with_ = gap(
      WeightedEvidenceKeyDetector(tonicBonusPoints: 4, minEvents: 1),
    );
    expect(with_, lessThan(without));
    expect(with_, greaterThan(0)); // F still leads on one chord; that is fair.
  });

  test('ranked list covers all 24 keys exactly once', () {
    final frames = _run(WeightedEvidenceKeyDetector(), cCadence);
    final ranked = frames.last.ranked;
    expect(ranked, hasLength(24));
    final distinct = {
      for (final estimate in ranked)
        estimate.tonality.tonicPitchClass * 2 +
            (estimate.tonality.isMinor ? 1 : 0),
    };
    expect(distinct, hasLength(24));
  });
}
