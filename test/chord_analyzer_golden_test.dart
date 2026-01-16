import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/theory/domain/theory_domain.dart';
import 'package:whatchord/features/theory/theory.dart';

/// Builds an [AnalysisContext] from a tonality, deriving key signature + default spelling policy.
AnalysisContext makeContext({
  Tonality tonality = const Tonality('C', TonalityMode.major),
  NoteSpellingPolicy? spellingPolicy,
}) {
  final ks = KeySignature.fromTonality(tonality);
  final policy =
      spellingPolicy ?? NoteSpellingPolicy(preferFlats: ks.prefersFlats);

  return AnalysisContext(
    tonality: tonality,
    keySignature: ks,
    spellingPolicy: policy,
  );
}

const defaultTonality = Tonality('C', TonalityMode.major);

int maskOf(Iterable<int> pcs) {
  var m = 0;
  for (final pc in pcs) {
    m |= (1 << (pc % 12));
  }
  return m;
}

int pc(String name) => pitchClassFromNoteName(name);

int maskOfNames(List<String> names) => maskOf(names.map(pc));

/// If the test name includes `-> SYMBOL`, treat that as the expected rendered symbol.
String expectedSymbolFromCaseName(String name) {
  final i = name.indexOf('->');
  return (i == -1) ? name : name.substring(i + 2).trim();
}

class GoldenCase {
  final String name;

  /// Pitch names like ["C", "E", "G", "Bb", "D"] (order is irrelevant for the mask).
  final List<String> pcs;

  /// Optional bass pitch name; defaults to first element of [pcs].
  final String? bass;

  /// Optional override; defaults to pcs.length.
  ///
  /// Use this to simulate octave duplications (e.g., power chord with doubled root).
  final int? noteCount;

  /// Optional per-case tonality override (defaults to C major).
  final Tonality? tonality;

  /// Optional override for the rendered symbol assertion.
  ///
  /// If omitted, we use the `-> ...` portion of [name] (when present), or [name] itself.
  final String? expectedSymbol;

  /// Additional structural assertions on the winning identity.
  final void Function(ChordIdentity top) expectTop;

  const GoldenCase({
    required this.name,
    required this.pcs,
    this.bass,
    this.noteCount,
    this.tonality,
    this.expectedSymbol,
    required this.expectTop,
  });
}

/// Small helper so each case reads as "notes -> expectation".
GoldenCase golden({
  required String name,
  required List<String> pcs,
  String? bass,
  int? noteCount,
  Tonality? tonality,
  String? expectedSymbol,
  required void Function(ChordIdentity top) expectTop,
}) {
  return GoldenCase(
    name: name,
    pcs: pcs,
    bass: bass,
    noteCount: noteCount,
    tonality: tonality,
    expectedSymbol: expectedSymbol,
    expectTop: expectTop,
  );
}

