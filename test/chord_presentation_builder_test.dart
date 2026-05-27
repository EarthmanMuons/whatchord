import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/theory/theory.dart';
import 'package:whatchord/features/theory/presentation/services/inversion_formatter.dart';

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

  test('rotates first-inversion slash bass above root position', () {
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
    expect(presentation.normalizedVoicing, [64, 67, 72]);
  });

  test('rotates second-inversion slash bass above root position', () {
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

    expect(presentation.normalizedVoicing, [67, 72, 76]);
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

    expect(presentation.normalizedVoicing, [70, 72, 76, 79]);
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

    expect(presentation.normalizedVoicing, [64, 67, 70, 72, 74]);
  });

  test('uses upper-structure slash display for add9 slash bass triads', () {
    final identity = _identity(
      root: 'G',
      bass: 'A',
      quality: ChordQualityToken.major,
      extensions: const {ChordExtension.add9},
      intervals: const [0, 2, 4, 7],
    );

    final presentation = ChordPresentationBuilder.fromIdentity(
      identity: identity,
      tonality: const Tonality('C', TonalityMode.major),
      notation: notation,
    );

    expect(presentation.symbol.toString(), 'G / A');
    expect(presentation.longLabel, 'G major over A');
    expect(presentation.semanticLongLabel, 'G major over A');
    expect(InversionFormatter.format(identity), 'upper-structure slash');
    expect(presentation.members, ['G', 'A', 'B', 'D']);
    expect(presentation.memberDegrees, ['1', '3', '5', '9']);
  });

  test('keeps root-position add9 triads explicit', () {
    final identity = _identity(
      root: 'G',
      quality: ChordQualityToken.major,
      extensions: const {ChordExtension.add9},
      intervals: const [0, 2, 4, 7],
    );

    final presentation = ChordPresentationBuilder.fromIdentity(
      identity: identity,
      tonality: const Tonality('C', TonalityMode.major),
      notation: notation,
    );

    expect(presentation.symbol.toString(), 'Gadd9');
    expect(presentation.longLabel, 'G major with added ninth');
    expect(InversionFormatter.format(identity), isNull);
  });

  test('uses six-slash-bass display when slash bass supplies the ninth', () {
    final identity = _identity(
      root: 'C',
      bass: 'D',
      quality: ChordQualityToken.major6,
      extensions: const {ChordExtension.add9},
      intervals: const [0, 2, 4, 7, 9],
    );

    final presentation = ChordPresentationBuilder.fromIdentity(
      identity: identity,
      tonality: const Tonality('C', TonalityMode.major),
      notation: notation,
    );

    expect(presentation.symbol.toString(), 'C6 / D');
    expect(presentation.longLabel, 'C major sixth over D');
    expect(InversionFormatter.format(identity), 'slash bass: 9');
    expect(presentation.members, ['C', 'D', 'E', 'G', 'A']);
    expect(presentation.memberDegrees, ['1', '3', '5', '6', '9']);
  });

  test('uses conventional long labels for root-position six-nine chords', () {
    final major = _identity(
      root: 'C',
      quality: ChordQualityToken.major6,
      extensions: const {ChordExtension.add9},
      intervals: const [0, 2, 4, 7, 9],
    );
    final minor = _identity(
      root: 'C',
      quality: ChordQualityToken.minor6,
      extensions: const {ChordExtension.add9},
      intervals: const [0, 2, 3, 7, 9],
    );

    final majorPresentation = ChordPresentationBuilder.fromIdentity(
      identity: major,
      tonality: const Tonality('C', TonalityMode.major),
      notation: notation,
    );
    final minorPresentation = ChordPresentationBuilder.fromIdentity(
      identity: minor,
      tonality: const Tonality('C', TonalityMode.major),
      notation: notation,
    );

    expect(majorPresentation.symbol.toString(), 'C6/9');
    expect(majorPresentation.longLabel, 'C major six-nine');
    expect(minorPresentation.symbol.toString(), 'Cm6/9');
    expect(minorPresentation.longLabel, 'C minor six-nine');
  });

  test('keeps incomplete add9 slash triads explicit', () {
    final identity = _identity(
      root: 'G',
      bass: 'A',
      quality: ChordQualityToken.major,
      extensions: const {ChordExtension.add9},
      intervals: const [0, 2, 4],
    );

    final presentation = ChordPresentationBuilder.fromIdentity(
      identity: identity,
      tonality: const Tonality('C', TonalityMode.major),
      notation: notation,
    );

    expect(presentation.symbol.toString(), 'Gadd9 / A');
    expect(presentation.longLabel, 'G major with added ninth over A');
    expect(InversionFormatter.format(identity), 'non-root bass: add9');
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
    expect(
      presentation.longLabel,
      'G dominant seventh with flat ninth and sharp eleventh',
    );
    expect(presentation.members, ['G', 'Ab', 'B', 'C#', 'D', 'F']);
    expect(presentation.memberDegrees, ['1', '3', '5', 'b7', 'b9', '#11']);
    expect(presentation.scaleDegree, isNull);

    expect(
      ChordLongFormFormatter.format(
        identity: identity,
        tonality: const Tonality('C', TonalityMode.major),
        accidentalStyle: ChordLongFormAccidentalStyle.plainText,
      ),
      'G dominant seventh with flat ninth and sharp eleventh',
    );
  });

  test('promotes seventh-family natural extensions in long labels', () {
    final dominantNinth = _identity(
      root: 'C',
      quality: ChordQualityToken.dominant7,
      extensions: const {ChordExtension.nine},
      intervals: const [0, 2, 4, 7, 10],
    );
    final minorEleventh = _identity(
      root: 'D',
      quality: ChordQualityToken.minor7,
      extensions: const {ChordExtension.nine, ChordExtension.eleven},
      intervals: const [0, 2, 3, 5, 7, 10],
    );
    final majorThirteenth = _identity(
      root: 'F',
      quality: ChordQualityToken.major7,
      extensions: const {
        ChordExtension.nine,
        ChordExtension.eleven,
        ChordExtension.thirteen,
      },
      intervals: const [0, 2, 4, 5, 7, 9, 11],
    );

    expect(
      ChordLongFormFormatter.format(
        identity: dominantNinth,
        tonality: const Tonality('C', TonalityMode.major),
      ),
      'C dominant ninth',
    );
    expect(
      ChordLongFormFormatter.format(
        identity: minorEleventh,
        tonality: const Tonality('C', TonalityMode.major),
      ),
      'D minor eleventh',
    );
    expect(
      ChordLongFormFormatter.format(
        identity: majorThirteenth,
        tonality: const Tonality('C', TonalityMode.major),
      ),
      'F major thirteenth',
    );
  });

  test('keeps added tones and alterations as long-label modifiers', () {
    final minorAddEleventh = _identity(
      root: 'D',
      quality: ChordQualityToken.minor7,
      extensions: const {ChordExtension.add11},
      intervals: const [0, 3, 5, 7, 10],
    );
    final dominantSharpEleventh = _identity(
      root: 'G',
      quality: ChordQualityToken.dominant7,
      extensions: const {
        ChordExtension.nine,
        ChordExtension.sharp11,
        ChordExtension.thirteen,
      },
      intervals: const [0, 2, 4, 6, 7, 9, 10],
    );

    expect(
      ChordLongFormFormatter.format(
        identity: minorAddEleventh,
        tonality: const Tonality('C', TonalityMode.major),
      ),
      'D minor seventh with added eleventh',
    );
    expect(
      ChordLongFormFormatter.format(
        identity: dominantSharpEleventh,
        tonality: const Tonality('C', TonalityMode.major),
      ),
      'G dominant thirteenth with sharp eleventh',
    );
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

    expect(presentation.symbol.toString(), 'Db');
    expect(presentation.longLabel, 'D♭ major');
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
