import 'package:test/test.dart';

import 'package:whatchord/whatchord.dart';
import 'package:whatkey/whatkey.dart';

const _cMajorTonality = Tonality(Tonic.c, TonalityMode.major);

ChordEvent _event(int index, List<int> pcs, ChordQuality quality) {
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

void main() {
  final cCadence = [
    _event(0, [0, 4, 7], ChordQuality.major),
    _event(1, [5, 9, 0], ChordQuality.major),
    _event(2, [7, 11, 2, 5], ChordQuality.dominant7),
    _event(3, [0, 4, 7], ChordQuality.major),
  ];

  test('claims C major for a C major cadence', () {
    final frames = _run(BocpdKeyDetector(), cCadence);
    final claim = frames.last.claim;
    expect(claim, isNotNull);
    expect(claim!.tonality.tonicPitchClass, 0);
    expect(claim.tonality.isMajor, isTrue);
  });

  test('marginal confidences are probabilities summing to one', () {
    final frames = _run(BocpdKeyDetector(), cCadence);
    final ranked = frames.last.ranked;
    expect(ranked, hasLength(24));
    final total = ranked.fold(0.0, (sum, e) => sum + e.confidence);
    expect(total, closeTo(1.0, 1e-9));
    for (final estimate in ranked) {
      expect(estimate.confidence, inInclusiveRange(0, 1));
    }
  });

  test('abstains until minEvents have arrived', () {
    final frames = _run(BocpdKeyDetector(), cCadence);
    expect(frames[0].isAbstention, isTrue);
    expect(frames[1].isAbstention, isTrue);
  });

  test('a sustained modulation switches the claim', () {
    final frames = _run(BocpdKeyDetector(), [
      ...cCadence,
      for (var i = 0; i < 6; i++) ...[
        _event(4 + 2 * i, [2, 6, 9, 0], ChordQuality.dominant7),
        _event(5 + 2 * i, [7, 11, 2], ChordQuality.major),
      ],
    ]);
    final claim = frames.last.claim;
    expect(claim, isNotNull);
    expect(claim!.tonality.tonicPitchClass, 7);
    expect(claim.tonality.isMajor, isTrue);
  });

  test('an established key persists through a single tonicization', () {
    final frames = _run(BocpdKeyDetector(), [
      ...cCadence,
      _event(4, [2, 6, 9, 0], ChordQuality.dominant7), // V7/V
      _event(5, [7, 11, 2, 5], ChordQuality.dominant7),
      _event(6, [0, 4, 7], ChordQuality.major),
    ]);
    for (final frame in frames.skip(3)) {
      final claim = frame.claim;
      if (claim != null) {
        expect(claim.tonality.tonicPitchClass, 0, reason: '$frame');
      }
    }
  });

  test('run-length truncation keeps the posterior normalized', () {
    final detector = BocpdKeyDetector(maxRunLength: 8);
    final frames = _run(detector, [
      for (var i = 0; i < 40; i++) _event(i, [0, 4, 7], ChordQuality.major),
    ]);
    final total = frames.last.ranked.fold(0.0, (s, e) => s + e.confidence);
    expect(total, closeTo(1.0, 1e-9));
    expect(frames.last.claim!.tonality.tonicPitchClass, 0);
  });
}
