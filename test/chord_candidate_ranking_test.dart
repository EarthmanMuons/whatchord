import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/theory/domain/theory_domain.dart';

void main() {
  test('compare and explain share hard-rule ranking decisions', () {
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

    const tonality = Tonality('C', TonalityMode.major);

    final comparison = ChordCandidateRanking.compare(
      dominant,
      diminishedSlash,
      tonality: tonality,
    );
    final explanation = ChordCandidateRanking.explain(
      dominant,
      diminishedSlash,
      tonality: tonality,
    );

    expect(comparison, explanation.result);
    expect(comparison, -1);
    expect(
      explanation.decidedByRule,
      'Prefer altered dominant7 over dim7 slash',
    );
    expect(
      explanation.scoreDelta.abs(),
      greaterThan(ChordCandidateRanking.nearTieWindow),
    );
  });
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
