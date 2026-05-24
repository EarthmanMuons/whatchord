import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/theory/theory.dart';

import 'helpers/theory_test_helpers.dart';

class GoldenCase {
  final String name;

  /// Pitch names like ["C", "E", "G", "Bb", "D"] (order is irrelevant for the mask).
  final List<String> pcs;

  /// Optional bass pitch name; defaults to first element of [pcs].
  final String? bass;

  /// Optional override; defaults to pcs.length.
  ///
  /// Use this to simulate octave duplications.
  final int? noteCount;

  /// Optional per-case tonality override (defaults to C major).
  final Tonality? tonality;

  /// Expected rendered symbol.
  final String expectedSymbol;

  /// Expected winning root pitch name.
  final String? expectedRoot;

  /// Expected winning bass pitch name. Defaults to [bass] when omitted.
  final String? expectedBass;

  /// Expected winning quality.
  final ChordQualityToken? expectedQuality;

  /// Extensions that must appear on the winning identity.
  final Set<ChordExtension> expectedExtensions;

  /// Whether the winning identity must have no extensions.
  final bool expectNoExtensions;

  /// Extensions that must not appear on the winning identity.
  final Set<ChordExtension> unexpectedExtensions;

  /// Tone roles that must appear at specific intervals on the winning identity.
  final Map<int, ChordToneRole> expectedToneRolesByInterval;

  const GoldenCase({
    required this.name,
    required this.expectedSymbol,
    required this.pcs,
    this.bass,
    this.noteCount,
    this.tonality,
    this.expectedRoot,
    this.expectedBass,
    this.expectedQuality,
    this.expectedExtensions = const {},
    this.expectNoExtensions = false,
    this.unexpectedExtensions = const {},
    this.expectedToneRolesByInterval = const {},
  });
}

/// Small helper so each case reads as "notes -> expectation".
GoldenCase golden({
  required String name,
  required String expectedSymbol,
  required List<String> pcs,
  String? bass,
  int? noteCount,
  Tonality? tonality,
  String? expectedRoot,
  String? expectedBass,
  ChordQualityToken? expectedQuality,
  Set<ChordExtension> expectedExtensions = const {},
  bool expectNoExtensions = false,
  Set<ChordExtension> unexpectedExtensions = const {},
  Map<int, ChordToneRole> expectedToneRolesByInterval = const {},
}) {
  return GoldenCase(
    name: name,
    expectedSymbol: expectedSymbol,
    pcs: pcs,
    bass: bass,
    noteCount: noteCount,
    tonality: tonality,
    expectedRoot: expectedRoot,
    expectedBass: expectedBass,
    expectedQuality: expectedQuality,
    expectedExtensions: expectedExtensions,
    expectNoExtensions: expectNoExtensions,
    unexpectedExtensions: unexpectedExtensions,
    expectedToneRolesByInterval: expectedToneRolesByInterval,
  );
}

void main() {
  // Keep notation pinned for golden stability.
  const testNotation = ChordNotationStyle.textual;

  final cases = <GoldenCase>[
    // -------------------------------------------------------------------------
    // Major / dominant / extended tertian harmony
    // -------------------------------------------------------------------------

    // Plain major triad should not be displaced by remote m#5.
    golden(
      name: 'C E G -> C',
      expectedSymbol: 'C',
      pcs: ['C', 'E', 'G'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.major,
    ),

    // Major triad with an added 9 should not be displaced by remote m7#5.
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
    // 6th-family + ranking interactions
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

    // -------------------------------------------------------------------------
    // (Intentionally excluded / future work)
    // -------------------------------------------------------------------------
    //
    // // Minor vs major third contradiction
    // // This is useful as a "known hard" case, but should remain commented until
    // // you decide the intended UX and scoring behavior.
    // golden(
    //   name: 'C Eb E G -> ???',
    //   pcs: ['C', 'Eb', 'E', 'G'],
    //   expectedRoot: 'C',
    //   expectedQuality: ChordQualityToken.minor,
    // ),
  ];

  for (final c in cases) {
    test(c.name, () {
      final input = chordInputFromNames(
        names: c.pcs,
        bass: c.bass,
        noteCount: c.noteCount,
      );

      final count = input.noteCount;
      final tonality = c.tonality ?? defaultTestTonality;
      final ctx = makeAnalysisContext(tonality: tonality);
      final results = ChordAnalyzer.analyze(input, context: ctx);

      expect(results, isNotEmpty, reason: 'No candidates returned');
      final top = results.first.identity;

      final actualSymbol = ChordSymbolBuilder.fromIdentity(
        identity: top,
        tonality: tonality,
        notation: testNotation,
      ).toString();

      expect(
        actualSymbol,
        c.expectedSymbol,
        reason: 'Rendered symbol mismatch',
      );

      try {
        expectTopIdentity(top, c);
      } on TestFailure catch (e) {
        fail(
          [
            'Expected chord: ${c.expectedSymbol}',
            '  Actual chord: $actualSymbol',
            '      Tonality: ${tonality.tonic} ${tonality.mode.name}',
            '         Notes: ${c.pcs.join(" ")}',
            '          Bass: ${c.bass ?? c.pcs.first}',
            '     NoteCount: $count',
            '',
            'Original failure:',
            e.message ?? e.toString(),
          ].join('\n'),
        );
      }
    });
  }
}

void expectTopIdentity(ChordIdentity top, GoldenCase c) {
  if (c.expectedRoot != null) {
    expect(top.rootPc, pc(c.expectedRoot!));
  }
  final expectedBass = c.expectedBass ?? c.bass;
  if (expectedBass != null) {
    expect(top.bassPc, pc(expectedBass));
  }
  if (c.expectedQuality != null) {
    expect(top.quality, c.expectedQuality);
  }
  if (c.expectNoExtensions) {
    expect(top.extensions, isEmpty);
  }
  for (final extension in c.expectedExtensions) {
    expect(top.extensions, contains(extension));
  }
  for (final extension in c.unexpectedExtensions) {
    expect(top.extensions, isNot(contains(extension)));
  }
  for (final entry in c.expectedToneRolesByInterval.entries) {
    expect(top.toneRolesByInterval[entry.key], entry.value);
  }
}
