import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/theory/theory.dart';

void main() {
  group('Scale model', () {
    test('pitch classes follow the scale intervals from the tonic', () {
      expect(const Scale(Tonic.c, ScaleKind.major).pitchClasses, [
        0,
        2,
        4,
        5,
        7,
        9,
        11,
      ]);
      expect(const Scale(Tonic.a, ScaleKind.aeolian).pitchClasses, [
        9,
        11,
        0,
        2,
        4,
        5,
        7,
      ]);
    });

    test('containsPitchClass reflects scale membership', () {
      const cMajor = Scale(Tonic.c, ScaleKind.major);
      expect(cMajor.containsPitchClass(0), isTrue); // C
      expect(cMajor.containsPitchClass(11), isTrue); // B
      expect(cMajor.containsPitchClass(1), isFalse); // C#/Db
      expect(cMajor.containsPitchClass(-12), isTrue); // normalizes to C
    });

    test('display names read naturally', () {
      expect(const Scale(Tonic.c, ScaleKind.major).displayName, 'C major');
      expect(
        const Scale(Tonic.a, ScaleKind.aeolian).displayName,
        'A natural minor',
      );
      expect(ScaleKind.major.displayLabel, 'Major (Ionian)');
      expect(ScaleKind.aeolian.displayLabel, 'Natural minor (Aeolian)');
      expect(ScaleKind.dorian.displayLabel, 'Dorian');
    });
  });

  group('Scale tone spelling', () {
    void expectTones(Tonic tonic, ScaleKind kind, List<String> expected) {
      expect(
        ScaleHarmonizer.harmonize(Scale(tonic, kind)).toneNames,
        expected,
        reason: '${tonic.label} ${kind.name}',
      );
    }

    test('major-scale modes use consecutive, letter-correct names', () {
      expectTones(Tonic.c, ScaleKind.major, [
        'C',
        'D',
        'E',
        'F',
        'G',
        'A',
        'B',
      ]);
      expectTones(Tonic.d, ScaleKind.dorian, [
        'D',
        'E',
        'F',
        'G',
        'A',
        'B',
        'C',
      ]);
      expectTones(Tonic.c, ScaleKind.phrygian, [
        'C',
        'Db',
        'Eb',
        'F',
        'G',
        'Ab',
        'Bb',
      ]);
      expectTones(Tonic.f, ScaleKind.lydian, [
        'F',
        'G',
        'A',
        'B',
        'C',
        'D',
        'E',
      ]);
      expectTones(Tonic.a, ScaleKind.aeolian, [
        'A',
        'B',
        'C',
        'D',
        'E',
        'F',
        'G',
      ]);
      expectTones(Tonic.b, ScaleKind.locrian, [
        'B',
        'C',
        'D',
        'E',
        'F',
        'G',
        'A',
      ]);
    });

    test('harmonic and melodic minor raise the right degrees', () {
      expectTones(Tonic.a, ScaleKind.harmonicMinor, [
        'A',
        'B',
        'C',
        'D',
        'E',
        'F',
        'G#',
      ]);
      expectTones(Tonic.a, ScaleKind.melodicMinor, [
        'A',
        'B',
        'C',
        'D',
        'E',
        'F#',
        'G#',
      ]);
    });
  });

  group('Diatonic chord qualities', () {
    List<ChordQualityToken> triads(Scale scale) => [
      for (final d in ScaleHarmonizer.harmonize(scale).degrees) d.triadQuality,
    ];
    List<ChordQualityToken> sevenths(Scale scale) => [
      for (final d in ScaleHarmonizer.harmonize(scale).degrees)
        d.seventhQuality,
    ];

    test('major scale triads and sevenths', () {
      const cMajor = Scale(Tonic.c, ScaleKind.major);
      expect(triads(cMajor), const [
        ChordQualityToken.major,
        ChordQualityToken.minor,
        ChordQualityToken.minor,
        ChordQualityToken.major,
        ChordQualityToken.major,
        ChordQualityToken.minor,
        ChordQualityToken.diminished,
      ]);
      expect(sevenths(cMajor), const [
        ChordQualityToken.major7,
        ChordQualityToken.minor7,
        ChordQualityToken.minor7,
        ChordQualityToken.major7,
        ChordQualityToken.dominant7,
        ChordQualityToken.minor7,
        ChordQualityToken.halfDiminished7,
      ]);
    });

    test('harmonic minor sevenths include maj7#5 and a fully diminished 7', () {
      expect(sevenths(const Scale(Tonic.a, ScaleKind.harmonicMinor)), const [
        ChordQualityToken.minorMajor7,
        ChordQualityToken.halfDiminished7,
        ChordQualityToken.major7Sharp5,
        ChordQualityToken.minor7,
        ChordQualityToken.dominant7,
        ChordQualityToken.major7,
        ChordQualityToken.diminished7,
      ]);
    });

    test('melodic minor sevenths', () {
      expect(sevenths(const Scale(Tonic.a, ScaleKind.melodicMinor)), const [
        ChordQualityToken.minorMajor7,
        ChordQualityToken.minor7,
        ChordQualityToken.major7Sharp5,
        ChordQualityToken.dominant7,
        ChordQualityToken.dominant7,
        ChordQualityToken.halfDiminished7,
        ChordQualityToken.halfDiminished7,
      ]);
    });
  });

  group('Roman numerals', () {
    test('major-scale triad and seventh roman numerals', () {
      final harmony = ScaleHarmonizer.harmonize(
        const Scale(Tonic.c, ScaleKind.major),
      );
      expect(
        [for (final d in harmony.degrees) d.triadRoman],
        ['I', 'ii', 'iii', 'IV', 'V', 'vi', 'vii°'],
      );
      expect(
        [for (final d in harmony.degrees) d.seventhRoman],
        ['Imaj7', 'ii7', 'iii7', 'IVmaj7', 'V7', 'vi7', 'viiø7'],
      );
    });

    test('lydian raises the fourth degree', () {
      final harmony = ScaleHarmonizer.harmonize(
        const Scale(Tonic.f, ScaleKind.lydian),
      );
      expect(
        [for (final d in harmony.degrees) d.triadRoman],
        ['I', 'II', 'iii', '♯iv°', 'V', 'vi', 'vii'],
      );
    });

    test('roman numerals are independent of the tonic', () {
      final inC = ScaleHarmonizer.harmonize(
        const Scale(Tonic.c, ScaleKind.major),
      );
      final inEb = ScaleHarmonizer.harmonize(
        const Scale(Tonic.eFlat, ScaleKind.major),
      );
      expect(
        [for (final d in inEb.degrees) d.triadRoman],
        [for (final d in inC.degrees) d.triadRoman],
      );
    });

    test('triad roman numerals match the published ScaleDegree table', () {
      const sources = {
        ScaleKind.major: ScaleDegreeSource.major,
        ScaleKind.aeolian: ScaleDegreeSource.naturalMinor,
        ScaleKind.harmonicMinor: ScaleDegreeSource.harmonicMinor,
      };

      for (final entry in sources.entries) {
        final harmony = ScaleHarmonizer.harmonize(Scale(Tonic.c, entry.key));
        for (var i = 0; i < 7; i++) {
          expect(
            harmony.degrees[i].triadRoman,
            ScaleDegree.values[i].romanNumeralForSource(entry.value),
            reason: '${entry.key.name} degree ${i + 1}',
          );
        }
      }
    });
  });

  test('every degree of every kind resolves to a known chord quality', () {
    for (final kind in ScaleKind.values) {
      for (final tonic in Tonic.values) {
        // Harmonizing must not throw for any supported scale on any tonic.
        final harmony = ScaleHarmonizer.harmonize(Scale(tonic, kind));
        expect(harmony.degrees, hasLength(kind.intervals.length));
      }
    }
  });
}
