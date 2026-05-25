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
