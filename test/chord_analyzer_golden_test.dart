import 'package:flutter_test/flutter_test.dart';
import 'package:what_chord/features/theory/services/chord_symbol_builder.dart';

import 'package:what_chord/features/theory/theory.dart';

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

String expectedSymbolFromCaseName(String name) {
  final i = name.indexOf('->');
  return (i == -1) ? name : name.substring(i + 2).trim();
}

class GoldenCase {
  final String name;

  /// Pitch names like ["C", "E", "G", "Bb", "D"]
  final List<String> pcs;

  /// Optional bass pitch name; defaults to first pc.
  final String? bass;

  /// Optional override; defaults to pcs.length.
  final int? noteCount;

  /// Optional per-case tonality override (defaults to C major).
  final Tonality? tonality;

  /// Optional, when set, assert against the rendered symbol (enharmonic spelling included).
  final String? expectedSymbol;

  /// Assert against the winning identity.
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

void main() {
  final cases = <GoldenCase>[
    GoldenCase(
      name: 'C E G D -> Cadd9', // not sus
      pcs: ['C', 'E', 'G', 'D'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.major);
        expect(top.extensions, contains(ChordExtension.add9));
      },
    ),
    GoldenCase(
      name: 'C E G Bb -> C7',
      pcs: ['C', 'E', 'G', 'Bb'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.dominant7);
        expect(top.extensions, isEmpty);
      },
    ),
    GoldenCase(
      name: 'C E G Bb D -> C9',
      pcs: ['C', 'E', 'G', 'Bb', 'D'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.dominant7);
        expect(top.extensions, contains(ChordExtension.nine));
      },
    ),
    GoldenCase(
      name: 'C E G B D -> Cmaj9',
      pcs: ['C', 'E', 'G', 'B', 'D'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.major7);
        expect(top.extensions, contains(ChordExtension.nine));
      },
    ),
    GoldenCase(
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
    GoldenCase(
      name: 'C E G Bb D --bass=G -> C9 / G',
      pcs: ['C', 'E', 'G', 'Bb', 'D'],
      bass: 'G',
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.bassPc, pc('G'));
        expect(top.quality, ChordQualityToken.dominant7);
      },
    ),
    GoldenCase(
      name: 'C E G Bb Db -> C7b9',
      pcs: ['C', 'E', 'G', 'Bb', 'Db'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.dominant7);
        expect(top.extensions, contains(ChordExtension.flat9));
      },
    ),
    GoldenCase(
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
    GoldenCase(
      name: 'B D F A -> Bm7(b5)',
      pcs: ['B', 'D', 'F', 'A'],
      expectTop: (top) {
        expect(top.rootPc, pc('B'));
        expect(top.quality, ChordQualityToken.halfDiminished7);
      },
    ),
    // Pure power chord
    GoldenCase(
      name: 'C G -> C5',
      pcs: ['C', 'G'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.power5);
      },
    ),
    // Power chord with octave duplication
    GoldenCase(
      name: 'C G C -> C5',
      pcs: ['C', 'G'],
      noteCount: 3,
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.power5);
      },
    ),
    // Power chord with added 4th
    GoldenCase(
      name: 'C F G -> Csus4', // or C5add11 (depending on intended UX)
      pcs: ['C', 'F', 'G'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.sus4);
      },
    ),
    // Major 6
    GoldenCase(
      name: 'C E G A -> C6',
      pcs: ['C', 'E', 'G', 'A'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.major6);
      },
    ),
    // 6 chord with inversion
    GoldenCase(
      name: 'C E G A --bass=E -> C6 / E',
      pcs: ['C', 'E', 'G', 'A'],
      bass: 'E',
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.bassPc, pc('E'));
        expect(top.quality, ChordQualityToken.major6);
      },
    ),
    // Minor 6
    GoldenCase(
      name: 'A C E F# -> Am6',
      pcs: ['A', 'C', 'E', 'F#'],
      expectTop: (top) {
        expect(top.rootPc, pc('A'));
        expect(top.quality, ChordQualityToken.minor6);
      },
    ),
    // 6/9 sonority
    GoldenCase(
      name: 'C E G A D -> C6/9',
      pcs: ['C', 'E', 'G', 'A', 'D'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.major6);
        expect(top.extensions, contains(ChordExtension.add9));
      },
    ),
    // Tonality-specific ranking
    GoldenCase(
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
    // Dominant 7 should beat major 6 when the 7 is present
    GoldenCase(
      name: 'C E G Bb A -> C13',
      pcs: ['C', 'E', 'G', 'Bb', 'A'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.dominant7);
        expect(top.extensions, contains(ChordExtension.thirteen));
      },
    ),
    // 6th-family should beat 7th-family when the 7 is missing
    GoldenCase(
      name: 'G Bb D E -> Gm6',
      pcs: ['G', 'Bb', 'D', 'E'],
      expectTop: (top) {
        expect(top.rootPc, pc('G'));
        expect(top.quality, ChordQualityToken.minor6);
      },
    ),
    // Major vs sus2
    GoldenCase(
      name: 'C D G -> Csus2',
      pcs: ['C', 'D', 'G'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.sus2);
      },
    ),
    // Enharmonic symbols 6 sharps
    GoldenCase(
      name: 'E# G# B --key=F#:maj -> E#dim',
      pcs: ['E#', 'G#', 'B'],
      tonality: const Tonality('F#', TonalityMode.major),
      expectedSymbol: 'E#dim',
      expectTop: (top) {
        expect(top.rootPc, pc('E#')); // pc('E#') == pc('F')
        expect(top.quality, ChordQualityToken.diminished);
      },
    ),
    // Enharmonic symbols 7 flats
    GoldenCase(
      name: 'Fb Ab Cb --key=Cb:maj -> Fb',
      pcs: ['Fb', 'Ab', 'Cb'],
      tonality: const Tonality('Cb', TonalityMode.major),
      expectedSymbol: 'Fb',
      expectTop: (top) {
        expect(top.rootPc, pc('Fb')); // pc('Fb') == pc('E')
        expect(top.quality, ChordQualityToken.major);
      },
    ),

    // // Minor vs major third contradiction
    // GoldenCase(
    //   name: 'C Eb E G -> ???', // Eb6(b9) / C or Cm
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

      const testNotation = ChordNotationStyle.leadSheet;

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
            '',
            'Original failure:',
            e.message ?? e.toString(),
          ].join('\n'),
        );
      }
    });
  }
}
