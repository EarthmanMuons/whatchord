import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/theory/domain/theory_domain.dart';

import 'helpers/theory_test_helpers.dart';

void main() {
  test('complete dominant sharp-nine beats sixth flat-nine', () {
    final dominant = _candidate(
      quality: ChordQualityToken.dominant7,
      root: 'C',
      bass: 'Eb',
      presentIntervals: const {0, 3, 4, 7, 10},
      extensions: const {ChordExtension.sharp9},
      score: 7.88,
    );

    final sixthFlat9 = _candidate(
      quality: ChordQualityToken.major6,
      root: 'Eb',
      bass: 'Eb',
      presentIntervals: const {0, 1, 4, 7, 9},
      extensions: const {ChordExtension.flat9},
      score: 8.03,
    );

    _expectTieRule(
      dominant,
      sixthFlat9,
      'prefer complete dominant sharp-nine over split-third sixth',
    );
  });

  test('complete sharp-nine sharp-eleven dominant beats split-third sixth', () {
    final dominant = _candidate(
      quality: ChordQualityToken.dominant7,
      root: 'A',
      bass: 'C',
      presentIntervals: const {0, 3, 4, 6, 7, 10},
      extensions: const {ChordExtension.sharp9, ChordExtension.sharp11},
      score: 7.59,
    );

    final splitThirdSixth = _candidate(
      quality: ChordQualityToken.major6,
      root: 'C',
      bass: 'C',
      presentIntervals: const {0, 1, 3, 4, 7, 9},
      extensions: const {ChordExtension.flat9, ChordExtension.addSharp9},
      score: 7.74,
    );

    _expectTieRule(
      dominant,
      splitThirdSixth,
      'prefer complete dominant sharp-nine over split-third sixth',
    );
  });

  test(
    'complete thirteenth sharp-nine dominant beats colored split-third sixth',
    () {
      final dominant = _candidate(
        quality: ChordQualityToken.dominant7,
        root: 'A',
        bass: 'C',
        presentIntervals: const {0, 3, 4, 6, 7, 9, 10},
        extensions: const {
          ChordExtension.sharp9,
          ChordExtension.sharp11,
          ChordExtension.thirteen,
        },
        score: 7.3,
      );

      final splitThirdSixth = _candidate(
        quality: ChordQualityToken.major6,
        root: 'C',
        bass: 'C',
        presentIntervals: const {0, 1, 3, 4, 6, 7, 9},
        extensions: const {
          ChordExtension.flat9,
          ChordExtension.addSharp9,
          ChordExtension.sharp11,
        },
        score: 7.45,
      );

      _expectTieRule(
        dominant,
        splitThirdSixth,
        'prefer complete dominant sharp-nine over split-third sixth',
      );
    },
  );

  test(
    'complete flat-thirteenth sharp-nine dominant beats add-eleven split-third sixth',
    () {
      final dominant = _candidate(
        quality: ChordQualityToken.dominant7,
        root: 'F#',
        bass: 'E',
        presentIntervals: const {0, 3, 4, 6, 7, 8, 10},
        extensions: const {
          ChordExtension.sharp9,
          ChordExtension.sharp11,
          ChordExtension.flat13,
        },
        score: 7.45,
      );

      final splitThirdSixth = _candidate(
        quality: ChordQualityToken.major6,
        root: 'A',
        bass: 'E',
        presentIntervals: const {0, 1, 3, 4, 5, 7, 9},
        extensions: const {
          ChordExtension.flat9,
          ChordExtension.addSharp9,
          ChordExtension.add11,
        },
        score: 7.45,
      );

      _expectTieRule(
        dominant,
        splitThirdSixth,
        'prefer complete dominant sharp-nine over split-third sixth',
      );
    },
  );

  test('complete altered dominant inversion beats altered major7', () {
    final dominant = _candidate(
      quality: ChordQualityToken.dominant7Sharp5,
      root: 'A',
      bass: 'C#',
      presentIntervals: const {0, 3, 4, 8, 10},
      extensions: const {ChordExtension.sharp9},
      score: 8.2,
    );

    for (final quality in [
      ChordQualityToken.major7Flat5,
      ChordQualityToken.major7Sharp5,
    ]) {
      final alteredMajor7 = _candidate(
        quality: quality,
        root: 'C#',
        bass: 'C#',
        presentIntervals: const {0, 4, 6, 8, 11},
        extensions: const {ChordExtension.flat13},
        score: 8.2,
      );

      _expectTieRule(
        dominant,
        alteredMajor7,
        'prefer complete altered dominant inversion over altered major7',
      );
    }
  });

  test('split-nine tritone dominants follow the conventional bass role', () {
    ChordCandidate splitNine({required String bass, required double score}) =>
        _candidate(
          quality: ChordQualityToken.dominant7Flat5,
          root: 'C',
          bass: bass,
          presentIntervals: const {0, 1, 2, 4, 6, 10},
          extensions: const {ChordExtension.flat9, ChordExtension.nine},
          score: score,
        );
    ChordCandidate tritoneColor({
      required String bass,
      required double score,
    }) => _candidate(
      quality: ChordQualityToken.dominant7,
      root: 'F#',
      bass: bass,
      presentIntervals: const {0, 4, 6, 7, 8, 10},
      extensions: const {ChordExtension.sharp11, ChordExtension.flat13},
      score: score,
    );

    for (final bass in ['Bb', 'F#', 'Db']) {
      _expectRule(
        tritoneColor(bass: bass, score: 7.74),
        splitNine(bass: bass, score: 7.95),
        'prefer conventional inversion in split-nine tritone dominant ambiguity',
      );
    }
    for (final bass in ['C', 'E']) {
      _expectRule(
        splitNine(bass: bass, score: 7.95),
        tritoneColor(bass: bass, score: 7.74),
        'prefer conventional inversion in split-nine tritone dominant ambiguity',
      );
    }
  });

  test('complete dominant flat-nine beats colored diminished7', () {
    final dominant = _candidate(
      quality: ChordQualityToken.dominant7,
      root: 'C',
      bass: 'G',
      presentIntervals: const {0, 1, 4, 7, 10},
      extensions: const {ChordExtension.flat9},
      score: 8.03,
    );

    final diminished = _candidate(
      quality: ChordQualityToken.diminished7,
      root: 'G',
      bass: 'G',
      presentIntervals: const {0, 3, 5, 6, 9},
      extensions: const {ChordExtension.add11},
      score: 8.25,
    );

    _expectRule(
      dominant,
      diminished,
      'prefer complete dominant flat-nine over colored diminished7',
    );
  });

  test(
    'complete dominant flat-nine sharp-eleven beats colored diminished7',
    () {
      final dominant = _candidate(
        quality: ChordQualityToken.dominant7,
        root: 'F#',
        bass: 'Db',
        presentIntervals: const {0, 1, 4, 6, 7, 10},
        extensions: const {ChordExtension.flat9, ChordExtension.sharp11},
        score: 7.74,
      );

      final diminished = _candidate(
        quality: ChordQualityToken.diminished7,
        root: 'A#',
        bass: 'Db',
        presentIntervals: const {0, 2, 3, 6, 8},
        extensions: const {ChordExtension.nine, ChordExtension.flat13},
        score: 8.10,
      );

      _expectRule(
        dominant,
        diminished,
        'prefer complete dominant flat-nine over colored diminished7',
      );
    },
  );

  test('third-inversion dominant flat-nine does not override diminished7', () {
    final dominant = _candidate(
      quality: ChordQualityToken.dominant7,
      root: 'C',
      bass: 'Bb',
      presentIntervals: const {0, 1, 4, 7, 10},
      extensions: const {ChordExtension.flat9},
      score: 8.03,
    );

    final diminished = _candidate(
      quality: ChordQualityToken.diminished7,
      root: 'Bb',
      bass: 'Bb',
      presentIntervals: const {0, 2, 3, 6, 9},
      extensions: const {ChordExtension.nine},
      score: 8.25,
    );

    const tonality = Tonality(Tonic.c, TonalityMode.major);
    final explanation = ChordCandidateRanking.explain(
      dominant,
      diminished,
      tonality: tonality,
    );

    expect(explanation.result, 1);
    expect(
      explanation.decidedByRule,
      isNot('prefer complete dominant flat-nine over colored diminished7'),
    );
  });

  group('fifthless flat-nine-bass dominant ambiguity', () {
    final dominant = _candidate(
      quality: ChordQualityToken.dominant7,
      root: 'C',
      bass: 'Db',
      presentIntervals: const {0, 1, 4, 10},
      extensions: const {ChordExtension.flat9},
      score: 7.01,
    );

    final minorMajor7 = _candidate(
      quality: ChordQualityToken.minorMajor7,
      root: 'Db',
      bass: 'Db',
      presentIntervals: const {0, 3, 9, 11},
      extensions: const {ChordExtension.add13},
      score: 7.22,
    );

    final diminishedTriad = _candidate(
      quality: ChordQualityToken.diminished,
      root: 'Bb',
      bass: 'Db',
      presentIntervals: const {0, 2, 3, 6},
      extensions: const {ChordExtension.add9},
      score: 7.22,
    );

    test('prefers familiar dominant shell in neutral context', () {
      _expectRule(
        dominant,
        minorMajor7,
        'prefer flat-nine-bass dominant over remote reinterpretation',
      );
      _expectRule(
        dominant,
        diminishedTriad,
        'prefer flat-nine-bass dominant over remote reinterpretation',
      );
    });

    test('preserves bass-rooted minor-major7 on the selected tonic', () {
      const tonality = Tonality(Tonic.cSharp, TonalityMode.minor);
      final explanation = ChordCandidateRanking.explain(
        dominant,
        minorMajor7,
        tonality: tonality,
      );

      expect(explanation.result, 1);
      expect(
        explanation.decidedByRule,
        isNot('prefer flat-nine-bass dominant over remote reinterpretation'),
      );
    });

    test('does not treat the bass-rooted minor-major7 as tonic in major', () {
      const tonality = Tonality(Tonic.cSharp, TonalityMode.major);
      final explanation = ChordCandidateRanking.explain(
        dominant,
        minorMajor7,
        tonality: tonality,
      );

      expect(explanation.result, -1);
      expect(
        explanation.decidedByRule,
        'prefer flat-nine-bass dominant over remote reinterpretation',
      );
    });

    test('does not apply when the dominant fifth is present', () {
      final completeDominant = _candidate(
        quality: ChordQualityToken.dominant7,
        root: 'C',
        bass: 'Db',
        presentIntervals: const {0, 1, 4, 7, 10},
        extensions: const {ChordExtension.flat9},
        score: 7.01,
      );
      final explanation = ChordCandidateRanking.explain(
        completeDominant,
        minorMajor7,
        tonality: defaultTestTonality,
      );

      expect(
        explanation.decidedByRule,
        isNot('prefer flat-nine-bass dominant over remote reinterpretation'),
      );
    });
  });

  test('altered dominant7 beats dim7 slash outside the near-tie window', () {
    final dominant = _candidate(
      quality: ChordQualityToken.dominant7,
      root: 'C',
      bass: 'C',
      presentIntervals: const {0, 1, 4, 10},
      extensions: const {ChordExtension.flat9},
      score: 1,
    );

    final diminishedSlash = _candidate(
      quality: ChordQualityToken.diminished7,
      root: 'Bb',
      bass: 'C',
      presentIntervals: const {0, 2, 3, 6, 9},
      extensions: const {ChordExtension.nine},
      // Intentionally outside the near-tie window in the other direction.
      score: 10,
    );

    _expectRule(
      dominant,
      diminishedSlash,
      'prefer altered dominant7 over dim7 slash',
    );
  });

  test('conventional altered seventh beats non-dominant add11 slash', () {
    final conventional = _candidate(
      quality: ChordQualityToken.minorMajor7,
      root: 'F',
      bass: 'Ab',
      presentIntervals: const {0, 3, 6, 7, 11},
      extensions: const {ChordExtension.sharp11},
      score: 9.6,
    );

    final add11Slash = _candidate(
      quality: ChordQualityToken.major7Sharp5,
      root: 'C',
      bass: 'Ab',
      presentIntervals: const {0, 4, 5, 8, 11},
      extensions: const {ChordExtension.add11},
      score: 10,
    );

    _expectRule(
      conventional,
      add11Slash,
      'prefer conventional altered seventh over add11 slash',
    );
  });

  test('complete minor sharp11 beats altered major7sus4', () {
    final minorSharp11 = _candidate(
      quality: ChordQualityToken.minor,
      root: 'A',
      bass: 'E',
      presentIntervals: const {0, 3, 6, 7},
      extensions: const {ChordExtension.sharp11},
      score: 9.65,
    );

    final alteredSus = _candidate(
      quality: ChordQualityToken.major7sus4,
      root: 'E',
      bass: 'E',
      presentIntervals: const {0, 5, 8, 11},
      extensions: const {ChordExtension.flat13},
      score: 10,
    );

    _expectRule(
      minorSharp11,
      alteredSus,
      'prefer complete minor sharp11 over altered maj7sus4',
    );
  });

  test('root-position dominant7 beats close non-dominant slash', () {
    final dominant = _candidate(
      quality: ChordQualityToken.dominant7,
      root: 'C',
      bass: 'C',
      presentIntervals: const {0, 1, 4, 6, 8, 10},
      extensions: const {
        ChordExtension.flat9,
        ChordExtension.sharp11,
        ChordExtension.flat13,
      },
      score: 9.79,
    );

    final remoteSlash = _candidate(
      quality: ChordQualityToken.minorMajor7,
      root: 'Db',
      bass: 'C',
      presentIntervals: const {0, 3, 7, 11},
      score: 10,
    );

    _expectRule(
      dominant,
      remoteSlash,
      'prefer close root-position dominant7 over non-dominant slash',
    );
  });

  test('root-position altered-fifth dominant beats close slash reading', () {
    final rootPosition = _candidate(
      quality: ChordQualityToken.dominant7Flat5,
      root: 'C',
      bass: 'C',
      presentIntervals: const {0, 3, 4, 6, 10},
      extensions: const {ChordExtension.sharp9},
      score: 9.6,
    );

    final slash = _candidate(
      quality: ChordQualityToken.dominant7Flat5,
      root: 'F#',
      bass: 'C',
      presentIntervals: const {0, 2, 4, 6, 10},
      extensions: const {ChordExtension.nine},
      score: 10,
    );

    _expectRule(
      rootPosition,
      slash,
      'prefer root-position altered-fifth dominant over slash',
    );
  });

  test(
    'root-position extended dominant beats altered-fifth slash near-tie',
    () {
      final rootPosition = _candidate(
        quality: ChordQualityToken.dominant7,
        root: 'C',
        bass: 'C',
        presentIntervals: const {0, 2, 4, 6, 7, 10},
        extensions: const {ChordExtension.nine, ChordExtension.sharp11},
        score: 7.91,
      );

      final slash = _candidate(
        quality: ChordQualityToken.dominant7Sharp5,
        root: 'D',
        bass: 'C',
        presentIntervals: const {0, 2, 4, 5, 8, 10},
        extensions: const {ChordExtension.nine, ChordExtension.eleven},
        score: 8,
      );

      _expectTieRule(
        rootPosition,
        slash,
        'prefer stable extended dominant over altered-fifth slash',
      );
    },
  );

  test('inverted extended dominant beats double-sharp altered-fifth slash', () {
    final inversion = _candidate(
      quality: ChordQualityToken.dominant7,
      root: 'C',
      bass: 'Bb',
      presentIntervals: const {0, 2, 4, 6, 7, 10},
      extensions: const {ChordExtension.nine, ChordExtension.sharp11},
      score: 7.74,
    );

    final slash = _candidate(
      quality: ChordQualityToken.dominant7Sharp5,
      root: 'F#',
      bass: 'Bb',
      presentIntervals: const {0, 1, 4, 6, 8, 10},
      extensions: const {ChordExtension.flat9, ChordExtension.sharp11},
      score: 7.95,
    );

    _expectRule(
      inversion,
      slash,
      'prefer stable extended dominant over double-accidental altered-fifth slash',
    );
  });

  test(
    'complete sharp-nine thirteenth dominant beats colored sixth near-tie',
    () {
      final dominant = _candidate(
        quality: ChordQualityToken.dominant7,
        root: 'Eb',
        bass: 'Db',
        presentIntervals: const {0, 3, 4, 7, 9, 10},
        extensions: const {ChordExtension.sharp9, ChordExtension.thirteen},
        score: 7.74,
      );

      final coloredSixth = _candidate(
        quality: ChordQualityToken.major6,
        root: 'F#',
        bass: 'C#',
        presentIntervals: const {0, 1, 4, 6, 7, 9},
        extensions: const {ChordExtension.flat9, ChordExtension.sharp11},
        score: 7.74,
      );

      _expectTieRule(
        dominant,
        coloredSixth,
        'prefer complete sharp-nine thirteenth dominant over colored sixth',
      );
    },
  );

  test(
    'altered sharp-five dominant beats natural-eleventh sharp-five near-tie',
    () {
      final alteredDominant = _candidate(
        quality: ChordQualityToken.dominant7Sharp5,
        root: 'C',
        bass: 'Ab',
        presentIntervals: const {0, 1, 4, 6, 8, 10},
        extensions: const {ChordExtension.flat9, ChordExtension.sharp11},
        score: 7.95,
      );

      final naturalEleventhSharpFive = _candidate(
        quality: ChordQualityToken.dominant7Sharp5,
        root: 'Ab',
        bass: 'Ab',
        presentIntervals: const {0, 2, 4, 5, 8, 10},
        extensions: const {ChordExtension.nine, ChordExtension.eleven},
        score: 8,
      );

      _expectTieRule(
        alteredDominant,
        naturalEleventhSharpFive,
        'prefer complete altered sharp-five dominant over remote spellings',
      );
    },
  );

  test('root-position dominant sus beats slash reinterpretation near-tie', () {
    final rootPositionSus = _candidate(
      quality: ChordQualityToken.dominant7sus4,
      root: 'D',
      bass: 'D',
      presentIntervals: const {0, 2, 5, 7, 10},
      extensions: const {ChordExtension.nine},
      score: 8.08,
    );

    final alteredSlash = _candidate(
      quality: ChordQualityToken.minor7Sharp5,
      root: 'E',
      bass: 'D',
      presentIntervals: const {0, 3, 5, 8, 10},
      extensions: const {ChordExtension.add11},
      score: 8.25,
    );

    _expectTieRule(
      rootPositionSus,
      alteredSlash,
      'prefer root-position dominant sus over slash',
    );
  });

  test('root-position minor-eleventh shell beats inverted sus readings', () {
    final minor11Shell = _candidate(
      quality: ChordQualityToken.minor7,
      root: 'D',
      bass: 'D',
      presentIntervals: const {0, 3, 5, 10},
      extensions: const {ChordExtension.add11},
      score: 7.22,
    );

    final dominantSusSlash = _candidate(
      quality: ChordQualityToken.dominant7sus4,
      root: 'G',
      bass: 'D',
      presentIntervals: const {0, 5, 7, 10},
      score: 8.37,
    );
    final doubleSusSlash = _candidate(
      quality: ChordQualityToken.sus2sus4,
      root: 'C',
      bass: 'D',
      presentIntervals: const {0, 2, 5, 7},
      score: 8.50,
    );

    for (final susSlash in [dominantSusSlash, doubleSusSlash]) {
      _expectRule(
        minor11Shell,
        susSlash,
        'prefer root-position minor-eleventh shell over sus slash',
      );
    }
  });

  test('complete major six-nine beats inverted minor7 sharp-five', () {
    final majorSixNine = _candidate(
      quality: ChordQualityToken.major6,
      root: 'Eb',
      bass: 'Bb',
      presentIntervals: const {0, 2, 4, 7, 9},
      extensions: const {ChordExtension.add9},
      score: 8.08,
    );
    final alteredMinorSlash = _candidate(
      quality: ChordQualityToken.minor7Sharp5,
      root: 'G',
      bass: 'Bb',
      presentIntervals: const {0, 3, 5, 8, 10},
      extensions: const {ChordExtension.add11},
      score: 8.25,
    );

    _expectTieRule(
      majorSixNine,
      alteredMinorSlash,
      'prefer complete major six-nine over inverted minor-seven sharp-five',
    );
  });

  test('complete lydian major six-nine beats minor11 sharp-five', () {
    final lydianMajorSixNine = _candidate(
      quality: ChordQualityToken.major6,
      root: 'Gb',
      bass: 'Eb',
      presentIntervals: const {0, 2, 4, 6, 7, 9},
      extensions: const {ChordExtension.add9, ChordExtension.sharp11},
      score: 7.79,
    );
    final alteredMinorSlash = _candidate(
      quality: ChordQualityToken.minor7Sharp5,
      root: 'Bb',
      bass: 'Eb',
      presentIntervals: const {0, 2, 3, 5, 8, 10},
      extensions: const {ChordExtension.nine, ChordExtension.eleven},
      score: 7.88,
    );

    _expectTieRule(
      lydianMajorSixNine,
      alteredMinorSlash,
      'prefer complete major six-nine over inverted minor-seven sharp-five',
    );
  });

  test('complete lydian major six-nine beats major13sus4', () {
    final lydianMajorSixNine = _candidate(
      quality: ChordQualityToken.major6,
      root: 'Gb',
      bass: 'Db',
      presentIntervals: const {0, 2, 4, 6, 7, 9},
      extensions: const {ChordExtension.add9, ChordExtension.sharp11},
      score: 7.79,
    );
    final majorThirteenSus = _candidate(
      quality: ChordQualityToken.major7sus4,
      root: 'Db',
      bass: 'Db',
      presentIntervals: const {0, 2, 5, 7, 9, 11},
      extensions: const {ChordExtension.nine, ChordExtension.thirteen},
      score: 7.79,
    );

    _expectTieRule(
      lydianMajorSixNine,
      majorThirteenSus,
      'prefer complete lydian six-nine over major13sus4',
    );
  });

  test('minor7 eleventh-bass slash beats minor7 sharp-five slash', () {
    final minor7Slash = _candidate(
      quality: ChordQualityToken.minor7,
      root: 'A',
      bass: 'D',
      presentIntervals: const {0, 3, 5, 7, 10},
      extensions: const {ChordExtension.add11},
      score: 7.94,
    );

    final alteredSlash = _candidate(
      quality: ChordQualityToken.minor7Sharp5,
      root: 'E',
      bass: 'D',
      presentIntervals: const {0, 3, 5, 8, 10},
      extensions: const {ChordExtension.add11},
      score: 8.25,
    );

    _expectRule(
      minor7Slash,
      alteredSlash,
      'prefer minor7 eleventh-bass slash over minor7 sharp-five slash',
    );
  });

  test('ninth-bass seventh chord beats altered slash outside near-tie', () {
    final ninthBassSeventh = _candidate(
      quality: ChordQualityToken.dominant7,
      root: 'C',
      bass: 'D',
      presentIntervals: const {0, 2, 4, 7, 10},
      extensions: const {ChordExtension.nine},
      score: 7.94,
    );

    final alteredSlash = _candidate(
      quality: ChordQualityToken.minor7Sharp5,
      root: 'E',
      bass: 'D',
      presentIntervals: const {0, 3, 6, 8, 10},
      extensions: const {ChordExtension.sharp11},
      score: 8.20,
    );

    _expectRule(
      ninthBassSeventh,
      alteredSlash,
      'prefer ninth-bass seventh chord over altered slash',
    );
  });

  test('minor-major ninth bass chord beats altered major7 slash', () {
    final ninthBassSeventh = _candidate(
      quality: ChordQualityToken.minorMajor7,
      root: 'C#',
      bass: 'D#',
      presentIntervals: const {0, 2, 3, 7, 11},
      extensions: const {ChordExtension.nine},
      score: 7.94,
    );

    final alteredSlash = _candidate(
      quality: ChordQualityToken.major7Sharp5,
      root: 'E',
      bass: 'D#',
      presentIntervals: const {0, 4, 8, 9, 11},
      extensions: const {ChordExtension.add13},
      score: 8.25,
    );

    _expectRule(
      ninthBassSeventh,
      alteredSlash,
      'prefer ninth-bass seventh chord over altered slash',
    );
  });

  test('ninth-bass seventh chord does not override conventional slash', () {
    final ninthBassSeventh = _candidate(
      quality: ChordQualityToken.minorMajor7,
      root: 'C#',
      bass: 'D#',
      presentIntervals: const {0, 2, 3, 7, 11},
      extensions: const {ChordExtension.nine},
      score: 7.94,
    );

    final conventionalSlash = _candidate(
      quality: ChordQualityToken.minor7,
      root: 'E',
      bass: 'D#',
      presentIntervals: const {0, 3, 7, 10},
      score: 8.25,
    );

    const tonality = Tonality(Tonic.c, TonalityMode.major);
    final explanation = ChordCandidateRanking.explain(
      ninthBassSeventh,
      conventionalSlash,
      tonality: tonality,
    );

    expect(explanation.result, 1);
    expect(
      explanation.decidedByRule,
      'score difference beyond tie-break range',
    );
  });

  test('complete triad beats incomplete inverted 6th in a near-tie', () {
    final completeTriad = _candidate(
      quality: ChordQualityToken.minor,
      root: 'E',
      bass: 'B',
      presentIntervals: const {0, 3, 7},
      score: 7.42,
    );

    final incompleteSixth = _candidate(
      quality: ChordQualityToken.major6,
      root: 'G',
      bass: 'B',
      presentIntervals: const {0, 4, 9},
      score: 7.50,
    );

    _expectTieRule(
      completeTriad,
      incompleteSixth,
      'prefer complete triad over incomplete inverted 6th',
    );
  });

  group('harmonic-minor tonic versus split-third inversion', () {
    final tonicMinorMajor7 = _candidate(
      quality: ChordQualityToken.minorMajor7,
      root: 'C#',
      bass: 'C#',
      presentIntervals: const {0, 3, 8, 11},
      extensions: const {ChordExtension.flat13},
      score: 7.16,
    );
    final splitThirdInversion = _candidate(
      quality: ChordQualityToken.major,
      root: 'A',
      bass: 'C#',
      presentIntervals: const {0, 3, 4, 7},
      extensions: const {ChordExtension.addSharp9},
      score: 7.07,
    );

    test('minor-key context prefers the harmonic-minor tonic', () {
      const tonality = Tonality(Tonic.cSharp, TonalityMode.minor);
      final explanation = ChordCandidateRanking.explain(
        tonicMinorMajor7,
        splitThirdInversion,
        tonality: tonality,
      );

      expect(explanation.result, -1);
      expect(
        explanation.decidedByRule,
        'prefer harmonic-minor tonic over split-third inversion',
      );
    });

    test('neutral major context preserves the split-third inversion', () {
      final explanation = ChordCandidateRanking.explain(
        splitThirdInversion,
        tonicMinorMajor7,
        tonality: defaultTestTonality,
      );

      expect(explanation.result, -1);
      expect(explanation.decidedByRule, 'prefer fewer altered/tension colors');
    });

    test('does not prefer a non-tonic minor-major7', () {
      const tonality = Tonality(Tonic.fSharp, TonalityMode.minor);
      final explanation = ChordCandidateRanking.explain(
        splitThirdInversion,
        tonicMinorMajor7,
        tonality: tonality,
      );

      expect(explanation.result, -1);
      expect(
        explanation.decidedByRule,
        isNot('prefer harmonic-minor tonic over split-third inversion'),
      );
    });
  });

  test('root-position add-chord beats sus-family slash outside near-tie', () {
    // {C, E, G, F}: musicians hear Cadd11, not Fmaj7sus2/C.
    // The sus reading earns a higher raw score (clean template fit with 3
    // required tones) but is a remote, convoluted name for a simple voicing.
    final addChord = _candidate(
      quality: ChordQualityToken.major,
      root: 'C',
      bass: 'C',
      presentIntervals: const {0, 4, 5, 7},
      extensions: const {ChordExtension.add11},
      score: 7.07,
    );

    final susSlash = _candidate(
      quality: ChordQualityToken.major7sus2,
      root: 'F',
      bass: 'C',
      presentIntervals: const {0, 2, 7, 11},
      score: 8.37,
    );

    _expectRule(
      addChord,
      susSlash,
      'prefer root-position add-chord over sus slash',
    );
  });

  test('common naming prior can resolve modest score gap before inversion', () {
    final conventionalAlteredDominant = _candidate(
      quality: ChordQualityToken.dominant7Sharp5,
      root: 'G',
      bass: 'A',
      presentIntervals: const {0, 2, 4, 8, 10},
      extensions: const {ChordExtension.nine},
      score: 8.125,
    );

    final rarerInversion = _candidate(
      quality: ChordQualityToken.dominant7Flat5,
      root: 'F',
      bass: 'A',
      presentIntervals: const {0, 2, 4, 6, 10},
      extensions: const {ChordExtension.nine},
      score: 8.25,
    );

    _expectTieRule(
      conventionalAlteredDominant,
      rarerInversion,
      'prefer common naming preference',
    );
  });

  test('complete major inversion beats minor sharp-five in a near-tie', () {
    for (final bass in ['C', 'Eb']) {
      final majorInversion = _candidate(
        quality: ChordQualityToken.major,
        root: 'Ab',
        bass: bass,
        presentIntervals: const {0, 4, 7},
        score: 7.42,
      );

      final minorSharpFive = _candidate(
        quality: ChordQualityToken.minorSharp5,
        root: 'C',
        bass: bass,
        presentIntervals: const {0, 3, 8},
        score: 7.51,
      );

      _expectTieRule(
        majorInversion,
        minorSharpFive,
        'prefer complete major inversion over minor sharp-five',
      );
    }
  });

  test('common naming preference breaks complete sixth and minor7 tie', () {
    final minor7 = _candidate(
      quality: ChordQualityToken.minor7,
      root: 'D',
      bass: 'A',
      presentIntervals: const {0, 3, 7, 10},
      score: 8.37,
    );

    final major6 = _candidate(
      quality: ChordQualityToken.major6,
      root: 'F',
      bass: 'A',
      presentIntervals: const {0, 4, 7, 9},
      score: 8.37,
    );

    _expectTieRule(minor7, major6, 'prefer common naming preference');
  });

  test('root-position major6 sharp11 beats inverted minor7 add13', () {
    // These enharmonic readings tie on score; natural-extension preference
    // settles it toward the major6 (its #11 is natural; the minor7's add13 is
    // an add tone).
    final major6Sharp11 = _candidate(
      quality: ChordQualityToken.major6,
      root: 'Eb',
      bass: 'Eb',
      presentIntervals: const {0, 4, 6, 7, 9},
      extensions: const {ChordExtension.sharp11},
      score: 8.08,
    );
    final minor7Add13 = _candidate(
      quality: ChordQualityToken.minor7,
      root: 'C',
      bass: 'Eb',
      presentIntervals: const {0, 3, 7, 9, 10},
      extensions: const {ChordExtension.add13},
      score: 8.08,
    );

    _expectTieRule(
      major6Sharp11,
      minor7Add13,
      'prefer natural extensions over adds, then fewer total',
    );
  });

  group('root-position relative minor7 versus major6 slash', () {
    final minor7 = _candidate(
      quality: ChordQualityToken.minor7,
      root: 'A',
      bass: 'A',
      presentIntervals: const {0, 3, 7, 10},
      score: 8.37,
    );
    final major6Slash = _candidate(
      quality: ChordQualityToken.major6,
      root: 'C',
      bass: 'A',
      presentIntervals: const {0, 4, 7, 9},
      score: 8.37,
    );

    test('prefers the bass-rooted minor7 despite major-key tonic context', () {
      final explanation = ChordCandidateRanking.explain(
        minor7,
        major6Slash,
        tonality: defaultTestTonality,
      );

      expect(explanation.result, -1);
      expect(
        explanation.decidedByRule,
        'prefer root-position relative minor7 over major6 slash',
      );
    });

    test('extends to matching add11 and add9 color', () {
      final coloredMinor7 = _candidate(
        quality: ChordQualityToken.minor7,
        root: 'A',
        bass: 'A',
        presentIntervals: const {0, 3, 5, 7, 10},
        extensions: const {ChordExtension.add11},
        score: 8.08,
      );
      final coloredMajor6Slash = _candidate(
        quality: ChordQualityToken.major6,
        root: 'C',
        bass: 'A',
        presentIntervals: const {0, 2, 4, 7, 9},
        extensions: const {ChordExtension.add9},
        score: 8.08,
      );

      final explanation = ChordCandidateRanking.explain(
        coloredMinor7,
        coloredMajor6Slash,
        tonality: defaultTestTonality,
      );

      expect(explanation.result, -1);
      expect(
        explanation.decidedByRule,
        'prefer root-position relative minor7 over major6 slash',
      );
    });

    test('does not override a root-position major6', () {
      final rootMajor6 = _candidate(
        quality: ChordQualityToken.major6,
        root: 'C',
        bass: 'C',
        presentIntervals: const {0, 4, 7, 9},
        score: 8.37,
      );
      final minor7Slash = _candidate(
        quality: ChordQualityToken.minor7,
        root: 'A',
        bass: 'C',
        presentIntervals: const {0, 3, 7, 10},
        score: 8.37,
      );
      final explanation = ChordCandidateRanking.explain(
        rootMajor6,
        minor7Slash,
        tonality: defaultTestTonality,
      );

      expect(explanation.result, -1);
      expect(
        explanation.decidedByRule,
        'prefer root-position 6th over inverted 7th',
      );
    });
  });

  test(
    'dominant7 shell slash with color bass beats major7 family slash in near-tie',
    () {
      // F7(#9,b13)/G# vs C#maj9b13/G#: same six notes, same bass.
      // F7 has shell (A=major3 + Eb=flat7) and color bass (G#=sharp9 of F).
      // C# has a higher raw score but the F dominant reading is what musicians
      // expect for this voicing.
      final dom7Slash = _candidate(
        quality: ChordQualityToken.dominant7,
        root: 'F',
        bass: 'G#',
        // intervals: root=0, sharp9=3, major3=4, perfect5=7, flat13=8, flat7=10
        presentIntervals: const {0, 3, 4, 7, 8, 10},
        extensions: const {ChordExtension.sharp9, ChordExtension.flat13},
        score: 7.59,
      );

      final maj7Slash = _candidate(
        quality: ChordQualityToken.major7,
        root: 'C#',
        bass: 'G#',
        // intervals: root=0, nine=2, major3=4, perfect5=7, flat13=8, major7=11
        presentIntervals: const {0, 2, 4, 7, 8, 11},
        extensions: const {ChordExtension.nine, ChordExtension.flat13},
        score: 7.74,
      );

      _expectTieRule(
        dom7Slash,
        maj7Slash,
        'prefer dominant7 shell slash over non-dominant seventh-family slash',
      );
    },
  );

  group('rank linearizes a non-transitive relation', () {
    const tonality = Tonality(Tonic.c, TonalityMode.major);

    // A beats B via a hard rule (altered dominant7 over dim7 slash) despite B
    // scoring higher; B beats C and C beats A on score alone (gaps exceed the
    // near-tie window). That is a cycle: A > B > C > A.
    final a = _candidate(
      quality: ChordQualityToken.dominant7,
      root: 'C',
      bass: 'C',
      presentIntervals: const {0, 1, 4, 10},
      extensions: const {ChordExtension.flat9},
      score: 1,
    );
    final b = _candidate(
      quality: ChordQualityToken.diminished7,
      root: 'Bb',
      bass: 'C',
      presentIntervals: const {0, 2, 3, 6, 9},
      extensions: const {ChordExtension.nine},
      score: 10,
    );
    final c = _candidate(
      quality: ChordQualityToken.major,
      root: 'E',
      bass: 'E',
      presentIntervals: const {0, 4, 7},
      score: 5,
    );

    int cmp(ChordCandidate x, ChordCandidate y) =>
        ChordCandidateRanking.compare(x, y, tonality: tonality);

    test('the candidate set really is a cycle (test precondition)', () {
      expect(cmp(a, b), lessThan(0)); // A beats B (hard rule)
      expect(cmp(b, c), lessThan(0)); // B beats C (score)
      expect(cmp(c, a), lessThan(0)); // C beats A (score) -> cycle
    });

    test('rank is independent of input order', () {
      List<String> ranked(List<ChordCandidate> input) =>
          ChordCandidateRanking.rank(
            input,
            (x) => x,
            tonality: tonality,
          ).map((x) => x.identity.quality.name).toList();

      final reference = ranked([a, b, c]);
      expect(ranked([c, b, a]), reference);
      expect(ranked([b, a, c]), reference);
      expect(ranked([b, c, a]), reference);
      expect(ranked([c, a, b]), reference);
      expect(ranked([a, c, b]), reference);
    });

    test(
      'the hard-rule winner is never placed below the candidate it overrode',
      () {
        final ranked = ChordCandidateRanking.rank(
          [b, c, a],
          (x) => x,
          tonality: tonality,
        );
        expect(ranked.indexOf(a), lessThan(ranked.indexOf(b)));
      },
    );
  });

  group('near-tie selection', () {
    test('isNearTie window is one-sided around the chosen #1 score', () {
      const best = 7.0;
      expect(ChordCandidateRanking.isNearTie(best, 6.85), isTrue); // within
      expect(ChordCandidateRanking.isNearTie(best, 6.81), isTrue); // within
      expect(ChordCandidateRanking.isNearTie(best, 6.79), isFalse); // outside
      // A reading scoring higher than the chosen #1 is still a near-tie; the
      // window must not clamp the difference to its absolute value.
      expect(ChordCandidateRanking.isNearTie(best, 7.30), isTrue);
    });

    ChordCandidate plain(String root, double score) => _candidate(
      quality: ChordQualityToken.major,
      root: root,
      bass: root,
      presentIntervals: const {0, 4, 7},
      score: score,
    );

    test('keeps a higher-scoring alternative and filters past a gap', () {
      // #1 was promoted below a higher-scoring reading (D, 7.30). A later
      // candidate (F, 6.90) is within the window even though the one before it
      // (E, 6.50) is not, so a break-on-first-miss would wrongly drop it.
      final ranked = [
        plain('C', 7.00),
        plain('D', 7.30),
        plain('E', 6.50),
        plain('F', 6.90),
      ];

      final alternatives = ChordCandidateRanking.nearTieAlternatives(ranked);

      expect(alternatives.map((c) => c.identity.rootPc), [pc('D'), pc('F')]);
    });

    test('returns empty when there are fewer than two candidates', () {
      expect(
        ChordCandidateRanking.nearTieAlternatives([plain('C', 7.0)]),
        isEmpty,
      );
      expect(ChordCandidateRanking.nearTieAlternatives(const []), isEmpty);
    });
  });
}

void _expectRule(
  ChordCandidate preferred,
  ChordCandidate other,
  String ruleName,
) {
  const tonality = Tonality(Tonic.c, TonalityMode.major);

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
  const tonality = Tonality(Tonic.c, TonalityMode.major);

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

ChordCandidate _candidate({
  required ChordQualityToken quality,
  required String root,
  required String bass,
  required Set<int> presentIntervals,
  required double score,
  Set<ChordExtension> extensions = const {},
}) {
  return ChordCandidate(
    identity: _identity(
      quality: quality,
      rootPc: pc(root),
      bassPc: pc(bass),
      presentIntervals: presentIntervals,
      extensions: extensions,
    ),
    score: score,
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
