import 'package:test/test.dart';

import 'package:whatchord/whatchord.dart';

import 'package:whatchord/testing.dart';

final _analyzer = ChordAnalyzer();

class ScaleDegreeCase {
  final String description;
  final List<String> pcs;
  final String? bass;
  final int? noteCount;
  final Tonality tonality;

  /// Expected strict degree (null = not diatonic under strict rules).
  final ScaleDegree? expectedDegree;
  final ScaleDegreeSource? expectedSource;
  final String? expectedRomanNumeral;

  /// Sanity-checks for the winning analyzer identity.
  final ChordQuality? expectedQuality;
  final Set<ChordExtension> expectedExtensions;

  const ScaleDegreeCase({
    required this.description,
    required this.pcs,
    this.bass,
    this.noteCount,
    required this.tonality,
    required this.expectedDegree,
    this.expectedSource,
    this.expectedRomanNumeral,
    this.expectedQuality,
    this.expectedExtensions = const {},
  });
}

ScaleDegreeCase deg({
  required String description,
  required List<String> pcs,
  String? bass,
  int? noteCount,
  Tonality tonality = const Tonality(Tonic.c, TonalityMode.major),
  required ScaleDegree? expected,
  ScaleDegreeSource? expectedSource,
  String? expectedRomanNumeral,
  ChordQuality? expectedQuality,
  Set<ChordExtension> expectedExtensions = const {},
}) {
  return ScaleDegreeCase(
    description: description,
    pcs: pcs,
    bass: bass,
    noteCount: noteCount,
    tonality: tonality,
    expectedDegree: expected,
    expectedSource: expectedSource,
    expectedRomanNumeral: expectedRomanNumeral,
    expectedQuality: expectedQuality,
    expectedExtensions: expectedExtensions,
  );
}

