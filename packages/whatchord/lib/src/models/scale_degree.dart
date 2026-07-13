import 'tonality.dart';

/// A diatonic scale degree (1..7), labeled relative to the parallel major
/// scale in minor keys.
enum ScaleDegree {
  one,
  two,
  three,
  four,
  five,
  six,
  seven;

  /// Roman numeral for this degree in [mode], cased by chord quality
  /// (e.g. "IV", "vii°", "♭III").
  String romanNumeralForMode(TonalityMode mode) {
    if (mode == TonalityMode.major) {
      return switch (this) {
        ScaleDegree.one => 'I',
        ScaleDegree.two => 'ii',
        ScaleDegree.three => 'iii',
        ScaleDegree.four => 'IV',
        ScaleDegree.five => 'V',
        ScaleDegree.six => 'vi',
        ScaleDegree.seven => 'vii°',
      };
    }

    // Degrees are labeled relative to the parallel major scale. In minor keys,
    // this means the native III, VI, and VII degrees appear as ♭III, ♭VI, and
    // ♭VII even though they are diatonic to the natural minor scale.
    return switch (this) {
      ScaleDegree.one => 'i',
      ScaleDegree.two => 'ii°',
      ScaleDegree.three => '♭III',
      ScaleDegree.four => 'iv',
      ScaleDegree.five => 'v',
      ScaleDegree.six => '♭VI',
      ScaleDegree.seven => '♭VII',
    };
  }

  /// Roman numeral for this degree in the scale named by [source], which
  /// distinguishes harmonic-minor spellings (e.g. "V", "vii°" in minor).
  String romanNumeralForSource(ScaleDegreeSource source) {
    return switch (source) {
      ScaleDegreeSource.major => romanNumeralForMode(TonalityMode.major),
      ScaleDegreeSource.naturalMinor => romanNumeralForMode(TonalityMode.minor),
      ScaleDegreeSource.harmonicMinor => switch (this) {
        ScaleDegree.one => 'i',
        ScaleDegree.two => 'ii°',
        ScaleDegree.three => '♭III+',
        ScaleDegree.four => 'iv',
        ScaleDegree.five => 'V',
        ScaleDegree.six => '♭VI',
        ScaleDegree.seven => 'vii°',
      },
    };
  }

  /// Spoken ordinal for this degree in [mode] (e.g. "flat third").
  String spokenScaleDegreeForMode(TonalityMode mode) {
    if (mode == TonalityMode.major) {
      return switch (this) {
        ScaleDegree.one => 'first',
        ScaleDegree.two => 'second',
        ScaleDegree.three => 'third',
        ScaleDegree.four => 'fourth',
        ScaleDegree.five => 'fifth',
        ScaleDegree.six => 'sixth',
        ScaleDegree.seven => 'seventh, diminished',
      };
    }

    return switch (this) {
      ScaleDegree.one => 'first',
      ScaleDegree.two => 'second, diminished',
      ScaleDegree.three => 'flat third',
      ScaleDegree.four => 'fourth',
      ScaleDegree.five => 'fifth',
      ScaleDegree.six => 'flat sixth',
      ScaleDegree.seven => 'flat seventh',
    };
  }

  /// Harmonic function name (e.g. "tonic", "dominant", "leading tone").
  String functionNameForMode(TonalityMode mode) {
    return switch (this) {
      ScaleDegree.one => 'tonic',
      ScaleDegree.two => 'supertonic',
      ScaleDegree.three => 'mediant',
      ScaleDegree.four => 'subdominant',
      ScaleDegree.five => 'dominant',
      ScaleDegree.six => 'submediant',
      ScaleDegree.seven =>
        mode == TonalityMode.major ? 'leading tone' : 'subtonic',
    };
  }
}

/// Which scale a degree classification was matched against.
enum ScaleDegreeSource {
  major,
  naturalMinor,
  harmonicMinor;

  /// Human-readable scale name (e.g. "natural minor").
  String get displayLabel {
    return switch (this) {
      ScaleDegreeSource.major => 'major',
      ScaleDegreeSource.naturalMinor => 'natural minor',
      ScaleDegreeSource.harmonicMinor => 'harmonic minor',
    };
  }
}

/// A chord's classified scale degree with its rendered labels.
class ScaleDegreeAnalysis {
  const ScaleDegreeAnalysis({
    required this.degree,
    required this.source,
    required this.romanNumeral,
    required this.spokenScaleDegree,
    required this.functionName,
  });

  /// The classified degree.
  final ScaleDegree degree;

  /// The scale the chord matched.
  final ScaleDegreeSource source;

  /// Rendered roman numeral (e.g. "V7", "ii°").
  final String romanNumeral;

  /// Spoken ordinal (e.g. "fifth").
  final String spokenScaleDegree;

  /// Harmonic function name (e.g. "dominant").
  final String functionName;

  /// Whether the match required the harmonic-minor scale.
  bool get isHarmonicMinor => source == ScaleDegreeSource.harmonicMinor;
}
