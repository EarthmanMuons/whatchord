import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/theory/domain/theory_domain.dart';

void main() {
  test('altered dominant7 beats dim7 slash outside the near-tie window', () {
    final dominant = ChordCandidate(
      identity: _identity(
        quality: ChordQualityToken.dominant7,
        rootPc: 0,
        bassPc: 0,
        presentIntervals: const {0, 1, 4, 10},
        extensions: const {ChordExtension.flat9},
      ),
      score: 1,
    );

    final diminishedSlash = ChordCandidate(
      identity: _identity(
        quality: ChordQualityToken.diminished7,
        rootPc: 10,
        bassPc: 0,
        presentIntervals: const {0, 2, 3, 6, 9},
        extensions: const {ChordExtension.nine},
      ),
      // Intentionally outside the near-tie window in the other direction.
      score: 10,
    );

    _expectRule(
      dominant,
      diminishedSlash,
      'Prefer altered dominant7 over dim7 slash',
    );
  });

  test('conventional altered seventh beats non-dominant add11 slash', () {
    final conventional = ChordCandidate(
      identity: _identity(
        quality: ChordQualityToken.minorMajor7,
        rootPc: 5,
        bassPc: 8,
        presentIntervals: const {0, 3, 6, 7, 11},
        extensions: const {ChordExtension.sharp11},
      ),
      score: 9.6,
    );

    final add11Slash = ChordCandidate(
      identity: _identity(
        quality: ChordQualityToken.major7Sharp5,
        rootPc: 0,
        bassPc: 8,
        presentIntervals: const {0, 4, 5, 8, 11},
        extensions: const {ChordExtension.add11},
      ),
      score: 10,
    );

    _expectRule(
      conventional,
      add11Slash,
      'Prefer conventional altered seventh over add11 slash',
    );
  });

  test('complete minor sharp11 beats altered major7sus4', () {
    final minorSharp11 = ChordCandidate(
      identity: _identity(
        quality: ChordQualityToken.minor,
        rootPc: 9,
        bassPc: 4,
        presentIntervals: const {0, 3, 6, 7},
        extensions: const {ChordExtension.sharp11},
      ),
      score: 9.65,
    );

    final alteredSus = ChordCandidate(
      identity: _identity(
        quality: ChordQualityToken.major7sus4,
        rootPc: 4,
        bassPc: 4,
        presentIntervals: const {0, 5, 8, 11},
        extensions: const {ChordExtension.flat13},
      ),
      score: 10,
    );

    _expectRule(
      minorSharp11,
      alteredSus,
      'Prefer complete minor sharp11 over altered maj7sus4',
    );
  });

  test('root-position dominant7 beats close non-dominant slash', () {
    final dominant = ChordCandidate(
      identity: _identity(
        quality: ChordQualityToken.dominant7,
        rootPc: 0,
        bassPc: 0,
        presentIntervals: const {0, 1, 4, 6, 8, 10},
        extensions: const {
          ChordExtension.flat9,
          ChordExtension.sharp11,
          ChordExtension.flat13,
        },
      ),
      score: 9.79,
    );

    final remoteSlash = ChordCandidate(
      identity: _identity(
        quality: ChordQualityToken.minorMajor7,
        rootPc: 1,
        bassPc: 0,
        presentIntervals: const {0, 3, 7, 11},
      ),
      score: 10,
    );

    _expectRule(
      dominant,
      remoteSlash,
      'Prefer close root-position dominant7 over non-dominant slash',
    );
  });

  test('root-position altered-fifth dominant beats close slash reading', () {
    final rootPosition = ChordCandidate(
      identity: _identity(
        quality: ChordQualityToken.dominant7Flat5,
        rootPc: 0,
        bassPc: 0,
        presentIntervals: const {0, 3, 4, 6, 10},
        extensions: const {ChordExtension.sharp9},
      ),
      score: 9.6,
    );

    final slash = ChordCandidate(
      identity: _identity(
        quality: ChordQualityToken.dominant7Flat5,
        rootPc: 6,
        bassPc: 0,
        presentIntervals: const {0, 2, 4, 6, 10},
        extensions: const {ChordExtension.nine},
      ),
      score: 10,
    );

    _expectRule(
      rootPosition,
      slash,
      'Prefer root-position altered-fifth dominant over slash',
    );
  });

  test('complete triad beats incomplete inverted 6th in a near-tie', () {
    final completeTriad = ChordCandidate(
      identity: _identity(
        quality: ChordQualityToken.minor,
        rootPc: 4,
        bassPc: 11,
        presentIntervals: const {0, 3, 7},
      ),
      score: 7.42,
    );

    final incompleteSixth = ChordCandidate(
      identity: _identity(
        quality: ChordQualityToken.major6,
        rootPc: 7,
        bassPc: 11,
        presentIntervals: const {0, 4, 9},
      ),
      score: 7.50,
    );

    _expectTieRule(
      completeTriad,
      incompleteSixth,
      'Prefer complete triad over incomplete inverted 6th',
    );
  });
}

void _expectRule(
  ChordCandidate preferred,
  ChordCandidate other,
  String ruleName,
) {
  const tonality = Tonality('C', TonalityMode.major);

  final comparison = ChordCandidateRanking.compare(
    preferred,
    other,
    tonality: tonality,
  );
  final explanation = ChordCandidateRanking.explain(
    preferred,
    other,
    tonality: tonality,
  );

  expect(comparison, explanation.result);
  expect(comparison, -1);
  expect(explanation.decidedByRule, ruleName);
  expect(
    explanation.scoreDelta.abs(),
    greaterThan(ChordCandidateRanking.nearTieWindow),
  );
}

void _expectTieRule(
  ChordCandidate preferred,
  ChordCandidate other,
  String ruleName,
) {
  const tonality = Tonality('C', TonalityMode.major);

  final comparison = ChordCandidateRanking.compare(
    preferred,
    other,
    tonality: tonality,
  );
  final explanation = ChordCandidateRanking.explain(
    preferred,
    other,
    tonality: tonality,
  );

  expect(comparison, explanation.result);
  expect(comparison, -1);
  expect(explanation.decidedByRule, ruleName);
  expect(
    explanation.scoreDelta.abs(),
    lessThanOrEqualTo(ChordCandidateRanking.nearTieWindow),
  );
}

ChordIdentity _identity({
  required ChordQualityToken quality,
  required int rootPc,
  required int bassPc,
  required Set<int> presentIntervals,
  Set<ChordExtension> extensions = const {},
}) {
  final presentIntervalsMask = _mask(presentIntervals);

  return ChordIdentity(
    rootPc: rootPc,
    bassPc: bassPc,
    quality: quality,
    extensions: extensions,
    toneRolesByInterval: ChordToneRoles.build(
      quality: quality,
      extensions: extensions,
      relMask: presentIntervalsMask,
    ),
    presentIntervalsMask: presentIntervalsMask,
  );
}

int _mask(Set<int> intervals) {
  var mask = 0;
  for (final interval in intervals) {
    mask |= 1 << (interval % 12);
  }
  return mask;
}
