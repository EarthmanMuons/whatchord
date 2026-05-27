import 'package:whatchord/features/theory/theory.dart';

import 'helpers/chord_analyzer_golden_helpers.dart';

void main() {
  final cases = <GoldenCase>[
    // -------------------------------------------------------------------------
    // Root-position extended harmony vs remote slash reinterpretations
    // -------------------------------------------------------------------------
    golden(
      description: 'root-position lydian dominant beats altered-fifth slash',
      expectedSymbol: 'C9#11',
      pcs: ['C', 'E', 'G', 'Bb', 'D', 'F#'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.nine, ChordExtension.sharp11},
    ),

    golden(
      description: 'root-position thirteenth sharp eleventh beats remote slash',
      expectedSymbol: 'C13#11',
      pcs: ['C', 'E', 'G', 'Bb', 'D', 'F#', 'A'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {
        ChordExtension.nine,
        ChordExtension.sharp11,
        ChordExtension.thirteen,
      },
    ),

    // -------------------------------------------------------------------------
    // Slash and inversion disambiguation
    // -------------------------------------------------------------------------
    golden(
      description: 'complete minor sharp eleventh beats altered sus slash',
      expectedSymbol: 'Am#11 / E',
      pcs: ['E', 'A', 'C', 'D#'],
      bass: 'E',
      expectedRoot: 'A',
      expectedBass: 'E',
      expectedQuality: ChordQualityToken.minor,
      expectedExtensions: {ChordExtension.sharp11},
    ),

    golden(
      description: 'complete triad beats incomplete inverted sixth',
      expectedSymbol: 'Em / B',
      pcs: ['B', 'E', 'G'],
      bass: 'B',
      noteCount: 4,
      tonality: const Tonality('D', TonalityMode.major),
      expectedRoot: 'E',
      expectedBass: 'B',
      expectedQuality: ChordQualityToken.minor,
    ),

    golden(
      description: 'complete major inversion beats minor sharp fifth',
      expectedSymbol: 'Ab / C',
      expectedAlternateSymbols: ['Cm#5'],
      pcs: ['C', 'Eb', 'Ab'],
      bass: 'C',
      expectedRoot: 'Ab',
      expectedBass: 'C',
      expectedQuality: ChordQualityToken.major,
    ),

    golden(
      description:
          'complete second-inversion major triad beats minor sharp fifth',
      expectedSymbol: 'Ab / Eb',
      expectedAlternateSymbols: ['Cm#5 / Eb'],
      pcs: ['C', 'Eb', 'Ab'],
      bass: 'Eb',
      expectedRoot: 'Ab',
      expectedBass: 'Eb',
      expectedQuality: ChordQualityToken.major,
    ),

    golden(
      description: 'upper-structure major triad over ninth bass',
      expectedSymbol: 'C# / D#',
      expectedAlternateSymbols: ['E#m7#5 / D#'],
      pcs: ['D#', 'C#', 'E#', 'G#'],
      bass: 'D#',
      tonality: const Tonality('C#', TonalityMode.major),
      expectedRoot: 'C#',
      expectedBass: 'D#',
      expectedQuality: ChordQualityToken.major,
      expectedExtensions: {ChordExtension.add9},
    ),

    golden(
      description:
          'root-position dominant sus beats complete second-inversion sus',
      expectedSymbol: 'G7sus4',
      expectedAlternateSymbols: ['Csus4 / G'],
      pcs: ['C', 'F', 'G'],
      bass: 'G',
      expectedRoot: 'G',
      expectedBass: 'G',
      expectedQuality: ChordQualityToken.dominant7sus4,
    ),

    golden(
      description: 'root-position ninth sus beats remote slash readings',
      expectedSymbol: 'D9sus4',
      expectedAlternateSymbols: ['Em7#5(add11) / D', 'Am7(add11) / D'],
      pcs: ['C', 'D', 'E', 'G', 'A'],
      bass: 'D',
      expectedRoot: 'D',
      expectedBass: 'D',
      expectedQuality: ChordQualityToken.dominant7sus4,
      expectedExtensions: {ChordExtension.nine},
    ),

    golden(
      description: 'ninth-bass dominant stack beats altered slash',
      expectedSymbol: 'C7 / D',
      expectedAlternateSymbols: ['Gm6add11 / D'],
      pcs: ['D', 'C', 'E', 'G', 'Bb'],
      bass: 'D',
      expectedRoot: 'C',
      expectedBass: 'D',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.nine},
    ),

    // -------------------------------------------------------------------------
    // Sixth-family ranking
    // -------------------------------------------------------------------------
    golden(
      description: 'sixth-family beats seventh-family when seventh is absent',
      expectedSymbol: 'Gm6',
      pcs: ['G', 'Bb', 'D', 'E'],
      expectedRoot: 'G',
      expectedQuality: ChordQualityToken.minor6,
    ),

    golden(
      description: 'minor-key tonality bias changes best interpretation',
      expectedSymbol: 'Am7(add11) / C',
      pcs: ['C', 'E', 'G', 'A', 'D'],
      tonality: const Tonality('A', TonalityMode.minor),
      expectedRoot: 'A',
      expectedBass: 'C',
      expectedQuality: ChordQualityToken.minor7,
      expectedExtensions: {ChordExtension.add11},
    ),

    // -------------------------------------------------------------------------
    // Sus-tone-in-bass penalty
    // -------------------------------------------------------------------------

    // {A, C, D, E} with E bass could be read as D7sus2/E (sus2 in bass),
    // C6/9/E (incomplete inverted sixth), or Amadd11/E (complete minor triad
    // with added color). The sus-bass penalty demotes D7sus2/E into a near-tie,
    // and the complete-triad-core rule prefers the Am reading over C6/9/E.
    golden(
      description: 'am add11 beats incomplete inverted sixth',
      expectedSymbol: 'Amadd11 / E',
      pcs: ['A', 'C', 'D', 'E'],
      bass: 'E',
      expectedRoot: 'A',
      expectedBass: 'E',
      expectedQuality: ChordQualityToken.minor,
      expectedExtensions: {ChordExtension.add11},
    ),

    golden(
      description: 'am add11 beats sus2-tone-in-bass in A minor context',
      expectedSymbol: 'Amadd11 / E',
      pcs: ['A', 'C', 'D', 'E'],
      bass: 'E',
      tonality: const Tonality('A', TonalityMode.minor),
      expectedRoot: 'A',
      expectedBass: 'E',
      expectedQuality: ChordQualityToken.minor,
      expectedExtensions: {ChordExtension.add11},
    ),

    golden(
      description: 'transposed add11 beats incomplete inverted sixth',
      expectedSymbol: 'Dmadd11 / A',
      pcs: ['D', 'F', 'G', 'A'],
      bass: 'A',
      tonality: const Tonality('F', TonalityMode.major),
      expectedRoot: 'D',
      expectedBass: 'A',
      expectedQuality: ChordQualityToken.minor,
      expectedExtensions: {ChordExtension.add11},
    ),

    // -------------------------------------------------------------------------
    // Compact voicing disambiguation
    // -------------------------------------------------------------------------
    golden(
      description:
          'minor-major sharp eleventh beats remote major sharp-five slash',
      expectedSymbol: 'Fm(maj7)#11 / Ab',
      pcs: ['Ab', 'B', 'C', 'E', 'F'],
      expectedRoot: 'F',
      expectedQuality: ChordQualityToken.minorMajor7,
      expectedExtensions: {ChordExtension.sharp11},
    ),
  ];

  runChordAnalyzerGoldenCases(cases);
}
