import 'package:whatchord/features/theory/theory.dart';

import 'helpers/chord_analyzer_golden_helpers.dart';

void main() {
  final cases = <GoldenCase>[
    // -------------------------------------------------------------------------
    // Enharmonic spelling edge cases (key signature should influence letter names)
    // -------------------------------------------------------------------------

    // In F# major (6 sharps), we should prefer E# over F for the leading tone triad.
    golden(
      description: 'sharp key preserves leading-tone diminished spelling',
      expectedSymbol: 'E#dim',
      pcs: ['E#', 'G#', 'B'],
      tonality: const Tonality(Tonic.fSharp, TonalityMode.major),
      expectedRoot: 'E#',
      expectedQuality: ChordQualityToken.diminished,
    ),

    // In Cb major (7 flats), we should prefer Fb over E for the subdominant chord.
    golden(
      description: 'flat key preserves subdominant spelling',
      expectedSymbol: 'Fb',
      pcs: ['Fb', 'Ab', 'Cb'],
      tonality: const Tonality(Tonic.cFlat, TonalityMode.major),
      expectedRoot: 'Fb',
      expectedQuality: ChordQualityToken.major,
    ),

    // -------------------------------------------------------------------------
    // Tonality bias vs chord-structure evidence (spelling/context disambiguation)
    // -------------------------------------------------------------------------

    // Diminished context: interpret Gb as b5 (not F# as #11) when structure supports dim.
    golden(
      description: 'diminished structure overrides sharp-leaning key spelling',
      expectedSymbol: 'Cdim/Gb',
      pcs: ['Gb', 'C', 'Eb'],
      tonality: const Tonality(Tonic.d, TonalityMode.major), // sharp-leaning
      expectedRoot: 'C',
      expectedBass: 'Gb',
      expectedQuality: ChordQualityToken.diminished,
    ),

    // Complete flat-five dominant sevenths should use the core b5 quality.
    golden(
      description: 'flat-leaning key spells complete flat-five dominant',
      expectedSymbol: 'Gb7b5',
      pcs: ['F#', 'C', 'E', 'Bb'],
      tonality: const Tonality(Tonic.dFlat, TonalityMode.major), // flat-leaning
      expectedRoot: 'F#',
      expectedBass: 'F#',
      expectedQuality: ChordQualityToken.dominant7Flat5,
    ),

    // Augmented triads are symmetric by pitch class, but root spelling should
    // still avoid double-sharp member names when a clean spelling exists.
    golden(
      description: 'root-position augmented triad uses readable root spelling',
      expectedSymbol: 'Abaug',
      pcs: ['C', 'E', 'Ab'],
      bass: 'Ab',
      expectedRoot: 'Ab',
      expectedBass: 'Ab',
      expectedQuality: ChordQualityToken.augmented,
    ),
  ];

  runChordAnalyzerGoldenCases(cases);
}
