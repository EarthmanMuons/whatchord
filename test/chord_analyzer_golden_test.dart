import 'package:whatchord/features/theory/theory.dart';

import 'helpers/chord_analyzer_golden_helpers.dart';

void main() {
  final cases = <GoldenCase>[
    // -------------------------------------------------------------------------
    // Major / dominant / extended tertian harmony
    // -------------------------------------------------------------------------
    golden(
      description: 'plain major triad',
      expectedSymbol: 'C',
      pcs: ['C', 'E', 'G'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major,
    ),

    golden(
      description: 'major triad with added ninth',
      expectedSymbol: 'Cadd9',
      pcs: ['C', 'E', 'G', 'D'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major,
      expectedExtensions: {ChordExtension.add9},
    ),

    golden(
      description: 'major triad with split third as added sharp ninth',
      expectedSymbol: 'Cadd#9',
      pcs: ['C', 'Eb', 'E', 'G'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major,
      expectedExtensions: {ChordExtension.addSharp9},
      expectedToneRolesByInterval: {3: ChordToneRole.splitMinor3},
    ),

    golden(
      description: 'split third shell without fifth',
      expectedSymbol: 'Cadd#9',
      pcs: ['C', 'Eb', 'E'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major,
      expectedExtensions: {ChordExtension.addSharp9},
      expectedToneRolesByInterval: {3: ChordToneRole.splitMinor3},
    ),

    golden(
      description: 'major sixth with split third as added sharp ninth',
      expectedSymbol: 'C6add#9',
      pcs: ['C', 'Eb', 'E', 'G', 'A'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major6,
      expectedExtensions: {ChordExtension.addSharp9},
      expectedToneRolesByInterval: {3: ChordToneRole.splitMinor3},
    ),

    golden(
      description: 'split-third major triad in second inversion',
      expectedSymbol: 'Aadd#9 / E',
      expectedAlternateSymbols: ['C#m(maj7)b13 / E', 'C6b9 / E'],
      pcs: ['C', 'Db', 'E', 'A'],
      bass: 'E',
      expectedRoot: 'A',
      expectedBass: 'E',
      expectedQuality: ChordQualityToken.major,
      expectedExtensions: {ChordExtension.addSharp9},
      expectedToneRolesByInterval: {3: ChordToneRole.splitMinor3},
    ),

    golden(
      description: 'split-third color bass does not become major inversion',
      expectedSymbol: 'C6b9',
      pcs: ['C', 'Db', 'E', 'A'],
      bass: 'C',
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major6,
      expectedExtensions: {ChordExtension.flat9},
    ),

    golden(
      description: 'straight dominant seventh',
      expectedSymbol: 'C7',
      pcs: ['C', 'E', 'G', 'Bb'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7,
      expectNoExtensions: true,
    ),

    golden(
      description: 'dominant ninth',
      expectedSymbol: 'C9',
      pcs: ['C', 'E', 'G', 'Bb', 'D'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.nine},
    ),

    // A lone 11 on a dominant seventh is an added tone, not a true 11th chord.
    golden(
      description: 'dominant seventh with lone added eleventh',
      expectedSymbol: 'C7(add11)',
      pcs: ['C', 'E', 'G', 'Bb', 'F'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.add11},
      unexpectedExtensions: {ChordExtension.eleven},
    ),

    // A true dominant 11 includes the implied ninth.
    golden(
      description: 'dominant eleventh with implied ninth present',
      expectedSymbol: 'C11',
      pcs: ['C', 'E', 'G', 'Bb', 'D', 'F'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.nine, ChordExtension.eleven},
    ),

    golden(
      description: 'major ninth',
      expectedSymbol: 'Cmaj9',
      pcs: ['C', 'E', 'G', 'B', 'D'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major7,
      expectedExtensions: {ChordExtension.nine},
    ),

    // 13th (as 7 + 9 + 13).
    golden(
      description: 'dominant thirteenth with ninth',
      expectedSymbol: 'C13',
      pcs: ['C', 'E', 'G', 'Bb', 'D', 'A'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.nine, ChordExtension.thirteen},
    ),

    // The fifth is optional in extended dominant voicings.
    golden(
      description: 'dominant thirteenth sharp eleventh with omitted fifth',
      expectedSymbol: 'C13#11',
      pcs: ['C', 'E', 'Bb', 'D', 'F#', 'A'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {
        ChordExtension.nine,
        ChordExtension.sharp11,
        ChordExtension.thirteen,
      },
    ),

    // -------------------------------------------------------------------------
    // Slash bass / inversions (explicit bass handling)
    // -------------------------------------------------------------------------

    // Same sonority as C9, but with a non-root bass should render a slash chord.
    golden(
      description: 'dominant ninth over fifth in the bass',
      expectedSymbol: 'C9 / G',
      pcs: ['C', 'E', 'G', 'Bb', 'D'],
      bass: 'G',
      expectedRoot: 'C',
      expectedBass: 'G',
      expectedQuality: ChordQualityToken.dominant7,
    ),

    golden(
      description: 'major sixth in first inversion',
      expectedSymbol: 'C6 / E',
      pcs: ['C', 'E', 'G', 'A'],
      bass: 'E',
      expectedRoot: 'C',
      expectedBass: 'E',
      expectedQuality: ChordQualityToken.major6,
    ),

    // Root-position 6(no5) with a doubled root remains a legitimate 6th chord.
    golden(
      description: 'major sixth without fifth and doubled root',
      expectedSymbol: 'C6',
      pcs: ['C', 'E', 'A'],
      noteCount: 4,
      expectedRoot: 'C',
      expectedBass: 'C',
      expectedQuality: ChordQualityToken.major6,
    ),

    // -------------------------------------------------------------------------
    // Altered/colored dominants
    // -------------------------------------------------------------------------
    golden(
      description: 'dominant seventh flat ninth',
      expectedSymbol: 'C7b9',
      pcs: ['C', 'E', 'G', 'Bb', 'Db'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.flat9},
    ),

    // Hendrix chord: dominant shell plus #9 should not be treated as a minor-third penalty.
    golden(
      description: 'dominant seventh sharp ninth',
      expectedSymbol: 'G7#9',
      pcs: ['G', 'B', 'D', 'F', 'A#'],
      expectedRoot: 'G',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.sharp9},
    ),

    golden(
      description: 'dominant seventh with flat ninth and sharp eleventh',
      expectedSymbol: 'C7(b9,#11)',
      pcs: ['C', 'E', 'G', 'Bb', 'Db', 'F#'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.flat9, ChordExtension.sharp11},
    ),

    golden(
      description: 'dominant seventh with three altered extensions',
      expectedSymbol: 'C7(b9,#11,b13)',
      pcs: ['C', 'E', 'G', 'Bb', 'Db', 'F#', 'Ab'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {
        ChordExtension.flat9,
        ChordExtension.sharp11,
        ChordExtension.flat13,
      },
    ),

    // Dominant 7 suspended 4 with 9 should promote to the combined headline.
    golden(
      description: 'dominant ninth suspended fourth',
      expectedSymbol: 'C9sus4',
      pcs: ['C', 'F', 'G', 'Bb', 'D'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7sus4,
      expectedExtensions: {ChordExtension.nine},
    ),

    golden(
      description: 'dominant seventh suspended second',
      expectedSymbol: 'C7sus2',
      pcs: ['C', 'D', 'G', 'Bb'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7sus2,
    ),

    golden(
      description: 'major seventh suspended second',
      expectedSymbol: 'Cmaj7sus2',
      pcs: ['C', 'D', 'G', 'B'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major7sus2,
    ),

    golden(
      description: 'major seventh suspended fourth',
      expectedSymbol: 'Cmaj7sus4',
      pcs: ['C', 'F', 'G', 'B'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major7sus4,
    ),

    // Dominant 7 sharp 5 should treat the augmented fifth as a core tone.
    golden(
      description: 'dominant seventh sharp fifth',
      expectedSymbol: 'C7#5',
      pcs: ['C', 'E', 'G#', 'Bb'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7Sharp5,
      expectedToneRolesByInterval: {8: ChordToneRole.sharp5},
    ),

    // The pitch-class set also admits Cm#5, but a complete first-inversion
    // major triad is the more conventional default for MIDI-style input.
    golden(
      description: 'first-inversion major triad beats minor sharp fifth',
      expectedSymbol: 'Ab / C',
      pcs: ['C', 'Eb', 'G#'],
      expectedRoot: 'Ab',
      expectedBass: 'C',
      expectedQuality: ChordQualityToken.major,
    ),

    // The same inversion-over-minorSharp5 preference that produces F#11/A for
    // {A, C, F, B} also applies here: Ab major (Ab, C, Eb) is a complete triad
    // in first inversion with D as #11, which is more natural than reading D as
    // add9 on the less common Cm#5 quality.
    golden(
      description:
          'major triad inversion beats minor sharp-five with added ninth',
      expectedSymbol: 'Ab#11 / C',
      pcs: ['C', 'Eb', 'G#', 'D'],
      expectedRoot: 'Ab',
      expectedBass: 'C',
      expectedQuality: ChordQualityToken.major,
      expectedExtensions: {ChordExtension.sharp11},
      expectedToneRolesByInterval: {6: ChordToneRole.sharp11},
    ),

    // Minor 7 sharp 5 should treat the augmented fifth as a core tone.
    golden(
      description: 'minor seventh sharp fifth',
      expectedSymbol: 'Cm7#5',
      pcs: ['C', 'Eb', 'G#', 'Bb'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.minor7Sharp5,
      expectedToneRolesByInterval: {8: ChordToneRole.sharp5},
    ),

    // Dominant 7 flat 5 should treat the diminished fifth as a core tone.
    golden(
      description: 'dominant seventh flat fifth',
      expectedSymbol: 'C7b5',
      pcs: ['C', 'E', 'Gb', 'Bb'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7Flat5,
      expectedToneRolesByInterval: {6: ChordToneRole.flat5},
    ),

    // Major 7 sharp 5 should treat the augmented fifth as a core tone.
    golden(
      description: 'major seventh sharp fifth',
      expectedSymbol: 'Cmaj7#5',
      pcs: ['C', 'E', 'G#', 'B'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major7Sharp5,
      expectedToneRolesByInterval: {8: ChordToneRole.sharp5},
    ),

    // Major 7 flat 5 should treat the diminished fifth as a core tone.
    golden(
      description: 'major seventh flat fifth',
      expectedSymbol: 'Cmaj7b5',
      pcs: ['C', 'E', 'Gb', 'B'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major7Flat5,
      expectedToneRolesByInterval: {6: ChordToneRole.flat5},
    ),

    // Major flat 5: three-note root+M3+tritone. The tritone replaces the fifth,
    // so it reads as a flat-five chord rather than a major triad with a #11
    // extension. When the natural fifth (P5) is absent, the flat-five template
    // wins cleanly; adding P5 to the voicing shifts the winner back to the
    // plain major template with a #11 extension.
    golden(
      description: 'major flat fifth triad (tritone replaces fifth)',
      expectedSymbol: 'C(b5)',
      pcs: ['C', 'E', 'Gb'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.majorFlat5,
      expectNoExtensions: true,
      expectedToneRolesByInterval: {6: ChordToneRole.flat5},
    ),

    // The oracle case: Ab-C-D in a flat-key context spells as Ab(b5).
    golden(
      description: 'major flat fifth triad in flat key context',
      expectedSymbol: 'Ab(b5)',
      pcs: ['Ab', 'C', 'D'],
      bass: 'Ab',
      tonality: Tonality(Tonic.aFlat, TonalityMode.major),
      expectedRoot: 'Ab',
      expectedQuality: ChordQualityToken.majorFlat5,
      expectNoExtensions: true,
      expectedToneRolesByInterval: {6: ChordToneRole.flat5},
    ),

    golden(
      description:
          'major flat fifth triad with P5 present reverts to major #11',
      expectedSymbol: 'Ab#11',
      pcs: ['Ab', 'C', 'Eb', 'D'],
      bass: 'Ab',
      expectedRoot: 'Ab',
      expectedQuality: ChordQualityToken.major,
      expectedExtensions: {ChordExtension.sharp11},
    ),

    // Altered augmented dominants keep both the #5 core tone and #9 color.
    golden(
      description: 'altered augmented dominant with sharp ninth',
      expectedSymbol: 'C7#5#9',
      pcs: ['C', 'E', 'G#', 'Bb', 'D#'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7Sharp5,
      expectedExtensions: {ChordExtension.sharp9},
      expectedToneRolesByInterval: {8: ChordToneRole.sharp5},
    ),

    // Altered flat-five dominants keep both the b5 core tone and #9 color.
    golden(
      description: 'altered flat-five dominant with sharp ninth',
      expectedSymbol: 'C7b5#9',
      pcs: ['C', 'E', 'Gb', 'Bb', 'D#'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7Flat5,
      expectedExtensions: {ChordExtension.sharp9},
      expectedToneRolesByInterval: {6: ChordToneRole.flat5},
    ),

    // -------------------------------------------------------------------------
    // Suspended chords
    // -------------------------------------------------------------------------
    golden(
      description: 'suspended fourth triad',
      expectedSymbol: 'Csus4',
      pcs: ['C', 'F', 'G'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.sus4,
    ),

    golden(
      description: 'suspended second triad',
      expectedSymbol: 'Csus2',
      pcs: ['C', 'D', 'G'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.sus2,
    ),

    golden(
      description: 'double-suspended chord',
      expectedSymbol: 'Csus2sus4',
      pcs: ['C', 'D', 'F', 'G'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.sus2sus4,
      expectedToneRolesByInterval: {
        2: ChordToneRole.sus2,
        5: ChordToneRole.sus4,
      },
    ),

    // -------------------------------------------------------------------------
    // 6th-family
    // -------------------------------------------------------------------------
    golden(
      description: 'major sixth',
      expectedSymbol: 'C6',
      pcs: ['C', 'E', 'G', 'A'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major6,
    ),

    golden(
      description: 'minor sixth',
      expectedSymbol: 'Am6',
      pcs: ['A', 'C', 'E', 'F#'],
      expectedRoot: 'A',
      expectedQuality: ChordQualityToken.minor6,
    ),

    // 6/9 sonority: represented as major6 + add9 in this system.
    golden(
      description: 'six-nine sonority',
      expectedSymbol: 'C6/9',
      pcs: ['C', 'E', 'G', 'A', 'D'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major6,
      expectedExtensions: {ChordExtension.add9},
    ),

    // Dominant 7 with a lone 13 is an added tone, not a true 13th chord.
    golden(
      description: 'dominant seventh with lone added thirteenth',
      expectedSymbol: 'C7(add13)',
      pcs: ['C', 'E', 'G', 'Bb', 'A'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.add13},
      unexpectedExtensions: {ChordExtension.thirteen},
    ),

    // -------------------------------------------------------------------------
    // Diminished-family (half-diminished and diminished7)
    // -------------------------------------------------------------------------
    golden(
      description: 'half-diminished seventh',
      expectedSymbol: 'Bm7(b5)',
      pcs: ['B', 'D', 'F', 'A'],
      expectedRoot: 'B',
      expectedQuality: ChordQualityToken.halfDiminished7,
    ),

    golden(
      description: 'half-diminished ninth headline',
      expectedSymbol: 'Cm9(b5)',
      pcs: ['C', 'Eb', 'Gb', 'Bb', 'D'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.halfDiminished7,
      expectedExtensions: {ChordExtension.nine},
    ),

    // Diminished seventh with color tones: verify extension mapping stays stable
    // unless the same pitch set forms a complete dominant flat-nine in a stable
    // inversion.
    golden(
      description: 'diminished seventh with added ninth',
      expectedSymbol: 'Cdim7(add9)',
      pcs: ['C', 'Eb', 'Gb', 'A', 'D'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.diminished7,
      expectedExtensions: {ChordExtension.nine},
    ),
    golden(
      description: 'complete dominant flat-nine beats diminished add-eleventh',
      expectedSymbol: 'F7b9 / C',
      pcs: ['C', 'Eb', 'Gb', 'A', 'F'],
      expectedRoot: 'F',
      expectedBass: 'C',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.flat9},
    ),
    golden(
      description: 'complete dominant flat-nine beats diminished flat-thirteen',
      expectedSymbol: 'G#7b9 / B#',
      pcs: ['C', 'Eb', 'Gb', 'A', 'Ab'],
      expectedRoot: 'G#',
      expectedBass: 'B#',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.flat9},
    ),
    golden(
      description: 'diminished seventh with flat ninth',
      expectedSymbol: 'Cdim7(b9)',
      pcs: ['C', 'Eb', 'Gb', 'A', 'Db'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.diminished7,
      expectedExtensions: {ChordExtension.flat9},
    ),

    // -------------------------------------------------------------------------
    // Shells / compact voicings
    // -------------------------------------------------------------------------
    golden(
      description: 'minor-major seventh shell without fifth',
      expectedSymbol: 'Cm(maj7)',
      pcs: ['C', 'Eb', 'B'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.minorMajor7,
    ),
  ];

  runChordAnalyzerGoldenCases(cases);
}
