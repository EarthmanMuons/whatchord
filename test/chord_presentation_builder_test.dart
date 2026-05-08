import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/theory/theory.dart';

void main() {
  const notation = ChordNotationStyle.textual;

  test('builds presentation for a diatonic triad', () {
    final identity = _identity(
      root: 'C',
      quality: ChordQualityToken.major,
      intervals: const [0, 4, 7],
    );

    final presentation = ChordPresentationBuilder.fromIdentity(
      identity: identity,
      tonality: const Tonality('C', TonalityMode.major),
      notation: notation,
    );

    expect(presentation.symbol.toString(), 'C');
    expect(presentation.longLabel, 'C major');
    expect(presentation.members, ['C', 'E', 'G']);
    expect(presentation.memberDegrees, ['1', '3', '5']);
    expect(presentation.scaleDegree, ScaleDegree.one);
    expect(presentation.normalizedVoicing, [60, 64, 67]);
  });

  test('rotates first-inversion slash bass into a compact voicing', () {
    final identity = _identity(
      root: 'C',
      bass: 'E',
      quality: ChordQualityToken.major,
      intervals: const [0, 4, 7],
    );

    final presentation = ChordPresentationBuilder.fromIdentity(
      identity: identity,
      tonality: const Tonality('C', TonalityMode.major),
      notation: notation,
    );

    expect(presentation.symbol.toString(), 'C / E');
    expect(presentation.longLabel, 'C major over E');
    expect(presentation.normalizedVoicing, [52, 55, 60]);
  });

  test('rotates second-inversion slash bass into a compact voicing', () {
    final identity = _identity(
      root: 'C',
      bass: 'G',
      quality: ChordQualityToken.major,
      intervals: const [0, 4, 7],
    );

    final presentation = ChordPresentationBuilder.fromIdentity(
      identity: identity,
      tonality: const Tonality('C', TonalityMode.major),
      notation: notation,
    );

    expect(presentation.normalizedVoicing, [55, 60, 64]);
  });

  test('rotates seventh-chord slash bass without duplicated pitch classes', () {
    final identity = _identity(
      root: 'C',
      bass: 'Bb',
      quality: ChordQualityToken.dominant7,
      intervals: const [0, 4, 7, 10],
    );

    final presentation = ChordPresentationBuilder.fromIdentity(
      identity: identity,
      tonality: const Tonality('C', TonalityMode.major),
      notation: notation,
    );

    expect(presentation.normalizedVoicing, [58, 60, 64, 67]);
  });

  test('keeps extensions above the selected slash bass', () {
    final identity = _identity(
      root: 'C',
      bass: 'E',
      quality: ChordQualityToken.dominant7,
      extensions: const {ChordExtension.nine},
      intervals: const [0, 2, 4, 7, 10],
    );

    final presentation = ChordPresentationBuilder.fromIdentity(
      identity: identity,
      tonality: const Tonality('C', TonalityMode.major),
      notation: notation,
    );

    expect(presentation.normalizedVoicing, [52, 55, 58, 60, 62]);
  });

  test('stacks root-position seventh extensions above the core chord', () {
    final identity = _identity(
      root: 'C',
      quality: ChordQualityToken.dominant7,
      extensions: const {ChordExtension.nine},
      intervals: const [0, 2, 4, 7, 10],
    );

    final presentation = ChordPresentationBuilder.fromIdentity(
      identity: identity,
      tonality: const Tonality('C', TonalityMode.major),
      notation: notation,
    );

    expect(presentation.normalizedVoicing, [60, 64, 67, 70, 74]);
  });

  test('includes extension labels and altered member degrees', () {
    final identity = _identity(
      root: 'G',
      quality: ChordQualityToken.dominant7,
      extensions: const {ChordExtension.flat9, ChordExtension.sharp11},
      intervals: const [0, 4, 6, 7, 10, 1],
    );

    final presentation = ChordPresentationBuilder.fromIdentity(
      identity: identity,
      tonality: const Tonality('C', TonalityMode.major),
      notation: notation,
    );

    expect(presentation.symbol.toString(), 'G7(b9,#11)');
    expect(presentation.members, ['G', 'Ab', 'B', 'C#', 'D', 'F']);
    expect(presentation.memberDegrees, ['1', '3', '5', 'b7', 'b9', '#11']);
    expect(presentation.scaleDegree, isNull);
  });

  test('returns null scale degree for non-diatonic presentation', () {
    final identity = _identity(
      root: 'Db',
      quality: ChordQualityToken.major,
      intervals: const [0, 4, 7],
    );

    final presentation = ChordPresentationBuilder.fromIdentity(
      identity: identity,
      tonality: const Tonality('C', TonalityMode.major),
      notation: notation,
    );

    expect(presentation.symbol.toString(), 'C#');
    expect(presentation.scaleDegree, isNull);
  });
}

ChordIdentity _identity({
  required String root,
  required ChordQualityToken quality,
  required List<int> intervals,
  String? bass,
  Set<ChordExtension> extensions = const {},
}) {
  final presentIntervalsMask = _maskOfIntervals(intervals);

  return ChordIdentity(
    rootPc: pitchClassFromNoteName(root),
    bassPc: pitchClassFromNoteName(bass ?? root),
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

int _maskOfIntervals(Iterable<int> intervals) {
  var mask = 0;
  for (final interval in intervals) {
    mask |= 1 << (interval % 12);
  }
  return mask;
}