void main() {
  group('ScaleDegree source labels', () {
    test('uses conventional harmonic-minor degree labels', () {
      expect(
        ScaleDegree.values
            .map(
              (degree) =>
                  degree.romanNumeralForSource(ScaleDegreeSource.harmonicMinor),
            )
            .toList(),
        ['i', 'ii°', '♭III+', 'iv', 'V', '♭VI', 'vii°'],
      );
    });
  });

  final cases = <ScaleDegreeCase>[
    // -------------------------
    // C major: triads + 7ths
    // -------------------------
    deg(
      description: 'major tonic triad',
      pcs: ['C', 'E', 'G'],
      expected: ScaleDegree.one,
    ),
    deg(
      description: 'major tonic seventh',
      pcs: ['C', 'E', 'G', 'B'],
      expected: ScaleDegree.one,
      expectedQuality: ChordQuality.major7,
    ),
    deg(
      description: 'supertonic minor triad',
      pcs: ['D', 'F', 'A'],
      expected: ScaleDegree.two,
    ),
    deg(
      description: 'supertonic minor seventh',
      pcs: ['D', 'F', 'A', 'C'],
      expected: ScaleDegree.two,
      expectedQuality: ChordQuality.minor7,
    ),
    deg(
      description: 'dominant seventh',
      pcs: ['G', 'B', 'D', 'F'],
      expected: ScaleDegree.five,
      expectedQuality: ChordQuality.dominant7,
    ),
    deg(
      description: 'leading-tone half-diminished seventh',
      pcs: ['B', 'D', 'F', 'A'],
      expected: ScaleDegree.seven,
      expectedRomanNumeral: 'viiø7',
      expectedQuality: ChordQuality.halfDiminished7,
    ),

    // -------------------------
    // Strict exclusions
    // -------------------------

    // Suspensions: strict classifier returns null.
    deg(
      description: 'suspended chord has no strict degree',
      pcs: ['C', 'F', 'G'],
      expected: null,
      expectedQuality: ChordQuality.sus4,
    ),

    // Altered dominants are non-diatonic under natural major/minor strictness.
    deg(
      description: 'chromatic altered dominant has no strict major degree',
      pcs: ['C', 'E', 'G', 'Bb', 'Db'],
      expected: null,
      expectedQuality: ChordQuality.dominant7,
      expectedExtensions: {ChordExtension.flat9},
    ),

    // 6th chords: allowed only when chord-member tones are diatonic (strict).
    deg(
      description: 'diatonic added-sixth tonic',
      pcs: ['C', 'E', 'G', 'A'],
      expected: ScaleDegree.one,
      expectedQuality: ChordQuality.major6,
    ),
    deg(
      description: 'non-diatonic minor sixth has no strict major degree',
      pcs: ['A', 'C', 'E', 'F#'],
      expected: null,
      // The analyzer still returns Am6; the classifier rejects the degree.
      expectedQuality: ChordQuality.minor6,
    ),

    // Diminished7 is not diatonic in C major natural scale.
    deg(
      description:
          'borrowed fully diminished seventh has no strict major degree',
      pcs: ['B', 'D', 'F', 'Ab'],
      expected: null,
    ),

    // -------------------------
    // A minor: natural-minor key signature plus harmonic-minor functions.
    // -------------------------
    deg(
      description: 'minor tonic triad',
      pcs: ['A', 'C', 'E'],
      tonality: const Tonality(Tonic.a, TonalityMode.minor),
      expected: ScaleDegree.one,
      expectedSource: ScaleDegreeSource.naturalMinor,
      expectedRomanNumeral: 'i',
    ),
    deg(
      description: 'natural-minor dominant minor triad',
      pcs: ['E', 'G', 'B'],
      tonality: const Tonality(Tonic.a, TonalityMode.minor),
      expected: ScaleDegree.five,
      expectedSource: ScaleDegreeSource.naturalMinor,
      expectedRomanNumeral: 'v',
    ),
    deg(
      description: 'harmonic-minor dominant triad',
      pcs: ['E', 'G#', 'B'],
      tonality: const Tonality(Tonic.a, TonalityMode.minor),
      expected: ScaleDegree.five,
      expectedSource: ScaleDegreeSource.harmonicMinor,
      expectedRomanNumeral: 'V',
    ),
    deg(
      description: 'harmonic-minor dominant seventh',
      pcs: ['E', 'G#', 'B', 'D'],
      tonality: const Tonality(Tonic.a, TonalityMode.minor),
      expected: ScaleDegree.five,
      expectedSource: ScaleDegreeSource.harmonicMinor,
      expectedRomanNumeral: 'V7',
      expectedQuality: ChordQuality.dominant7,
    ),
    deg(
      description: 'harmonic-minor dominant flat ninth',
      pcs: ['E', 'G#', 'B', 'D', 'F'],
      tonality: const Tonality(Tonic.a, TonalityMode.minor),
      expected: ScaleDegree.five,
      expectedSource: ScaleDegreeSource.harmonicMinor,
      expectedRomanNumeral: 'V7',
      expectedQuality: ChordQuality.dominant7,
      expectedExtensions: {ChordExtension.flat9},
    ),
    deg(
      description: 'harmonic-minor dominant sharp fifth',
      pcs: ['E', 'G#', 'C', 'D'],
      tonality: const Tonality(Tonic.a, TonalityMode.minor),
      expected: ScaleDegree.five,
      expectedSource: ScaleDegreeSource.harmonicMinor,
      expectedRomanNumeral: 'V7#5',
      expectedQuality: ChordQuality.dominant7Sharp5,
    ),
    deg(
      description: 'natural-minor flat seventh dominant seventh',
      pcs: ['G', 'B', 'D', 'F'],
      tonality: const Tonality(Tonic.a, TonalityMode.minor),
      expected: ScaleDegree.seven,
      expectedSource: ScaleDegreeSource.naturalMinor,
      expectedRomanNumeral: '♭VII7',
    ),
    deg(
      description: 'harmonic-minor leading-tone diminished triad',
      pcs: ['G#', 'B', 'D'],
      tonality: const Tonality(Tonic.a, TonalityMode.minor),
      expected: ScaleDegree.seven,
      expectedSource: ScaleDegreeSource.harmonicMinor,
      expectedRomanNumeral: 'vii°',
    ),
    deg(
      description: 'harmonic-minor leading-tone diminished seventh',
      pcs: ['G#', 'B', 'D', 'F'],
      tonality: const Tonality(Tonic.a, TonalityMode.minor),
      expected: ScaleDegree.seven,
      expectedSource: ScaleDegreeSource.harmonicMinor,
      expectedRomanNumeral: 'vii°7',
      expectedQuality: ChordQuality.diminished7,
    ),
    deg(
      description: 'harmonic-minor augmented mediant',
      pcs: ['C', 'E', 'G#'],
      tonality: const Tonality(Tonic.a, TonalityMode.minor),
      expected: ScaleDegree.three,
      expectedSource: ScaleDegreeSource.harmonicMinor,
      expectedRomanNumeral: '♭III+',
      expectedQuality: ChordQuality.augmented,
    ),
    deg(
      description: 'harmonic-minor augmented mediant seventh',
      pcs: ['C', 'E', 'G#', 'B'],
      tonality: const Tonality(Tonic.a, TonalityMode.minor),
      expected: ScaleDegree.three,
      expectedSource: ScaleDegreeSource.harmonicMinor,
      expectedRomanNumeral: '♭III+maj7#5',
      expectedQuality: ChordQuality.major7Sharp5,
    ),
    deg(
      description: 'harmonic-minor tonic major seventh',
      pcs: ['A', 'C', 'E', 'G#'],
      tonality: const Tonality(Tonic.a, TonalityMode.minor),
      expected: ScaleDegree.one,
      expectedSource: ScaleDegreeSource.harmonicMinor,
      expectedRomanNumeral: 'i(maj7)',
      expectedQuality: ChordQuality.minorMajor7,
    ),
  ];

  for (final c in cases) {
    test(_testName(c), () {
      final input = chordInputFromNames(
        names: c.pcs,
        bass: c.bass,
        noteCount: c.noteCount,
      );

      final ctx = makeAnalysisContext(tonality: c.tonality);
      final results = _analyzer.analyze(input, context: ctx);

      expect(results, isNotEmpty, reason: 'No candidates returned');
      final top = results.first.identity;

      if (c.expectedQuality != null) {
        expect(top.quality, c.expectedQuality);
      }
      for (final extension in c.expectedExtensions) {
        expect(top.extensions, contains(extension));
      }

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

String _testName(ScaleDegreeCase c) {
  final expected = c.expectedRomanNumeral ?? c.expectedDegree?.name ?? 'null';
  final parts = [
    c.description,
    '${c.pcs.join(" ")} in ${c.tonality.displayName} -> $expected',
  ];
  final bass = c.bass;
  if (bass != null) {
    parts.add('bass $bass');
  }
  if (c.noteCount != null) {
    parts.add('note count ${c.noteCount}');
  }

  return parts.join(' | ');
}
