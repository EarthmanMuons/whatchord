import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/theory/theory.dart';

import 'helpers/theory_test_helpers.dart';

class ScaleDegreeCase {
  final String name;
  final List<String> pcs;
  final String? bass;
  final int? noteCount;
  final Tonality tonality;

  /// Expected strict degree (null = not diatonic under strict rules).
  final ScaleDegree? expectedDegree;
  final ScaleDegreeSource? expectedSource;
  final String? expectedRomanNumeral;

  /// Sanity-check the winning chord identity.
  final void Function(ChordIdentity top)? expectTop;

  const ScaleDegreeCase({
    required this.name,
    required this.pcs,
    this.bass,
    this.noteCount,
    required this.tonality,
    required this.expectedDegree,
    this.expectedSource,
    this.expectedRomanNumeral,
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
  ScaleDegreeSource? expectedSource,
  String? expectedRomanNumeral,
  void Function(ChordIdentity top)? expectTop,
}) {
  return ScaleDegreeCase(
    name: name,
    pcs: pcs,
    bass: bass,
    noteCount: noteCount,
    tonality: tonality,
    expectedDegree: expected,
    expectedSource: expectedSource,
    expectedRomanNumeral: expectedRomanNumeral,
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

    // Suspensions: strict classifier returns null.
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
    // A minor: natural-minor key signature plus harmonic-minor functions.
    // -------------------------
    deg(
      name: 'A C E in A minor => i',
      pcs: ['A', 'C', 'E'],
      tonality: const Tonality('A', TonalityMode.minor),
      expected: ScaleDegree.one,
      expectedSource: ScaleDegreeSource.naturalMinor,
      expectedRomanNumeral: 'i',
    ),
    deg(
      name: 'E G B in A minor => v',
      pcs: ['E', 'G', 'B'],
      tonality: const Tonality('A', TonalityMode.minor),
      expected: ScaleDegree.five,
      expectedSource: ScaleDegreeSource.naturalMinor,
      expectedRomanNumeral: 'v',
    ),
    deg(
      name: 'E G# B in A minor => V (harmonic minor)',
      pcs: ['E', 'G#', 'B'],
      tonality: const Tonality('A', TonalityMode.minor),
      expected: ScaleDegree.five,
      expectedSource: ScaleDegreeSource.harmonicMinor,
      expectedRomanNumeral: 'V',
    ),
    deg(
      name: 'E G# B D in A minor => V7 (harmonic minor)',
      pcs: ['E', 'G#', 'B', 'D'],
      tonality: const Tonality('A', TonalityMode.minor),
      expected: ScaleDegree.five,
      expectedSource: ScaleDegreeSource.harmonicMinor,
      expectedRomanNumeral: 'V7',
      expectTop: (top) => expect(top.quality, ChordQualityToken.dominant7),
    ),
    deg(
      name: 'E G# B D F in A minor => V7b9 (harmonic minor)',
      pcs: ['E', 'G#', 'B', 'D', 'F'],
      tonality: const Tonality('A', TonalityMode.minor),
      expected: ScaleDegree.five,
      expectedSource: ScaleDegreeSource.harmonicMinor,
      expectedRomanNumeral: 'V7',
      expectTop: (top) {
        expect(top.quality, ChordQualityToken.dominant7);
        expect(top.extensions, contains(ChordExtension.flat9));
      },
    ),
    deg(
      name: 'E G# C D in A minor => V7#5 (harmonic minor)',
      pcs: ['E', 'G#', 'C', 'D'],
      tonality: const Tonality('A', TonalityMode.minor),
      expected: ScaleDegree.five,
      expectedSource: ScaleDegreeSource.harmonicMinor,
      expectedRomanNumeral: 'V7#5',
      expectTop: (top) =>
          expect(top.quality, ChordQualityToken.dominant7Sharp5),
    ),
    deg(
      name: 'G B D F in A minor => bVII7 (natural minor)',
      pcs: ['G', 'B', 'D', 'F'],
      tonality: const Tonality('A', TonalityMode.minor),
      expected: ScaleDegree.seven,
      expectedSource: ScaleDegreeSource.naturalMinor,
      expectedRomanNumeral: '♭VII7',
    ),
    deg(
      name: 'G# B D in A minor => vii° (harmonic minor)',
      pcs: ['G#', 'B', 'D'],
      tonality: const Tonality('A', TonalityMode.minor),
      expected: ScaleDegree.seven,
      expectedSource: ScaleDegreeSource.harmonicMinor,
      expectedRomanNumeral: 'vii°',
    ),
    deg(
      name: 'G# B D F in A minor => vii°7 (harmonic minor)',
      pcs: ['G#', 'B', 'D', 'F'],
      tonality: const Tonality('A', TonalityMode.minor),
      expected: ScaleDegree.seven,
      expectedSource: ScaleDegreeSource.harmonicMinor,
      expectedRomanNumeral: 'vii°7',
      expectTop: (top) => expect(top.quality, ChordQualityToken.diminished7),
    ),
    deg(
      name: 'C E G# in A minor => bIII+ (harmonic minor)',
      pcs: ['C', 'E', 'G#'],
      tonality: const Tonality('A', TonalityMode.minor),
      expected: ScaleDegree.three,
      expectedSource: ScaleDegreeSource.harmonicMinor,
      expectedRomanNumeral: '♭III+',
      expectTop: (top) => expect(top.quality, ChordQualityToken.augmented),
    ),
    deg(
      name: 'C E G# B in A minor => bIIImaj7#5 (harmonic minor)',
      pcs: ['C', 'E', 'G#', 'B'],
      tonality: const Tonality('A', TonalityMode.minor),
      expected: ScaleDegree.three,
      expectedSource: ScaleDegreeSource.harmonicMinor,
      expectedRomanNumeral: '♭III+maj7#5',
      expectTop: (top) => expect(top.quality, ChordQualityToken.major7Sharp5),
    ),
    deg(
      name: 'A C E G# in A minor => i(maj7) (harmonic minor)',
      pcs: ['A', 'C', 'E', 'G#'],
      tonality: const Tonality('A', TonalityMode.minor),
      expected: ScaleDegree.one,
      expectedSource: ScaleDegreeSource.harmonicMinor,
      expectedRomanNumeral: 'i(maj7)',
      expectTop: (top) => expect(top.quality, ChordQualityToken.minorMajor7),
    ),
  ];

  for (final c in cases) {
    test(c.name, () {
      final input = chordInputFromNames(
        names: c.pcs,
        bass: c.bass,
        noteCount: c.noteCount,
      );

      final ctx = makeAnalysisContext(tonality: c.tonality);
      final results = ChordAnalyzer.analyze(input, context: ctx);

      expect(results, isNotEmpty, reason: 'No candidates returned');
      final top = results.first.identity;

      // Sanity-check top chord identity if requested.
      c.expectTop?.call(top);

      final analysis = ScaleDegreeClassifier.analyzeChord(
        c.tonality,
        top,
        presentIntervalsMask: top.presentIntervalsMask,
        strictVoicingValidation: true,
        rejectUnexplainedTones: true,
      );

      expect(
        analysis?.degree,
        c.expectedDegree,
        reason: [
          'Scale degree mismatch',
          '  Tonality: ${c.tonality.displayName}',
          '    Notes: ${c.pcs.join(" ")}',
          '     Bass: ${c.bass ?? c.pcs.first}',
          '  TopChord: $top',
        ].join('\n'),
      );

      if (c.expectedSource != null) {
        expect(analysis?.source, c.expectedSource);
      }
      if (c.expectedRomanNumeral != null) {
        expect(analysis?.romanNumeral, c.expectedRomanNumeral);
      }
    });
  }
}
