import 'package:whatchord/features/theory/theory.dart';

import 'helpers/chord_analyzer_golden_helpers.dart';

void main() {
  final cases = <GoldenCase>[
    // -------------------------------------------------------------------------
    // Major / dominant / extended tertian harmony
    // -------------------------------------------------------------------------

    // Plain major triad.
    golden(
      name: 'C E G -> C',
      expectedSymbol: 'C',
      pcs: ['C', 'E', 'G'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major,
    ),

    // Major triad with an added 9.
    golden(
      name: 'C E G D -> Cadd9',
      expectedSymbol: 'Cadd9',
      pcs: ['C', 'E', 'G', 'D'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major,
      expectedExtensions: {ChordExtension.add9},
    ),

    // Straight dominant 7.
    golden(
      name: 'C E G Bb -> C7',
      expectedSymbol: 'C7',
      pcs: ['C', 'E', 'G', 'Bb'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7,
      expectNoExtensions: true,
    ),

    // Dominant 9.
    golden(
      name: 'C E G Bb D -> C9',
      expectedSymbol: 'C9',
      pcs: ['C', 'E', 'G', 'Bb', 'D'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.nine},
    ),

    // A lone 11 on a dominant seventh is an added tone, not a true 11th chord.
    golden(
      name: 'C E G Bb F -> C7(add11)',
      expectedSymbol: 'C7(add11)',
      pcs: ['C', 'E', 'G', 'Bb', 'F'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.add11},
      unexpectedExtensions: {ChordExtension.eleven},
    ),

    // A true dominant 11 includes the implied ninth.
    golden(
      name: 'C E G Bb D F -> C11',
      expectedSymbol: 'C11',
      pcs: ['C', 'E', 'G', 'Bb', 'D', 'F'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.nine, ChordExtension.eleven},
    ),

    // Major 9.
    golden(
      name: 'C E G B D -> Cmaj9',
      expectedSymbol: 'Cmaj9',
      pcs: ['C', 'E', 'G', 'B', 'D'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major7,
      expectedExtensions: {ChordExtension.nine},
    ),

    // 13th (as 7 + 9 + 13).
    golden(
      name: 'C E G Bb D A -> C13',
      expectedSymbol: 'C13',
      pcs: ['C', 'E', 'G', 'Bb', 'D', 'A'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.nine, ChordExtension.thirteen},
    ),

    // The fifth is optional in extended dominant voicings.
    golden(
      name: 'C E Bb D F# A -> C13#11',
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
      name: 'C E G Bb D --bass=G -> C9 / G',
      expectedSymbol: 'C9 / G',
      pcs: ['C', 'E', 'G', 'Bb', 'D'],
      bass: 'G',
      expectedRoot: 'C',
      expectedBass: 'G',
      expectedQuality: ChordQualityToken.dominant7,
    ),

    // Major 6 in first inversion.
    golden(
      name: 'C E G A --bass=E -> C6 / E',
      expectedSymbol: 'C6 / E',
      pcs: ['C', 'E', 'G', 'A'],
      bass: 'E',
      expectedRoot: 'C',
      expectedBass: 'E',
      expectedQuality: ChordQualityToken.major6,
    ),

    // Root-position 6(no5) with a doubled root remains a legitimate 6th chord.
    golden(
      name: 'C E A C -> C6',
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

    // Dominant b9.
    golden(
      name: 'C E G Bb Db -> C7b9',
      expectedSymbol: 'C7b9',
      pcs: ['C', 'E', 'G', 'Bb', 'Db'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.flat9},
    ),

    // Hendrix chord: dominant shell plus #9 should not be treated as a minor-third penalty.
    golden(
      name: 'G B D F A# -> G7#9',
      expectedSymbol: 'G7#9',
      pcs: ['G', 'B', 'D', 'F', 'A#'],
      expectedRoot: 'G',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.sharp9},
    ),

    // Dominant b9 + #11.
    golden(
      name: 'C E G Bb Db F# -> C7(b9,#11)',
      expectedSymbol: 'C7(b9,#11)',
      pcs: ['C', 'E', 'G', 'Bb', 'Db', 'F#'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7,
      expectedExtensions: {ChordExtension.flat9, ChordExtension.sharp11},
    ),

    // Dominant b9 + #11 + b13.
    golden(
      name: 'C E G Bb Db F# Ab -> C7(b9,#11,b13)',
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
      name: 'C F G Bb D -> C9sus4',
      expectedSymbol: 'C9sus4',
      pcs: ['C', 'F', 'G', 'Bb', 'D'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7sus4,
      expectedExtensions: {ChordExtension.nine},
    ),

    // Dominant 7 suspended 2.
    golden(
      name: 'C D G Bb -> C7sus2',
      expectedSymbol: 'C7sus2',
      pcs: ['C', 'D', 'G', 'Bb'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7sus2,
    ),

    // Major 7 suspended 2.
    golden(
      name: 'C D G B -> Cmaj7sus2',
      expectedSymbol: 'Cmaj7sus2',
      pcs: ['C', 'D', 'G', 'B'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major7sus2,
    ),

    // Major 7 suspended 4.
    golden(
      name: 'C F G B -> Cmaj7sus4',
      expectedSymbol: 'Cmaj7sus4',
      pcs: ['C', 'F', 'G', 'B'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major7sus4,
    ),

    // Dominant 7 sharp 5 should treat the augmented fifth as a core tone.
    golden(
      name: 'C E G# Bb -> C7#5',
      expectedSymbol: 'C7#5',
      pcs: ['C', 'E', 'G#', 'Bb'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7Sharp5,
      expectedToneRolesByInterval: {8: ChordToneRole.sharp5},
    ),

    // Minor sharp 5 should treat the augmented fifth as a core tone.
    golden(
      name: 'C Eb G# -> Cm#5',
      expectedSymbol: 'Cm#5',
      pcs: ['C', 'Eb', 'G#'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.minorSharp5,
      expectedToneRolesByInterval: {8: ChordToneRole.sharp5},
    ),

    // Minor 7 sharp 5 should treat the augmented fifth as a core tone.
    golden(
      name: 'C Eb G# Bb -> Cm7#5',
      expectedSymbol: 'Cm7#5',
      pcs: ['C', 'Eb', 'G#', 'Bb'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.minor7Sharp5,
      expectedToneRolesByInterval: {8: ChordToneRole.sharp5},
    ),

    // Dominant 7 flat 5 should treat the diminished fifth as a core tone.
    golden(
      name: 'C E Gb Bb -> C7b5',
      expectedSymbol: 'C7b5',
      pcs: ['C', 'E', 'Gb', 'Bb'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7Flat5,
      expectedToneRolesByInterval: {6: ChordToneRole.flat5},
    ),

    // Major 7 sharp 5 should treat the augmented fifth as a core tone.
    golden(
      name: 'C E G# B -> Cmaj7#5',
      expectedSymbol: 'Cmaj7#5',
      pcs: ['C', 'E', 'G#', 'B'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major7Sharp5,
      expectedToneRolesByInterval: {8: ChordToneRole.sharp5},
    ),

    // Major 7 flat 5 should treat the diminished fifth as a core tone.
    golden(
      name: 'C E Gb B -> Cmaj7b5',
      expectedSymbol: 'Cmaj7b5',
      pcs: ['C', 'E', 'Gb', 'B'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major7Flat5,
      expectedToneRolesByInterval: {6: ChordToneRole.flat5},
    ),

    // Altered augmented dominants keep both the #5 core tone and #9 color.
    golden(
      name: 'C E G# Bb D# -> C7#5#9',
      expectedSymbol: 'C7#5#9',
      pcs: ['C', 'E', 'G#', 'Bb', 'D#'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.dominant7Sharp5,
      expectedExtensions: {ChordExtension.sharp9},
      expectedToneRolesByInterval: {8: ChordToneRole.sharp5},
    ),

    // Altered flat-five dominants keep both the b5 core tone and #9 color.
    golden(
      name: 'C E Gb Bb D# -> C7b5#9',
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

    // Sus4 identification.
    golden(
      name: 'C F G -> Csus4',
      expectedSymbol: 'Csus4',
      pcs: ['C', 'F', 'G'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.sus4,
    ),

    // Sus2 identification.
    golden(
      name: 'C D G -> Csus2',
      expectedSymbol: 'Csus2',
      pcs: ['C', 'D', 'G'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.sus2,
    ),

    // -------------------------------------------------------------------------
    // 6th-family
    // -------------------------------------------------------------------------

    // Major 6.
    golden(
      name: 'C E G A -> C6',
      expectedSymbol: 'C6',
      pcs: ['C', 'E', 'G', 'A'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major6,
    ),

    // Minor 6.
    golden(
      name: 'A C E F# -> Am6',
      expectedSymbol: 'Am6',
      pcs: ['A', 'C', 'E', 'F#'],
      expectedRoot: 'A',
      expectedQuality: ChordQualityToken.minor6,
    ),

    // 6/9 sonority: represented as major6 + add9 in this system.
    golden(
      name: 'C E G A D -> C6/9',
      expectedSymbol: 'C6/9',
      pcs: ['C', 'E', 'G', 'A', 'D'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major6,
      expectedExtensions: {ChordExtension.add9},
    ),

    // Dominant 7 with a lone 13 is an added tone, not a true 13th chord.
    golden(
      name: 'C E G Bb A -> C7(add13)',
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

    // Half-diminished 7th (m7b5).
    golden(
      name: 'B D F A -> Bm7(b5)',
      expectedSymbol: 'Bm7(b5)',
      pcs: ['B', 'D', 'F', 'A'],
      expectedRoot: 'B',
      expectedQuality: ChordQualityToken.halfDiminished7,
    ),

    // Half-diminished headline promotion with a 9 extension.
    golden(
      name: 'C Eb Gb Bb D -> Cm9(b5)',
      expectedSymbol: 'Cm9(b5)',
      pcs: ['C', 'Eb', 'Gb', 'Bb', 'D'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.halfDiminished7,
      expectedExtensions: {ChordExtension.nine},
    ),

    // Diminished seventh with color tones: verify extension mapping stays stable.
    golden(
      name: 'C Eb Gb A D -> Cdim7(add9)',
      expectedSymbol: 'Cdim7(add9)',
      pcs: ['C', 'Eb', 'Gb', 'A', 'D'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.diminished7,
      expectedExtensions: {ChordExtension.nine},
    ),
    golden(
      name: 'C Eb Gb A F -> Cdim7(add11)',
      expectedSymbol: 'Cdim7(add11)',
      pcs: ['C', 'Eb', 'Gb', 'A', 'F'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.diminished7,
      expectedExtensions: {ChordExtension.add11},
    ),
    golden(
      name: 'C Eb Gb A Ab -> Cdim7(b13)',
      expectedSymbol: 'Cdim7(b13)',
      pcs: ['C', 'Eb', 'Gb', 'A', 'Ab'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.diminished7,
      expectedExtensions: {ChordExtension.flat13},
    ),
    golden(
      name: 'C Eb Gb A Db -> Cdim7(b9)',
      expectedSymbol: 'Cdim7(b9)',
      pcs: ['C', 'Eb', 'Gb', 'A', 'Db'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.diminished7,
      expectedExtensions: {ChordExtension.flat9},
    ),

    // -------------------------------------------------------------------------
    // Shells / compact voicings
    // -------------------------------------------------------------------------

    // Minor-major 7 shell (no fifth).
    golden(
      name: 'C Eb B -> Cm(maj7)',
      expectedSymbol: 'Cm(maj7)',
      pcs: ['C', 'Eb', 'B'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.minorMajor7,
    ),
  ];

  runChordAnalyzerGoldenCases(cases);
}
