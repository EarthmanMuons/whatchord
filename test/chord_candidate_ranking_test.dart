import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/theory/domain/analysis/candidate_features.dart';
import 'package:whatchord/features/theory/domain/theory_domain.dart';

import 'helpers/theory_test_helpers.dart';

void main() {
  test('sharp-nine bass is not treated as a stable inversion', () {
    final candidate = _candidate(
      quality: ChordQualityToken.dominant7,
      root: 'C',
      bass: 'Eb',
      presentIntervals: const {0, 3, 4, 7, 10},
      extensions: const {ChordExtension.sharp9},
      cost: 1,
    );

    final features = CandidateFeatures.from(candidate);

    expect(features.bassIsColorTone, isTrue);
    expect(features.hasStableBassRole, isFalse);
  });

  test('generic seventh preference requires a sounding seventh', () {
    final missingSeventh = _candidate(
      quality: ChordQualityToken.dominant7,
      root: 'C',
      bass: 'C',
      presentIntervals: const {0, 4, 7},
      cost: 1,
    );

    final triad = _candidate(
      quality: ChordQualityToken.major,
      root: 'C',
      bass: 'C',
      presentIntervals: const {0, 4, 7},
      cost: 1,
    );

    final explanation = ChordCandidateRanking.explain(
      missingSeventh,
      triad,
      tonality: defaultTestTonality,
    );

    expect(explanation.decidedByRule, isNot('prefer 7th chords over triads'));
  });

  test('complete dominant sharp-nine beats sixth flat-nine', () {
    final dominant = _candidate(
      quality: ChordQualityToken.dominant7,
      root: 'C',
      bass: 'Eb',
      presentIntervals: const {0, 3, 4, 7, 10},
      extensions: const {ChordExtension.sharp9},
      cost: 3.12,
    );

    final sixthFlat9 = _candidate(
      quality: ChordQualityToken.major6,
      root: 'Eb',
      bass: 'Eb',
      presentIntervals: const {0, 1, 4, 7, 9},
      extensions: const {ChordExtension.flat9},
      cost: 2.97,
    );

    _expectTieRule(
      dominant,
      sixthFlat9,
      'prefer complete dominant sharp-nine over non-seventh color',
    );
  });

  test('complete sharp-nine sharp-eleven dominant beats split-third sixth', () {
    final dominant = _candidate(
      quality: ChordQualityToken.dominant7,
      root: 'A',
      bass: 'C',
      presentIntervals: const {0, 3, 4, 6, 7, 10},
      extensions: const {ChordExtension.sharp9, ChordExtension.sharp11},
      cost: 3.41,
    );

    final splitThirdSixth = _candidate(
      quality: ChordQualityToken.major6,
      root: 'C',
      bass: 'C',
      presentIntervals: const {0, 1, 3, 4, 7, 9},
      extensions: const {ChordExtension.flat9, ChordExtension.addSharp9},
      cost: 3.26,
    );

    _expectTieRule(
      dominant,
      splitThirdSixth,
      'prefer complete dominant sharp-nine over non-seventh color',
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
        cost: 3.7,
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
        cost: 3.55,
      );

      _expectTieRule(
        dominant,
        splitThirdSixth,
        'prefer complete dominant sharp-nine over non-seventh color',
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
        cost: 3.55,
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
        cost: 3.55,
      );

      _expectTieRule(
        dominant,
        splitThirdSixth,
        'prefer complete dominant sharp-nine over non-seventh color',
      );
    },
  );

  test('complete sharp-five sharp-nine dominant beats sus flat-nine color', () {
    final dominant = _candidate(
      quality: ChordQualityToken.dominant7Sharp5,
      root: 'A',
      bass: 'C',
      presentIntervals: const {0, 3, 4, 8, 10},
      extensions: const {ChordExtension.sharp9},
      cost: 1.40,
    );

    final susColor = _candidate(
      quality: ChordQualityToken.sus4,
      root: 'C',
      bass: 'C',
      presentIntervals: const {0, 1, 5, 7, 9},
      extensions: const {ChordExtension.addFlat9, ChordExtension.add13},
      cost: 1.50,
    );

    _expectTieRule(
      dominant,
      susColor,
      'prefer complete dominant sharp-nine over non-seventh color',
    );
  });

  test(
    'complete flat-nine flat-thirteen dominant beats remote seventh spelling',
    () {
      final dominant = _candidate(
        quality: ChordQualityToken.dominant7,
        root: 'F',
        bass: 'Eb',
        presentIntervals: const {0, 1, 4, 7, 8, 10},
        extensions: const {ChordExtension.flat9, ChordExtension.flat13},
        cost: 2.86,
      );

      final remoteMinor = _candidate(
        quality: ChordQualityToken.halfDiminished7,
        root: 'D#',
        bass: 'D#',
        presentIntervals: const {0, 2, 3, 6, 9, 10},
        extensions: const {ChordExtension.nine, ChordExtension.thirteen},
        cost: 3.0,
      );

      _expectTieRule(
        dominant,
        remoteMinor,
        'prefer complete flat-nine flat-thirteen dominant over remote spelling',
      );
    },
  );

  test('split-nine tritone dominants follow the conventional bass role', () {
    ChordCandidate splitNine({required String bass, required double cost}) =>
        _candidate(
          quality: ChordQualityToken.dominant7Flat5,
          root: 'C',
          bass: bass,
          presentIntervals: const {0, 1, 2, 4, 6, 10},
          extensions: const {ChordExtension.flat9, ChordExtension.nine},
          cost: cost,
        );
    ChordCandidate tritoneColor({required String bass, required double cost}) =>
        _candidate(
          quality: ChordQualityToken.dominant7,
          root: 'F#',
          bass: bass,
          presentIntervals: const {0, 4, 6, 7, 8, 10},
          extensions: const {ChordExtension.sharp11, ChordExtension.flat13},
          cost: cost,
        );

    for (final bass in ['Bb', 'F#', 'Db']) {
      _expectRule(
        tritoneColor(bass: bass, cost: 3.32),
        splitNine(bass: bass, cost: 3.05),
        'prefer conventional inversion in split-nine tritone dominant ambiguity',
      );
    }
    for (final bass in ['C', 'E']) {
      _expectRule(
        splitNine(bass: bass, cost: 3.05),
        tritoneColor(bass: bass, cost: 3.32),
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
      cost: 3.05,
    );

    final diminished = _candidate(
      quality: ChordQualityToken.diminished7,
      root: 'G',
      bass: 'G',
      presentIntervals: const {0, 3, 5, 6, 9},
      extensions: const {ChordExtension.add11},
      cost: 2.75,
    );

    _expectRule(
      dominant,
      diminished,
      'prefer dominant flat-nine shell over colored diminished',
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
        cost: 3.17,
      );

      final diminished = _candidate(
        quality: ChordQualityToken.diminished7,
        root: 'A#',
        bass: 'Db',
        presentIntervals: const {0, 2, 3, 6, 8},
        extensions: const {ChordExtension.nine, ChordExtension.flat13},
        cost: 2.9,
      );

      _expectRule(
        dominant,
        diminished,
        'prefer dominant flat-nine shell over colored diminished',
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
      cost: 3.05,
    );

    final diminished = _candidate(
      quality: ChordQualityToken.diminished7,
      root: 'Bb',
      bass: 'Bb',
      presentIntervals: const {0, 2, 3, 6, 9},
      extensions: const {ChordExtension.nine},
      cost: 2.75,
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
      isNot('prefer dominant flat-nine shell over colored diminished'),
    );
  });

  test('complete dominant flat-nine beats diminished add-nine', () {
    final dominant = _candidate(
      quality: ChordQualityToken.dominant7,
      root: 'C',
      bass: 'E',
      presentIntervals: const {0, 1, 4, 10},
      extensions: const {ChordExtension.flat9},
      cost: 3.84,
    );

    final diminished = _candidate(
      quality: ChordQualityToken.diminished,
      root: 'A#',
      bass: 'E',
      presentIntervals: const {0, 2, 3, 6},
      extensions: const {ChordExtension.add9},
      cost: 3.78,
    );

    _expectTieRule(
      dominant,
      diminished,
      'prefer dominant flat-nine shell over colored diminished',
    );
  });

  group('fifthless flat-nine-bass dominant ambiguity', () {
    final dominant = _candidate(
      quality: ChordQualityToken.dominant7,
      root: 'C',
      bass: 'Db',
      presentIntervals: const {0, 1, 4, 10},
      extensions: const {ChordExtension.flat9},
      cost: 4.08,
    );

    final minorMajor7 = _candidate(
      quality: ChordQualityToken.minorMajor7,
      root: 'Db',
      bass: 'Db',
      presentIntervals: const {0, 3, 9, 11},
      extensions: const {ChordExtension.add13},
      cost: 3.78,
    );

    final diminishedTriad = _candidate(
      quality: ChordQualityToken.diminished,
      root: 'Bb',
      bass: 'Db',
      presentIntervals: const {0, 2, 3, 6},
      extensions: const {ChordExtension.add9},
      cost: 3.78,
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

    test(
      'also applies when the dominant has split flat and natural ninths',
      () {
        final splitNinthDominant = _candidate(
          quality: ChordQualityToken.dominant7,
          root: 'C',
          bass: 'Db',
          presentIntervals: const {0, 1, 2, 4, 10},
          extensions: const {ChordExtension.flat9, ChordExtension.nine},
          cost: 1.70,
        );
        final splitNinthMinorMajor = _candidate(
          quality: ChordQualityToken.minorMajor7,
          root: 'Db',
          bass: 'Db',
          presentIntervals: const {0, 1, 3, 9, 11},
          extensions: const {ChordExtension.flat9, ChordExtension.thirteen},
          cost: 1.78,
        );

        _expectTieRule(
          splitNinthDominant,
          splitNinthMinorMajor,
          'prefer flat-nine-bass dominant over remote reinterpretation',
        );
      },
    );

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
        cost: 3.99,
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
      cost: 2.0,
    );

    final diminishedSlash = _candidate(
      quality: ChordQualityToken.diminished7,
      root: 'Bb',
      bass: 'C',
      presentIntervals: const {0, 2, 3, 6, 9},
      extensions: const {ChordExtension.nine},
      // Outside the near-tie window, but only by a realistic margin (gap 1.0).
      // Hard rules override cost within their measured reach (~1.6 across
      // the corpus), not by arbitrary amounts; asserting an extreme gap (e.g. 9)
      // would encode an unbounded-override contract we do not want, since it
      // conflicts with cost-bounded candidate pruning.
      cost: 1.0,
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
      cost: 1.4,
    );

    final add11Slash = _candidate(
      quality: ChordQualityToken.major7Sharp5,
      root: 'C',
      bass: 'Ab',
      presentIntervals: const {0, 4, 5, 8, 11},
      extensions: const {ChordExtension.add11},
      cost: 1.0,
    );

    _expectRule(
      conventional,
      add11Slash,
      'prefer conventional altered seventh over add11 slash',
    );
  });

  test(
    'natural dominant color does not trigger altered seventh add11 rule',
    () {
      final naturalDominant = _candidate(
        quality: ChordQualityToken.dominant7,
        root: 'Eb',
        bass: 'Db',
        presentIntervals: const {0, 4, 5, 9, 10},
        extensions: const {ChordExtension.eleven, ChordExtension.thirteen},
        cost: 1.65,
      );

      final add11Slash = _candidate(
        quality: ChordQualityToken.major7,
        root: 'Ab',
        bass: 'Db',
        presentIntervals: const {0, 4, 5, 7, 11},
        extensions: const {ChordExtension.eleven},
        cost: 1.10,
      );

      final explanation = ChordCandidateRanking.explain(
        add11Slash,
        naturalDominant,
        tonality: defaultTestTonality,
      );

      expect(explanation.result, -1);
      expect(
        explanation.decidedByRule,
        isNot('prefer conventional altered seventh over add11 slash'),
      );
    },
  );

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
      cost: 1.3,
    );

    final remoteSlash = _candidate(
      quality: ChordQualityToken.minorMajor7,
      root: 'Db',
      bass: 'C',
      presentIntervals: const {0, 3, 7, 11},
      cost: 1.0,
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
      cost: 1.3,
    );

    final slash = _candidate(
      quality: ChordQualityToken.dominant7Flat5,
      root: 'F#',
      bass: 'C',
      presentIntervals: const {0, 2, 4, 6, 10},
      extensions: const {ChordExtension.nine},
      cost: 1.0,
    );

    _expectRule(
      rootPosition,
      slash,
      'prefer root-position altered-fifth dominant over slash',
    );
  });

  test(
    'ninth altered-fifth slash can beat whole-tone root-position spelling',
    () {
      final ninthSlash = _candidate(
        quality: ChordQualityToken.dominant7Sharp5,
        root: 'E',
        bass: 'G#',
        presentIntervals: const {0, 2, 4, 8, 10},
        extensions: const {ChordExtension.nine},
        cost: 2.75,
      );

      final rootPosition = _candidate(
        quality: ChordQualityToken.dominant7Sharp5,
        root: 'G#',
        bass: 'G#',
        presentIntervals: const {0, 4, 6, 8, 10},
        extensions: const {ChordExtension.sharp11},
        cost: 2.8,
      );

      _expectTieRule(
        ninthSlash,
        rootPosition,
        'prefer fewer altered/tension colors',
      );
    },
  );

  test(
    'lower-cost major-seventh-bass inversion beats remote color-bass slash',
    () {
      final conventionalInversion = _candidate(
        quality: ChordQualityToken.major7,
        root: 'Ab',
        bass: 'G',
        presentIntervals: const {0, 4, 5, 7, 8, 11},
        extensions: const {ChordExtension.eleven, ChordExtension.flat13},
        cost: 3.26,
      );

      final colorBassSlash = _candidate(
        quality: ChordQualityToken.minorMajor7,
        root: 'Db',
        bass: 'G',
        presentIntervals: const {0, 2, 3, 6, 7, 11},
        extensions: const {ChordExtension.nine, ChordExtension.sharp11},
        cost: 3.41,
      );

      _expectTieRule(
        conventionalInversion,
        colorBassSlash,
        'prefer lower-cost major-seventh-bass inversion over color-bass slash',
      );
    },
  );

  test(
    'root-position extended dominant beats altered-fifth slash near-tie',
    () {
      final rootPosition = _candidate(
        quality: ChordQualityToken.dominant7,
        root: 'C',
        bass: 'C',
        presentIntervals: const {0, 2, 4, 6, 7, 10},
        extensions: const {ChordExtension.nine, ChordExtension.sharp11},
        cost: 3.09,
      );

      final slash = _candidate(
        quality: ChordQualityToken.dominant7Sharp5,
        root: 'D',
        bass: 'C',
        presentIntervals: const {0, 2, 4, 5, 8, 10},
        extensions: const {ChordExtension.nine, ChordExtension.eleven},
        cost: 3.0,
      );

      _expectTieRule(
        rootPosition,
        slash,
        'prefer stable extended dominant over altered-fifth slash',
      );
    },
  );

  test(
    'complete altered thirteenth dominant beats altered minor thirteenth near-tie',
    () {
      final dominant = _candidate(
        quality: ChordQualityToken.dominant7,
        root: 'A',
        bass: 'F#',
        presentIntervals: const {0, 3, 4, 6, 7, 9, 10},
        extensions: const {
          ChordExtension.sharp9,
          ChordExtension.sharp11,
          ChordExtension.thirteen,
        },
        cost: 3.7,
      );

      final minor = _candidate(
        quality: ChordQualityToken.minor7,
        root: 'F#',
        bass: 'F#',
        presentIntervals: const {0, 1, 3, 6, 7, 9, 10},
        extensions: const {
          ChordExtension.flat9,
          ChordExtension.sharp11,
          ChordExtension.thirteen,
        },
        cost: 3.55,
      );

      _expectTieRule(
        dominant,
        minor,
        'prefer complete altered thirteenth dominant over altered minor thirteenth',
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
        cost: 3.05,
      );

      final naturalEleventhSharpFive = _candidate(
        quality: ChordQualityToken.dominant7Sharp5,
        root: 'Ab',
        bass: 'Ab',
        presentIntervals: const {0, 2, 4, 5, 8, 10},
        extensions: const {ChordExtension.nine, ChordExtension.eleven},
        cost: 3.0,
      );

      _expectTieRule(
        alteredDominant,
        naturalEleventhSharpFive,
        'prefer complete altered sharp-five dominant over remote spellings',
      );
    },
  );

  test('flat-nine sharp-five dominant beats remote minor-major thirteenth', () {
    final alteredDominant = _candidate(
      quality: ChordQualityToken.dominant7Sharp5,
      root: 'C',
      bass: 'C',
      presentIntervals: const {0, 1, 4, 8, 10},
      extensions: const {ChordExtension.flat9},
      cost: 2.8,
    );

    final remoteMinorMajor = _candidate(
      quality: ChordQualityToken.minorMajor7,
      root: 'C#',
      bass: 'C',
      presentIntervals: const {0, 3, 7, 9, 11},
      extensions: const {ChordExtension.thirteen},
      cost: 2.92,
    );

    _expectTieRule(
      alteredDominant,
      remoteMinorMajor,
      'prefer complete altered sharp-five dominant over remote spellings',
    );
  });

  test('root-position dominant sus beats slash reinterpretation near-tie', () {
    final rootPositionSus = _candidate(
      quality: ChordQualityToken.dominant7sus4,
      root: 'D',
      bass: 'D',
      presentIntervals: const {0, 2, 5, 7, 10},
      extensions: const {ChordExtension.nine},
      cost: 2.92,
    );

    final alteredSlash = _candidate(
      quality: ChordQualityToken.minor7Sharp5,
      root: 'E',
      bass: 'D',
      presentIntervals: const {0, 3, 5, 8, 10},
      extensions: const {ChordExtension.add11},
      cost: 2.75,
    );

    _expectTieRule(
      rootPositionSus,
      alteredSlash,
      'prefer root-position dominant sus over slash',
    );
  });

  test('major-seventh upper-structure slash beats dominant sus label', () {
    final upperStructureSlash = _candidate(
      quality: ChordQualityToken.major7,
      root: 'Db',
      bass: 'Eb',
      presentIntervals: const {0, 2, 4, 7, 11},
      extensions: const {ChordExtension.nine},
      cost: 0.65,
    );

    final rootPositionSus = _candidate(
      quality: ChordQualityToken.dominant7sus4,
      root: 'Eb',
      bass: 'Eb',
      presentIntervals: const {0, 2, 5, 9, 10},
      extensions: const {ChordExtension.nine, ChordExtension.thirteen},
      cost: 0.75,
    );

    _expectTieRule(
      upperStructureSlash,
      rootPositionSus,
      'prefer major-seventh upper-structure sus slash',
    );
  });

  test('root-position minor-eleventh shell beats inverted sus readings', () {
    final minor11Shell = _candidate(
      quality: ChordQualityToken.minor7,
      root: 'D',
      bass: 'D',
      presentIntervals: const {0, 3, 5, 10},
      extensions: const {ChordExtension.add11},
      cost: 3.78,
    );

    final dominantSusSlash = _candidate(
      quality: ChordQualityToken.dominant7sus4,
      root: 'G',
      bass: 'D',
      presentIntervals: const {0, 5, 7, 10},
      cost: 2.63,
    );
    final doubleSusSlash = _candidate(
      quality: ChordQualityToken.sus2sus4,
      root: 'C',
      bass: 'D',
      presentIntervals: const {0, 2, 5, 7},
      cost: 2.5,
    );

    for (final susSlash in [dominantSusSlash, doubleSusSlash]) {
      _expectRule(
        minor11Shell,
        susSlash,
        'prefer root-position minor-eleventh shell over sus slash',
      );
    }
  });

  test('ninth-bass seventh chord beats altered slash outside near-tie', () {
    final ninthBassSeventh = _candidate(
      quality: ChordQualityToken.dominant7,
      root: 'C',
      bass: 'D',
      presentIntervals: const {0, 2, 4, 7, 10},
      extensions: const {ChordExtension.nine},
      cost: 3.06,
    );

    final alteredSlash = _candidate(
      quality: ChordQualityToken.minor7Sharp5,
      root: 'E',
      bass: 'D',
      presentIntervals: const {0, 3, 6, 8, 10},
      extensions: const {ChordExtension.sharp11},
      cost: 2.8,
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
      cost: 3.06,
    );

    final alteredSlash = _candidate(
      quality: ChordQualityToken.major7Sharp5,
      root: 'E',
      bass: 'D#',
      presentIntervals: const {0, 4, 8, 9, 11},
      extensions: const {ChordExtension.add13},
      cost: 2.75,
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
      cost: 3.06,
    );

    final conventionalSlash = _candidate(
      quality: ChordQualityToken.minor7,
      root: 'E',
      bass: 'D#',
      presentIntervals: const {0, 3, 7, 10},
      cost: 2.75,
    );

    const tonality = Tonality(Tonic.c, TonalityMode.major);
    final explanation = ChordCandidateRanking.explain(
      ninthBassSeventh,
      conventionalSlash,
      tonality: tonality,
    );

    expect(explanation.result, 1);
    expect(explanation.decidedByRule, 'cost difference beyond tie-break range');
  });

  test('complete triad beats incomplete 6th in a near-tie', () {
    final completeTriad = _candidate(
      quality: ChordQualityToken.minor,
      root: 'E',
      bass: 'B',
      presentIntervals: const {0, 3, 7},
      cost: 3.58,
    );

    final incompleteSixth = _candidate(
      quality: ChordQualityToken.major6,
      root: 'G',
      bass: 'B',
      presentIntervals: const {0, 4, 9},
      cost: 3.5,
    );

    _expectTieRule(
      completeTriad,
      incompleteSixth,
      'prefer complete triad over incomplete 6th',
    );
  });

  test('complete diminished triad beats root-position fifthless minor 6th', () {
    final diminishedTriad = _candidate(
      quality: ChordQualityToken.diminished,
      root: 'C',
      bass: 'Eb',
      presentIntervals: const {0, 3, 6},
      cost: 0.25,
    );

    final fifthlessMinorSixth = _candidate(
      quality: ChordQualityToken.minor6,
      root: 'Eb',
      bass: 'Eb',
      presentIntervals: const {0, 3, 9},
      cost: 0.45,
    );

    _expectTieRule(
      diminishedTriad,
      fifthlessMinorSixth,
      'prefer complete triad over incomplete 6th',
    );
  });

  test('complete triad rule preserves root-position six-nine color', () {
    final rootSixNine = _candidate(
      quality: ChordQualityToken.major6,
      root: 'C',
      bass: 'C',
      presentIntervals: const {0, 2, 4, 9},
      extensions: const {ChordExtension.add9},
      cost: 0.4,
    );

    final completeTriad = _candidate(
      quality: ChordQualityToken.minor,
      root: 'A',
      bass: 'C',
      presentIntervals: const {0, 3, 5, 7},
      extensions: const {ChordExtension.add11},
      cost: 0.45,
    );

    final explanation = ChordCandidateRanking.explain(
      rootSixNine,
      completeTriad,
      tonality: defaultTestTonality,
    );

    expect(explanation.result, -1);
    expect(
      explanation.decidedByRule,
      isNot('prefer complete triad over incomplete 6th'),
    );
  });

  group('harmonic-minor tonic versus split-third inversion', () {
    final tonicMinorMajor7 = _candidate(
      quality: ChordQualityToken.minorMajor7,
      root: 'C#',
      bass: 'C#',
      presentIntervals: const {0, 3, 8, 11},
      extensions: const {ChordExtension.flat13},
      cost: 3.84,
    );
    final splitThirdInversion = _candidate(
      quality: ChordQualityToken.major,
      root: 'A',
      bass: 'C#',
      presentIntervals: const {0, 3, 4, 7},
      extensions: const {ChordExtension.addSharp9},
      cost: 3.93,
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
    // The sus reading earns a lower raw cost (clean template fit with 3
    // required tones) but is a remote, convoluted name for a simple voicing.
    final addChord = _candidate(
      quality: ChordQualityToken.major,
      root: 'C',
      bass: 'C',
      presentIntervals: const {0, 4, 5, 7},
      extensions: const {ChordExtension.add11},
      cost: 3.93,
    );

    final susSlash = _candidate(
      quality: ChordQualityToken.major7sus2,
      root: 'F',
      bass: 'C',
      presentIntervals: const {0, 2, 7, 11},
      cost: 2.63,
    );

    _expectRule(
      addChord,
      susSlash,
      'prefer root-position add-chord over sus slash',
    );
  });

  test('common naming prior can resolve full near-tie cost gap', () {
    final commonMinorNinth = _candidate(
      quality: ChordQualityToken.minor7,
      root: 'Bb',
      bass: 'F',
      presentIntervals: const {0, 2, 3, 7, 10},
      extensions: const {ChordExtension.nine},
      cost: 0.5,
    );

    final rarerMajorThirteenth = _candidate(
      quality: ChordQualityToken.major7,
      root: 'Db',
      bass: 'F',
      presentIntervals: const {0, 4, 7, 9, 11},
      extensions: const {ChordExtension.thirteen},
      cost: 0.7,
    );

    _expectTieRule(
      commonMinorNinth,
      rarerMajorThirteenth,
      'prefer common naming preference',
    );
  });

  test(
    'common naming prior does not promote sharp-five dominant over flat-five',
    () {
      final alteredFifthDominant = _candidate(
        quality: ChordQualityToken.dominant7Sharp5,
        root: 'G',
        bass: 'A',
        presentIntervals: const {0, 2, 4, 8, 10},
        extensions: const {ChordExtension.nine},
        cost: 1.05,
      );

      final flatFiveDominant = _candidate(
        quality: ChordQualityToken.dominant7Flat5,
        root: 'F',
        bass: 'A',
        presentIntervals: const {0, 2, 4, 6, 10},
        extensions: const {ChordExtension.nine},
        cost: 0.9,
      );

      final explanation = ChordCandidateRanking.explain(
        flatFiveDominant,
        alteredFifthDominant,
        tonality: defaultTestTonality,
      );

      expect(explanation.result, -1);
      expect(
        explanation.decidedByRule,
        isNot('prefer common naming preference'),
      );
    },
  );

  test('clean spelling beats awkward tritone flat-five dominant inversion', () {
    final cleanSeventhBass = _candidate(
      quality: ChordQualityToken.dominant7Flat5,
      root: 'D',
      bass: 'C',
      presentIntervals: const {0, 4, 6, 10},
      cost: 2.5,
    );

    final awkwardThirdBass = _candidate(
      quality: ChordQualityToken.dominant7Flat5,
      root: 'Ab',
      bass: 'C',
      presentIntervals: const {0, 4, 6, 10},
      cost: 2.5,
    );

    _expectTieRule(
      cleanSeventhBass,
      awkwardThirdBass,
      'prefer cleaner tritone flat-five dominant spelling',
    );
  });

  test('common naming preference breaks complete sixth and minor7 tie', () {
    final minor7 = _candidate(
      quality: ChordQualityToken.minor7,
      root: 'D',
      bass: 'A',
      presentIntervals: const {0, 3, 7, 10},
      cost: 2.63,
    );

    final major6 = _candidate(
      quality: ChordQualityToken.major6,
      root: 'F',
      bass: 'A',
      presentIntervals: const {0, 4, 7, 9},
      cost: 2.63,
    );

    _expectTieRule(minor7, major6, 'prefer common naming preference');
  });

  test('cleaner spelling breaks final ties', () {
    // Same root, same extension load, nothing structural separates them; the
    // C#maj7 reading spells its third as E# while the minor reading uses E.
    final minorMajor = _candidate(
      quality: ChordQualityToken.minorMajor7,
      root: 'C#',
      bass: 'C#',
      presentIntervals: const {0, 1, 3, 11},
      extensions: const {ChordExtension.flat9},
      cost: 3.5,
    );

    final major7 = _candidate(
      quality: ChordQualityToken.major7,
      root: 'C#',
      bass: 'C#',
      presentIntervals: const {0, 1, 4, 11},
      extensions: const {ChordExtension.flat9},
      cost: 3.5,
    );

    _expectTieRule(minorMajor, major7, 'prefer cleaner spelling');
  });

  test('root-position major6 sharp11 beats inverted minor7 add13', () {
    // These enharmonic readings tie on cost; natural-extension preference
    // settles it toward the major6 (its #11 is natural; the minor7's add13 is
    // an add tone).
    final major6Sharp11 = _candidate(
      quality: ChordQualityToken.major6,
      root: 'Eb',
      bass: 'Eb',
      presentIntervals: const {0, 4, 6, 7, 9},
      extensions: const {ChordExtension.sharp11},
      cost: 2.92,
    );
    final minor7Add13 = _candidate(
      quality: ChordQualityToken.minor7,
      root: 'C',
      bass: 'Eb',
      presentIntervals: const {0, 3, 7, 9, 10},
      extensions: const {ChordExtension.add13},
      cost: 2.92,
    );

    _expectTieRule(
      major6Sharp11,
      minor7Add13,
      'prefer natural extensions over adds, then fewer total',
    );
  });

  test('does not use natural extensions to promote deficient slash chords', () {
    final diminishedAdd9 = _candidate(
      quality: ChordQualityToken.diminished,
      root: 'A#',
      bass: 'A#',
      presentIntervals: const {0, 2, 3, 6},
      extensions: const {ChordExtension.add9},
      cost: 3.78,
    );

    final minorMajor13Slash = _candidate(
      quality: ChordQualityToken.minorMajor7,
      root: 'C#',
      bass: 'A#',
      presentIntervals: const {0, 3, 9, 11},
      extensions: const {ChordExtension.thirteen},
      cost: 3.93,
    );

    _expectTieRule(diminishedAdd9, minorMajor13Slash, 'prefer root position');
  });

  test('allows natural extensions for fifthless dominant shell slash', () {
    final dominant9Slash = _candidate(
      quality: ChordQualityToken.dominant7,
      root: 'D',
      bass: 'C',
      presentIntervals: const {0, 2, 4, 10},
      extensions: const {ChordExtension.nine},
      cost: 3.78,
    );

    final majorFlat5Add9 = _candidate(
      quality: ChordQualityToken.majorFlat5,
      root: 'C',
      bass: 'C',
      presentIntervals: const {0, 2, 4, 6},
      extensions: const {ChordExtension.add9},
      cost: 3.78,
    );

    _expectTieRule(
      dominant9Slash,
      majorFlat5Add9,
      'prefer natural extensions over adds, then fewer total',
    );
  });

  test(
    'full coverage does not promote altered major7 over lower-cost minor ninth shell',
    () {
      final minorNinthShell = _candidate(
        quality: ChordQualityToken.minor7,
        root: 'D',
        bass: 'C',
        presentIntervals: const {0, 2, 3, 10},
        extensions: const {ChordExtension.nine},
        cost: 2.50,
      );

      final majorSeventhSplitNinth = _candidate(
        quality: ChordQualityToken.major7,
        root: 'Db',
        bass: 'C',
        presentIntervals: const {0, 1, 3, 4, 11},
        extensions: const {ChordExtension.flat9, ChordExtension.sharp9},
        cost: 2.65,
      );

      final explanation = ChordCandidateRanking.explain(
        minorNinthShell,
        majorSeventhSplitNinth,
        tonality: defaultTestTonality,
      );

      expect(explanation.result, -1);
      expect(
        explanation.decidedByRule,
        isNot('prefer voicing that names every tone'),
      );
    },
  );

  group('root-position relative minor7 versus major6 slash', () {
    final minor7 = _candidate(
      quality: ChordQualityToken.minor7,
      root: 'A',
      bass: 'A',
      presentIntervals: const {0, 3, 7, 10},
      cost: 2.63,
    );
    final major6Slash = _candidate(
      quality: ChordQualityToken.major6,
      root: 'C',
      bass: 'A',
      presentIntervals: const {0, 4, 7, 9},
      cost: 2.63,
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
        cost: 2.92,
      );
      final coloredMajor6Slash = _candidate(
        quality: ChordQualityToken.major6,
        root: 'C',
        bass: 'A',
        presentIntervals: const {0, 2, 4, 7, 9},
        extensions: const {ChordExtension.add9},
        cost: 2.92,
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
        cost: 2.63,
      );
      final minor7Slash = _candidate(
        quality: ChordQualityToken.minor7,
        root: 'A',
        bass: 'C',
        presentIntervals: const {0, 3, 7, 10},
        cost: 2.63,
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
      // C# has a lower raw cost but the F dominant reading is what musicians
      // expect for this voicing.
      final dom7Slash = _candidate(
        quality: ChordQualityToken.dominant7,
        root: 'F',
        bass: 'G#',
        // intervals: root=0, sharp9=3, major3=4, perfect5=7, flat13=8, flat7=10
        presentIntervals: const {0, 3, 4, 7, 8, 10},
        extensions: const {ChordExtension.sharp9, ChordExtension.flat13},
        cost: 3.41,
      );

      final maj7Slash = _candidate(
        quality: ChordQualityToken.major7,
        root: 'C#',
        bass: 'G#',
        // intervals: root=0, nine=2, major3=4, perfect5=7, flat13=8, major7=11
        presentIntervals: const {0, 2, 4, 7, 8, 11},
        extensions: const {ChordExtension.nine, ChordExtension.flat13},
        cost: 3.26,
      );

      _expectTieRule(
        dom7Slash,
        maj7Slash,
        'prefer dominant7 shell slash over non-dominant seventh-family slash',
      );
    },
  );

  test(
    'complete add-nine triad inversion beats sparse major-thirteenth shell',
    () {
      final triadAddNine = _candidate(
        quality: ChordQualityToken.minor,
        root: 'Bb',
        bass: 'Db',
        presentIntervals: const {0, 2, 3, 7},
        extensions: const {ChordExtension.add9},
        cost: 3.93,
      );

      final sparseMajorThirteenth = _candidate(
        quality: ChordQualityToken.major7,
        root: 'Db',
        bass: 'Db',
        presentIntervals: const {0, 4, 9, 11},
        extensions: const {ChordExtension.thirteen},
        cost: 3.78,
      );

      _expectTieRule(
        triadAddNine,
        sparseMajorThirteenth,
        'prefer complete triad add-tone over sparse seventh-family color',
      );
    },
  );

  group('rank linearizes a non-transitive relation', () {
    const tonality = Tonality(Tonic.c, TonalityMode.major);

    // A beats B via a hard rule (altered dominant7 over dim7 slash) despite B
    // being cheaper; B beats C and C beats A on cost alone (gaps exceed the
    // near-tie window). That is a cycle: A > B > C > A.
    final a = _candidate(
      quality: ChordQualityToken.dominant7,
      root: 'C',
      bass: 'C',
      presentIntervals: const {0, 1, 4, 10},
      extensions: const {ChordExtension.flat9},
      cost: 10.0,
    );
    final b = _candidate(
      quality: ChordQualityToken.diminished7,
      root: 'Bb',
      bass: 'C',
      presentIntervals: const {0, 2, 3, 6, 9},
      extensions: const {ChordExtension.nine},
      cost: 1.0,
    );
    final c = _candidate(
      quality: ChordQualityToken.major,
      root: 'E',
      bass: 'E',
      presentIntervals: const {0, 4, 7},
      cost: 6.0,
    );

    int cmp(ChordCandidate x, ChordCandidate y) =>
        ChordCandidateRanking.compare(x, y, tonality: tonality);

    test('the candidate set really is a cycle (test precondition)', () {
      expect(cmp(a, b), lessThan(0)); // A beats B (hard rule)
      expect(cmp(b, c), lessThan(0)); // B beats C (cost)
      expect(cmp(c, a), lessThan(0)); // C beats A (cost) -> cycle
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
    test('isNearTie window is one-sided around the chosen #1 cost', () {
      const chosenCost = 4.0;
      expect(
        ChordCandidateRanking.isNearTie(chosenCost, 4.15),
        isTrue,
      ); // within
      expect(
        ChordCandidateRanking.isNearTie(chosenCost, 4.24),
        isTrue,
      ); // within
      expect(
        ChordCandidateRanking.isNearTie(chosenCost, 4.26),
        isFalse,
      ); // outside
      // A reading cheaper than the chosen #1 is still a near-tie; the
      // window must not clamp the difference to its absolute value.
      expect(ChordCandidateRanking.isNearTie(chosenCost, 3.7), isTrue);
    });

    ChordCandidate plain(String root, double cost) => _candidate(
      quality: ChordQualityToken.major,
      root: root,
      bass: root,
      presentIntervals: const {0, 4, 7},
      cost: cost,
    );

    test('keeps ranked candidates above the last cost-window alternative', () {
      // #1 was promoted above a lower-cost reading (D, 3.7). A later
      // candidate (F, 4.1) is within the window even though the one before it
      // (E, 4.5) is not, so the visible alternative list should include the
      // whole ranked prefix through F rather than skipping E.
      final ranked = [
        plain('C', 4.0),
        plain('D', 3.7),
        plain('E', 4.5),
        plain('F', 4.1),
      ];

      final alternatives = ChordCandidateRanking.alternatives(ranked);

      expect(ChordCandidateRanking.alternativeCount(ranked), 3);
      expect(alternatives.map((c) => c.identity.rootPc), [
        pc('D'),
        pc('E'),
        pc('F'),
      ]);
    });

    test('returns empty when there are fewer than two candidates', () {
      expect(ChordCandidateRanking.alternativeCount([plain('C', 4.0)]), 0);
      expect(ChordCandidateRanking.alternativeCount(const []), 0);
      expect(ChordCandidateRanking.alternatives([plain('C', 4.0)]), isEmpty);
      expect(ChordCandidateRanking.alternatives(const []), isEmpty);
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
    explanation.costDelta.abs(),
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
    explanation.costDelta.abs(),
    lessThanOrEqualTo(ChordCandidateRanking.nearTieWindow),
  );
}

ChordCandidate _candidate({
  required ChordQualityToken quality,
  required String root,
  required String bass,
  required Set<int> presentIntervals,
  required double cost,
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
    cost: cost,
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
