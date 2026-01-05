import 'package:flutter_test/flutter_test.dart';
import 'package:what_chord/features/theory/engine/engine.dart';

int maskOf(Iterable<int> pcs) {
  var m = 0;
  for (final pc in pcs) {
    m |= (1 << (pc % 12));
  }
  return m;
}

/// Parse simple pitch-class spellings like:
/// C, C#, Db, Bb, F#, etc.
/// (Single accidental only; extend later if needed.)
int pc(String name) {
  final s = name.trim().toUpperCase();
  if (s.isEmpty) throw ArgumentError('Empty pitch name');

  const base = <String, int>{
    'C': 0,
    'D': 2,
    'E': 4,
    'F': 5,
    'G': 7,
    'A': 9,
    'B': 11,
  };

  final letter = s[0];
  final n0 = base[letter];
  if (n0 == null) throw ArgumentError('Bad pitch letter: $name');

  var n = n0;
  final rest = s.substring(1);

  if (rest.isEmpty) return n;

  if (rest == 'B') {
    // flat
    n = (n - 1) % 12;
  } else if (rest == '#') {
    // sharp
    n = (n + 1) % 12;
  } else {
    throw ArgumentError('Unsupported accidental in: $name');
  }

  return n < 0 ? n + 12 : n;
}

int maskOfNames(List<String> names) => maskOf(names.map(pc));

class GoldenCase {
  final String name;

  /// Pitch names like ["C", "E", "G", "Bb", "D"]
  final List<String> pcs;

  /// Optional bass pitch name; defaults to first pc.
  final String? bass;

  /// Optional override; defaults to pcs.length.
  final int? noteCount;

  /// Assert against the winning identity.
  final void Function(ChordIdentity top) expectTop;

  const GoldenCase({
    required this.name,
    required this.pcs,
    this.bass,
    this.noteCount,
    required this.expectTop,
  });
}

void main() {
  final cases = <GoldenCase>[
    GoldenCase(
      name: 'C E G D -> C add9 (not sus)',
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
      name: 'C E G Bb D with bass G -> C9 / G',
      pcs: ['C', 'E', 'G', 'Bb', 'D'],
      bass: 'G',
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.bassPc, pc('G'));
        expect(top.quality, ChordQualityToken.dominant7);
      },
    ),
    GoldenCase(
      name: 'C E G Bb Db -> C7(b9)',
      pcs: ['C', 'E', 'G', 'Bb', 'Db'],
      expectTop: (top) {
        expect(top.rootPc, pc('C'));
        expect(top.quality, ChordQualityToken.dominant7);
        expect(top.extensions, contains(ChordExtension.flat9));
      },
    ),
    GoldenCase(
      name: 'B D F A -> Bø7',
      pcs: ['B', 'D', 'F', 'A'],
      expectTop: (top) {
        expect(top.rootPc, pc('B'));
        expect(top.quality, ChordQualityToken.halfDiminished7);
      },
    ),
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

      final results = ChordAnalyzer.analyze(input);
      expect(results, isNotEmpty, reason: 'No candidates returned');

      final top = results.first.identity;
      c.expectTop(top);
    });
  }
}
