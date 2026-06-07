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
      tonality: const Tonality(Tonic.d, TonalityMode.major),
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
      description:
          'complete major triad with flat ninth beats note-dropping '
          'diminished triad',
      expectedSymbol: 'Caddb9 / G',
      expectedAlternateSymbols: ['Em#5add13 / G', 'Em6b13 / G', 'C#dim / G'],
      pcs: ['C', 'Db', 'E', 'G'],
      bass: 'G',
      expectedRoot: 'C',
      expectedBass: 'G',
      expectedQuality: ChordQualityToken.major,
      expectedExtensions: {ChordExtension.addFlat9},
    ),

    golden(
      description: 'upper-structure major triad over ninth bass',
      expectedSymbol: 'C# / D#',
      expectedAlternateSymbols: ['E#m7#5 / D#'],
      pcs: ['D#', 'C#', 'E#', 'G#'],
      bass: 'D#',
      tonality: const Tonality(Tonic.cSharp, TonalityMode.major),
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
      expectedAlternateSymbols: ['Am7 / D', 'Em7#5(add11) / D'],
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

    golden(
      description: 'complete dominant flat-nine beats colored diminished7',
      expectedSymbol: 'C7b9 / G',
      pcs: ['C', 'Db', 'E', 'G', 'Bb'],
      bass: 'G',
      expectedRoot: 'C',
      expectedBass: 'G',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.flat9},
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
      tonality: const Tonality(Tonic.a, TonalityMode.minor),
      expectedRoot: 'A',
      expectedBass: 'C',
      expectedQuality: ChordQualityToken.minor7,
      expectedExtensions: {ChordExtension.add11},
    ),

    golden(
      description: 'common-name prior breaks sixth versus minor seventh tie',
      expectedSymbol: 'Dm7 / A',
      expectedAlternateSymbols: ['F6 / A'],
      pcs: ['C', 'D', 'F', 'A'],
      bass: 'A',
      tonality: const Tonality(Tonic.c, TonalityMode.major),
      expectedRoot: 'D',
      expectedBass: 'A',
      expectedQuality: ChordQualityToken.minor7,
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
      tonality: const Tonality(Tonic.a, TonalityMode.minor),
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
      tonality: const Tonality(Tonic.f, TonalityMode.major),
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

    // -------------------------------------------------------------------------
    // Dominant7 shell slash beats non-dominant seventh-family slash
    // -------------------------------------------------------------------------
    // {C, Db, Eb, F, Ab, A} with Ab bass: the F altered dominant reading
    // (F7#9b13 with Ab=G# as the sharp-9 bass) is what musicians expect.
    // The competing C#maj9b13/Ab interpretation has a higher raw score, but
    // the dom7 shell-slash rule correctly promotes F7.
    golden(
      description: 'dominant7 shell slash beats major7 family slash',
      expectedSymbol: 'F7(#9,b13) / G#',
      pcs: ['C', 'Db', 'Eb', 'F', 'Ab', 'A'],
      bass: 'Ab',
      expectedRoot: 'F',
      expectedBass: 'G#',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.sharp9, ChordExtension.flat13},
    ),

    golden(
      description: 'complete altered dominant inversion beats altered major7',
      expectedSymbol: 'A7#5#9 / C#',
      pcs: ['C', 'Db', 'F', 'G', 'A'],
      bass: 'Db',
      expectedRoot: 'A',
      expectedBass: 'C#',
      expectedQuality: ChordQualityToken.dominant7Sharp5,
      expectedExtensions: {ChordExtension.sharp9},
    ),

    golden(
      description: 'complete dominant sharp-nine beats sixth flat-nine',
      expectedSymbol: 'C7#9 / D#',
      pcs: ['C', 'Eb', 'E', 'G', 'Bb'],
      bass: 'Eb',
      expectedRoot: 'C',
      expectedBass: 'D#',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.sharp9},
    ),

    // -------------------------------------------------------------------------
    // Simple triad add-tone beats inverted unusual seventh-family quality
    // -------------------------------------------------------------------------
    golden(
      description: 'simple triad add-tone beats inverted unusual seventh',
      expectedSymbol: 'Cadd9 / G',
      pcs: ['C', 'D', 'E', 'G'],
      bass: 'G',
      expectedRoot: 'C',
      expectedBass: 'G',
      expectedQuality: ChordQualityToken.major,
      expectedExtensions: {ChordExtension.add9},
    ),

    golden(
      description: 'root-position double suspension beats dominant sus slash',
      expectedSymbol: 'Gsus2sus4',
      expectedAlternateSymbols: ['D7sus4 / G'],
      pcs: ['G', 'D', 'A', 'C'],
      bass: 'G',
      tonality: const Tonality(Tonic.d, TonalityMode.major),
      expectedRoot: 'G',
      expectedQuality: ChordQualityToken.sus2sus4,
      expectedToneRolesByInterval: {
        2: ChordToneRole.sus2,
        5: ChordToneRole.sus4,
      },
    ),

    golden(
      description:
          'common altered dominant beats rarer enharmonic ninth inversion',
      expectedSymbol: 'G7#5 / A',
      expectedAlternateSymbols: ['F9b5 / A'],
      pcs: ['A', 'G', 'D#', 'F', 'B'],
      bass: 'A',
      tonality: const Tonality(Tonic.b, TonalityMode.minor),
      expectedRoot: 'G',
      expectedBass: 'A',
      expectedQuality: ChordQualityToken.dominant7Sharp5,
      expectedExtensions: {ChordExtension.nine},
    ),

    // -------------------------------------------------------------------------
    // Root-position add-chord beats dominant sus slash
    // -------------------------------------------------------------------------
    golden(
      description: 'root-position add-chord beats dominant sus slash',
      expectedSymbol: 'Abadd9',
      pcs: ['C', 'Eb', 'Ab', 'Bb'],
      bass: 'Ab',
      expectedRoot: 'Ab',
      expectedQuality: ChordQualityToken.major,
      expectedExtensions: {ChordExtension.add9},
    ),

    // -------------------------------------------------------------------------
    // Conventional add-tone slash beats root-position dominant sus
    // -------------------------------------------------------------------------
    golden(
      description:
          'conventional add-tone slash beats root-position dominant sus',
      expectedSymbol: 'Abadd11 / Eb',
      pcs: ['C', 'Db', 'Eb', 'Ab'],
      bass: 'Eb',
      expectedRoot: 'Ab',
      expectedBass: 'Eb',
      expectedQuality: ChordQualityToken.major,
      expectedExtensions: {ChordExtension.add11},
    ),
  ];

  runChordAnalyzerGoldenCases(cases);
}
