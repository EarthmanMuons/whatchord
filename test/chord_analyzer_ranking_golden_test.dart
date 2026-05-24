import 'package:whatchord/features/theory/theory.dart';

import 'helpers/chord_analyzer_golden_helpers.dart';

void main() {
  final cases = <GoldenCase>[
    // -------------------------------------------------------------------------
    // Root-position extended harmony vs remote slash reinterpretations
    // -------------------------------------------------------------------------

    // Root-position lydian dominant should beat a remote altered-fifth slash
    // reinterpretation such as D11#5/C.
    golden(
      name: 'C E G Bb D F# -> C9#11',
      expectedSymbol: 'C9#11',
      pcs: ['C', 'E', 'G', 'Bb', 'D', 'F#'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.nine, ChordExtension.sharp11},
    ),

    // Dominant 13 with a sharp eleventh should beat remote slash reinterpretations.
    golden(
      name: 'C E G Bb D F# A -> C13#11',
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

    // Complete minor triad with #11 should beat a remote altered maj7sus4 name.
    golden(
      name: 'E A C D# --bass=E -> Am#11 / E',
      expectedSymbol: 'Am#11 / E',
      pcs: ['E', 'A', 'C', 'D#'],
      bass: 'E',
      expectedRoot: 'A',
      expectedBass: 'E',
      expectedQuality: ChordQualityToken.minor,
      expectedExtensions: {ChordExtension.sharp11},
    ),

    // Complete triad should beat an incomplete inverted 6th reading.
    golden(
      name: 'B E G B --bass=B --key=D:maj -> Em / B',
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

    // 6th-family should beat 7th-family when the 7 is missing.
    golden(
      name: 'G Bb D E -> Gm6',
      expectedSymbol: 'Gm6',
      pcs: ['G', 'Bb', 'D', 'E'],
      expectedRoot: 'G',
      expectedQuality: ChordQualityToken.minor6,
    ),

    // Tonality-specific ranking: same pitch-class set, different "best" chord in A minor.
    golden(
      name: 'C E G A D --key=A:min -> Am7(add11) / C',
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

    // Complete minor-major 7 with #11 should keep the F-rooted sonority rather
    // than prefer a remote major7#5(add11) slash interpretation.
    golden(
      name: 'Ab B C E F -> Fm(maj7)#11 / Ab',
      expectedSymbol: 'Fm(maj7)#11 / Ab',
      pcs: ['Ab', 'B', 'C', 'E', 'F'],
      expectedRoot: 'F',
      expectedQuality: ChordQualityToken.minorMajor7,
      expectedExtensions: {ChordExtension.sharp11},
    ),
  ];

  runChordAnalyzerGoldenCases(cases);
}
