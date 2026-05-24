import 'package:whatchord/features/theory/theory.dart';

import 'helpers/chord_analyzer_golden_helpers.dart';

void main() {
  final cases = <GoldenCase>[
    // -------------------------------------------------------------------------
    // Enharmonic spelling edge cases (key signature should influence letter names)
    // -------------------------------------------------------------------------

    // In F# major (6 sharps), we should prefer E# over F for the leading tone triad.
    golden(
      name: 'E# G# B --key=F#:maj -> E#dim',
      expectedSymbol: 'E#dim',
      pcs: ['E#', 'G#', 'B'],
      tonality: const Tonality('F#', TonalityMode.major),
      expectedRoot: 'E#',
      expectedQuality: ChordQualityToken.diminished,
    ),

    // In Cb major (7 flats), we should prefer Fb over E for the subdominant chord.
    golden(
      name: 'Fb Ab Cb --key=Cb:maj -> Fb',
      expectedSymbol: 'Fb',
      pcs: ['Fb', 'Ab', 'Cb'],
      tonality: const Tonality('Cb', TonalityMode.major),
      expectedRoot: 'Fb',
      expectedQuality: ChordQualityToken.major,
    ),

    // -------------------------------------------------------------------------
    // Tonality bias vs chord-structure evidence (spelling/context disambiguation)
    // -------------------------------------------------------------------------

    // Diminished context: interpret Gb as b5 (not F# as #11) when structure supports dim.
    golden(
      name: 'Gb C Eb -> Cdim / Gb',
      expectedSymbol: 'Cdim / Gb',
      pcs: ['Gb', 'C', 'Eb'],
      tonality: const Tonality('D', TonalityMode.major), // sharp-leaning
      expectedRoot: 'C',
      expectedBass: 'Gb',
      expectedQuality: ChordQualityToken.diminished,
    ),

    // Complete flat-five dominant sevenths should use the core b5 quality.
    golden(
      name: 'F# C E Bb -> Gb7b5',
      expectedSymbol: 'Gb7b5',
      pcs: ['F#', 'C', 'E', 'Bb'],
      tonality: const Tonality('Db', TonalityMode.major), // flat-leaning
      expectedRoot: 'F#',
      expectedBass: 'F#',
      expectedQuality: ChordQualityToken.dominant7Flat5,
    ),
  ];

  runChordAnalyzerGoldenCases(cases);
}
