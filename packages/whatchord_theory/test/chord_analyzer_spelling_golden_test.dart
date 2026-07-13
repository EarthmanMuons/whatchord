import 'package:whatchord_theory/whatchord_theory.dart';

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

    // -------------------------------------------------------------------------
    // Slash bass readability: a color/altered tone in the bass names the
    // sounding pitch, not its interior role, so it avoids wrap and double
    // accidental spellings. The chord body still carries the harmonic role.
    // -------------------------------------------------------------------------

    // A #9 in the bass would functionally spell as B# (a wrap); prefer C.
    golden(
      description: 'sharp-nine bass avoids wrap spelling',
      expectedSymbol: 'A7#9/C',
      pcs: ['A', 'C#', 'E', 'G', 'C'],
      bass: 'C',
      expectedRoot: 'A',
      expectedBass: 'C',
      expectedQuality: ChordQualityToken.dominant7,
    ),

    // A #9 in the bass would functionally spell as Cx (double sharp); prefer D.
    golden(
      description: 'sharp-nine bass avoids double-sharp spelling',
      expectedSymbol: 'B7#9/D',
      pcs: ['B', 'D#', 'F#', 'A', 'D'],
      bass: 'D',
      expectedRoot: 'B',
      expectedBass: 'D',
      expectedQuality: ChordQualityToken.dominant7,
    ),

    // Stacked tensions in the bass stay readable while the body names the roles.
    golden(
      description: 'upper-structure tension bass stays readable',
      expectedSymbol: 'A13(#9,#11)/C',
      pcs: ['A', 'C#', 'E', 'G', 'C', 'D#', 'F#'],
      bass: 'C',
      expectedRoot: 'A',
      expectedBass: 'C',
      expectedQuality: ChordQualityToken.dominant7,
    ),

    // Contrast: a genuine chord-tone inversion keeps its functional spelling
    // even as a wrap letter. In C# major the major seventh is B#, not C.
    golden(
      description: 'major-seventh bass inversion keeps wrap spelling',
      expectedSymbol: 'C#maj7/B#',
      pcs: ['C#', 'E#', 'G#', 'B#'],
      bass: 'B#',
      tonality: const Tonality(Tonic.cSharp, TonalityMode.major),
      expectedRoot: 'C#',
      expectedBass: 'B#',
      expectedQuality: ChordQualityToken.major7,
    ),

    // Contrast: the major third in the bass keeps its sharp inversion spelling.
    golden(
      description: 'major-third bass inversion keeps sharp spelling',
      expectedSymbol: 'F#7/A#',
      pcs: ['F#', 'A#', 'C#', 'E'],
      bass: 'A#',
      expectedRoot: 'F#',
      expectedBass: 'A#',
      expectedQuality: ChordQualityToken.dominant7,
    ),
  ];

  runChordAnalyzerGoldenCases(cases);
}