void main() {
  // Keep notation pinned for golden stability.
  const testNotation = ChordNotationStyle.textual;

  final cases = <GoldenCase>[
    // -------------------------------------------------------------------------
    // Major / dominant / extended tertian harmony
    // -------------------------------------------------------------------------

    // Major triad with an added 9 should not collapse to sus.
    golden(
      name: 'C E G D -> Cadd9',
      pcs: ['C', 'E', 'G', 'D'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.major);
        expect(top.extensions, contains(ChordExtension.add9));
      },
    ),

    // Straight dominant 7.
    golden(
      name: 'C E G Bb -> C7',
      pcs: ['C', 'E', 'G', 'Bb'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.dominant7);
        expect(top.extensions, isEmpty);
      },
    ),

    // Dominant 9.
    golden(
      name: 'C E G Bb D -> C9',
      pcs: ['C', 'E', 'G', 'Bb', 'D'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.dominant7);
        expect(top.extensions, contains(ChordExtension.nine));
      },
    ),

    // Major 9.
    golden(
      name: 'C E G B D -> Cmaj9',
      pcs: ['C', 'E', 'G', 'B', 'D'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.major7);
        expect(top.extensions, contains(ChordExtension.nine));
      },
    ),

    // 13th (as 7 + 9 + 13).
    golden(
      name: 'C E G Bb D A -> C13',
      pcs: ['C', 'E', 'G', 'Bb', 'D', 'A'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.dominant7);
        expect(
          top.extensions,
          containsAll(<ChordExtension>[
            ChordExtension.nine,
            ChordExtension.thirteen,
          ]),
        );
      },
    ),

    // -------------------------------------------------------------------------
    // Slash bass / inversions (explicit bass handling)
    // -------------------------------------------------------------------------

    // Same sonority as C9, but with a non-root bass should render a slash chord.
    golden(
      name: 'C E G Bb D --bass=G -> C9 / G',
      pcs: ['C', 'E', 'G', 'Bb', 'D'],
      bass: 'G',
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.bassPc, pc('G'));
        expect(top.quality, ChordQualityToken.dominant7);
      },
    ),

    // Major 6 in first inversion.
    golden(
      name: 'C E G A --bass=E -> C6 / E',
      pcs: ['C', 'E', 'G', 'A'],
      bass: 'E',
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.bassPc, pc('E'));
        expect(top.quality, ChordQualityToken.major6);
      },
    ),

    // -------------------------------------------------------------------------
    // Altered/colored dominants
    // -------------------------------------------------------------------------

    // Dominant b9.
    golden(
      name: 'C E G Bb Db -> C7b9',
      pcs: ['C', 'E', 'G', 'Bb', 'Db'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.dominant7);
        expect(top.extensions, contains(ChordExtension.flat9));
      },
    ),

    // Dominant b9 + #11.
    golden(
      name: 'C E G Bb Db F# -> C7(b9,#11)',
      pcs: ['C', 'E', 'G', 'Bb', 'Db', 'F#'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.dominant7);
        expect(
          top.extensions,
          containsAll(<ChordExtension>[
            ChordExtension.flat9,
            ChordExtension.sharp11,
          ]),
        );
      },
    ),

    // Dominant b9 + #11 + b13.
    golden(
      name: 'C E G Bb Db F# Ab -> C7(b9,#11,b13)',
      pcs: ['C', 'E', 'G', 'Bb', 'Db', 'F#', 'Ab'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.dominant7);
        expect(
          top.extensions,
          containsAll(<ChordExtension>[
            ChordExtension.flat9,
            ChordExtension.sharp11,
            ChordExtension.flat13,
          ]),
        );
      },
    ),

    // Dominant 7 suspended 4 with 9 should promote to the combined headline.
    golden(
      name: 'C F G Bb D -> C9sus4',
      pcs: ['C', 'F', 'G', 'Bb', 'D'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.dominant7sus4);
        expect(top.extensions, contains(ChordExtension.nine));
      },
    ),

    // -------------------------------------------------------------------------
    // Power chords and sus chords
    // -------------------------------------------------------------------------

    // Pure power chord.
    golden(
      name: 'C G -> C5',
      pcs: ['C', 'G'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.power5);
      },
    ),

    // Power chord with octave duplication: mask stays the same; noteCount changes.
    golden(
      name: 'C G C -> C5',
      pcs: ['C', 'G'],
      noteCount: 3,
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.power5);
      },
    ),

    // Power chord with added 4th: prefer sus4 headline.
    golden(
      name: 'C F G -> Csus4',
      pcs: ['C', 'F', 'G'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.sus4);
      },
    ),

    // Sus2 identification.
    golden(
      name: 'C D G -> Csus2',
      pcs: ['C', 'D', 'G'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.sus2);
      },
    ),

    // -------------------------------------------------------------------------
    // 6th-family + ranking interactions
    // -------------------------------------------------------------------------

    // Major 6.
    golden(
      name: 'C E G A -> C6',
      pcs: ['C', 'E', 'G', 'A'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.major6);
      },
    ),

    // Minor 6.
    golden(
      name: 'A C E F# -> Am6',
      pcs: ['A', 'C', 'E', 'F#'],
      expectTop: (top) {
        expect(top.rootPc, pc('A'));
        expect(top.quality, ChordQualityToken.minor6);
      },
    ),

    // 6/9 sonority: represented as major6 + add9 in this system.
    golden(
      name: 'C E G A D -> C6/9',
      pcs: ['C', 'E', 'G', 'A', 'D'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.major6);
        expect(top.extensions, contains(ChordExtension.add9));
      },
    ),

    // Dominant 7 should beat major 6 when the b7 is present.
    golden(
      name: 'C E G Bb A -> C13',
      pcs: ['C', 'E', 'G', 'Bb', 'A'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.dominant7);
        expect(top.extensions, contains(ChordExtension.thirteen));
      },
    ),

    // 6th-family should beat 7th-family when the 7 is missing.
    golden(
      name: 'G Bb D E -> Gm6',
      pcs: ['G', 'Bb', 'D', 'E'],
      expectTop: (top) {
        expect(top.rootPc, pc('G'));
        expect(top.quality, ChordQualityToken.minor6);
      },
    ),

    // Tonality-specific ranking: same pitch-class set, different "best" chord in A minor.
    golden(
      name: 'C E G A D --key=A:min -> Am11 / C',
      pcs: ['C', 'E', 'G', 'A', 'D'],
      tonality: const Tonality('A', TonalityMode.minor),
      expectTop: (top) {
        expect(top.rootPc, pc('A'));
        expect(top.quality, ChordQualityToken.minor7);
        expect(top.extensions, contains(ChordExtension.eleven));
        expect(top.bassPc, pc('C'));
      },
    ),

    // -------------------------------------------------------------------------
    // Diminished-family (half-diminished and diminished7)
    // -------------------------------------------------------------------------

    // Half-diminished 7th (m7b5).
    golden(
      name: 'B D F A -> Bm7(b5)',
      pcs: ['B', 'D', 'F', 'A'],
      expectTop: (top) {
        expect(top.rootPc, pc('B'));
        expect(top.quality, ChordQualityToken.halfDiminished7);
      },
    ),

    // Half-diminished headline promotion with a 9 extension.
    golden(
      name: 'C Eb Gb Bb D -> Cm9(b5)',
      pcs: ['C', 'Eb', 'Gb', 'Bb', 'D'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.halfDiminished7);
        expect(top.extensions, contains(ChordExtension.nine));
      },
    ),

    // Diminished seventh with color tones: verify extension mapping stays stable.
    golden(
      name: 'C Eb Gb A D -> Cdim7(add9)',
      pcs: ['C', 'Eb', 'Gb', 'A', 'D'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.diminished7);
        expect(top.extensions, contains(ChordExtension.nine));
      },
    ),
    golden(
      name: 'C Eb Gb A F -> Cdim7(add11)',
      pcs: ['C', 'Eb', 'Gb', 'A', 'F'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.diminished7);
        expect(top.extensions, contains(ChordExtension.eleven));
      },
    ),
    golden(
      name: 'C Eb Gb A Ab -> Cdim7(b13)',
      pcs: ['C', 'Eb', 'Gb', 'A', 'Ab'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.diminished7);
        expect(top.extensions, contains(ChordExtension.flat13));
      },
    ),
    golden(
      name: 'C Eb Gb A Db -> Cdim7(b9)',
      pcs: ['C', 'Eb', 'Gb', 'A', 'Db'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.diminished7);
        expect(top.extensions, contains(ChordExtension.flat9));
      },
    ),

    // -------------------------------------------------------------------------
    // Enharmonic spelling edge cases (key signature should influence letter names)
    // -------------------------------------------------------------------------

    // In F# major (6 sharps), we should prefer E# over F for the leading tone triad.
    golden(
      name: 'E# G# B --key=F#:maj -> E#dim',
      pcs: ['E#', 'G#', 'B'],
      tonality: const Tonality('F#', TonalityMode.major),
      expectTop: (top) {
        expect(top.rootPc, pc('E#')); // pc('E#') == pc('F')
        expect(top.quality, ChordQualityToken.diminished);
      },
    ),

    // In Cb major (7 flats), we should prefer Fb over E for the subdominant chord.
    golden(
      name: 'Fb Ab Cb --key=Cb:maj -> Fb',
      pcs: ['Fb', 'Ab', 'Cb'],
      tonality: const Tonality('Cb', TonalityMode.major),
      expectTop: (top) {
        expect(top.rootPc, pc('Fb')); // pc('Fb') == pc('E')
        expect(top.quality, ChordQualityToken.major);
      },
    ),

    // -------------------------------------------------------------------------
    // Tonality bias vs chord-structure evidence (spelling/context disambiguation)
    // -------------------------------------------------------------------------

    // Diminished context: interpret Gb as b5 (not F# as #11) when structure supports dim.
    golden(
      name: 'Gb C Eb -> Cdim / Gb',
      pcs: ['Gb', 'C', 'Eb'],
      tonality: const Tonality('D', TonalityMode.major), // sharp-leaning
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.diminished);
        expect(top.bassPc, pc('Gb'));
      },
    ),

    // Dominant altered context: interpret F# as #11 (not Gb as b5) when structure supports 7#11.
    golden(
      name: 'F# C E Bb -> C7#11 / F#',
      pcs: ['F#', 'C', 'E', 'Bb'],
      tonality: const Tonality('Db', TonalityMode.major), // flat-leaning
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.dominant7);
        expect(top.extensions, contains(ChordExtension.sharp11));
        expect(top.bassPc, pc('F#'));
      },
    ),

    // Same pitch classes, different key: should not flip when chord-structure evidence is strong.
    golden(
      name: 'Gb C E Bb --key=Gb:maj -> C7#11 / F#',
      pcs: ['Gb', 'C', 'E', 'Bb'],
      tonality: const Tonality('Gb', TonalityMode.major),
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.dominant7);
        expect(top.extensions, contains(ChordExtension.sharp11));
        expect(top.bassPc, pc('F#'));
      },
    ),

    // -------------------------------------------------------------------------
    // Shells / compact voicings
    // -------------------------------------------------------------------------

    // Minor-major 7 shell (no fifth).
    golden(
      name: 'C Eb B -> Cm(maj7)',
      pcs: ['C', 'Eb', 'B'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.minorMajor7);
      },
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
    //   expectTop: (top) {
    //     expect(top.rootPc, pc('C'));
    //     expect(top.quality, ChordQualityToken.minor);
    //   },
    // ),
  ];

  for (final c in cases) {
    test(c.name, () {
      final bassPc = pc(c.bass ?? c.pcs.first);
      final count = c.noteCount ?? c.pcs.length;

      final input = ChordInput(
        pcMask: maskOfNames(c.pcs),
        bassPc: bassPc,
        noteCount: count,
      );

      final tonality = c.tonality ?? defaultTonality;
      final ctx = makeContext(tonality: tonality);
      final results = ChordAnalyzer.analyze(input, context: ctx);

      expect(results, isNotEmpty, reason: 'No candidates returned');
      final top = results.first.identity;

      final actualSymbol = ChordSymbolBuilder.fromIdentity(
        identity: top,
        tonality: tonality,
        notation: testNotation,
      ).toString();

      final expectedSymbol =
          c.expectedSymbol ?? expectedSymbolFromCaseName(c.name);

      expect(actualSymbol, expectedSymbol, reason: 'Rendered symbol mismatch');

      try {
        c.expectTop(top);
      } on TestFailure catch (e) {
        fail(
          [
            'Expected chord: $expectedSymbol',
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
