import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/theory/domain/theory_domain.dart';

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

int pc(String name) => pitchClassFromNoteName(name);

int maskOf(Iterable<int> pcs) {
  var m = 0;
  for (final p in pcs) {
    m |= (1 << (p % 12));
  }
  return m;
}

int maskOfNames(List<String> names) => maskOf(names.map(pc));

class ScaleDegreeCase {
  final String name;
  final List<String> pcs;
  final String? bass;
  final int? noteCount;
  final Tonality tonality;

  /// Expected strict degree (null = not diatonic under strict rules).
  final ScaleDegree? expectedDegree;

  /// Sanity-check the winning chord identity.
  final void Function(ChordIdentity top)? expectTop;

  const ScaleDegreeCase({
    required this.name,
    required this.pcs,
    this.bass,
    this.noteCount,
    required this.tonality,
    required this.expectedDegree,
    this.expectTop,
  });
}

ScaleDegreeCase deg({
  required String name,
  required List<String> pcs,
  String? bass,
  int? noteCount,
  Tonality tonality = const Tonality('C', TonalityMode.major),
  required ScaleDegree? expected,
  void Function(ChordIdentity top)? expectTop,
}) {
  return ScaleDegreeCase(
    name: name,
    pcs: pcs,
    bass: bass,
    noteCount: noteCount,
    tonality: tonality,
    expectedDegree: expected,
    expectTop: expectTop,
  );
}

void main() {
  final cases = <ScaleDegreeCase>[
    // -------------------------
    // C major: triads + 7ths
    // -------------------------
    deg(
      name: 'C E G in C major => I',
      pcs: ['C', 'E', 'G'],
      expected: ScaleDegree.one,
    ),
    deg(
      name: 'C E G B in C major => I (maj7)',
      pcs: ['C', 'E', 'G', 'B'],
      expected: ScaleDegree.one,
      expectTop: (top) => expect(top.quality, ChordQualityToken.major7),
    ),
    deg(
      name: 'D F A in C major => ii',
      pcs: ['D', 'F', 'A'],
      expected: ScaleDegree.two,
    ),
    deg(
      name: 'D F A C in C major => ii (m7)',
      pcs: ['D', 'F', 'A', 'C'],
      expected: ScaleDegree.two,
      expectTop: (top) => expect(top.quality, ChordQualityToken.minor7),
    ),
    deg(
      name: 'G B D F in C major => V (dom7)',
      pcs: ['G', 'B', 'D', 'F'],
      expected: ScaleDegree.five,
      expectTop: (top) => expect(top.quality, ChordQualityToken.dominant7),
    ),
    deg(
      name: 'B D F A in C major => vii° (ø7)',
      pcs: ['B', 'D', 'F', 'A'],
      expected: ScaleDegree.seven,
      expectTop: (top) =>
          expect(top.quality, ChordQualityToken.halfDiminished7),
    ),

    // -------------------------
    // Strict exclusions
    // -------------------------

    // Suspensions / power chords: strict classifier returns null.
    deg(
      name: 'C G in C major => null (power chord)',
      pcs: ['C', 'G'],
      expected: null,
      expectTop: (top) => expect(top.quality, ChordQualityToken.power5),
    ),
    deg(
      name: 'C F G in C major => null (sus4)',
      pcs: ['C', 'F', 'G'],
      expected: null,
      expectTop: (top) => expect(top.quality, ChordQualityToken.sus4),
    ),

    // Altered dominants are non-diatonic under natural major/minor strictness.
    deg(
      name: 'C E G Bb Db in C major => null (V7b9 is chromatic)',
      pcs: ['C', 'E', 'G', 'Bb', 'Db'],
      expected: null,
      expectTop: (top) {
        expect(top.quality, ChordQualityToken.dominant7);
        expect(top.extensions, contains(ChordExtension.flat9));
      },
    ),

    // 6th chords: allowed only when chord-member tones are diatonic (strict).
    deg(
      name: 'C E G A in C major => I (C6 treated as added-sixth)',
      pcs: ['C', 'E', 'G', 'A'],
      expected: ScaleDegree.one,
      expectTop: (top) => expect(top.quality, ChordQualityToken.major6),
    ),
    deg(
      name: 'A C E F# in C major => null (Am6 has F#; non-diatonic)',
      pcs: ['A', 'C', 'E', 'F#'],
      expected: null,
      // Your analyzer likely still returns Am6; the classifier rejects degree.
      expectTop: (top) => expect(top.quality, ChordQualityToken.minor6),
    ),

    // Diminished7 is not diatonic in C major natural scale.
    deg(
      name: 'B D F Ab in C major => null (fully diminished7 is borrowed)',
      pcs: ['B', 'D', 'F', 'Ab'],
      expected: null,
    ),

    // -------------------------
    // A natural minor sanity
    // -------------------------
    deg(
      name: 'A C E in A minor => i',
      pcs: ['A', 'C', 'E'],
      tonality: const Tonality('A', TonalityMode.minor),
      expected: ScaleDegree.one,
    ),
    deg(
      name: 'G B D F in A minor => VII (G7 is diatonic in natural minor model)',
      pcs: ['G', 'B', 'D', 'F'],
      tonality: const Tonality('A', TonalityMode.minor),
      expected: ScaleDegree.seven,
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

      final ctx = makeContext(tonality: c.tonality);
      final results = ChordAnalyzer.analyze(input, context: ctx);

      expect(results, isNotEmpty, reason: 'No candidates returned');
      final top = results.first.identity;

      // Sanity-check top chord identity if requested.
      c.expectTop?.call(top);

      final degree = ScaleDegreeClassifier.degreeForChord(
        c.tonality,
        top,
        presentIntervalsMask: top.presentIntervalsMask,
        strictVoicingValidation: true,
        rejectUnexplainedTones: true,
      );

      expect(
        degree,
        c.expectedDegree,
        reason: [
          'Scale degree mismatch',
          '  Tonality: ${c.tonality.displayName}',
          '    Notes: ${c.pcs.join(" ")}',
          '     Bass: ${c.bass ?? c.pcs.first}',
          '  TopChord: $top',
        ].join('\n'),
      );
    });
  }
}
