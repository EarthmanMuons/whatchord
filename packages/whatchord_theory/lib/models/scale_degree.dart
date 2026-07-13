import 'tonality.dart';

enum ScaleDegree {
  one,
  two,
  three,
  four,
  five,
  six,
  seven;

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

enum ScaleDegreeSource {
  major,
  naturalMinor,
  harmonicMinor;

  String get displayLabel {
    return switch (this) {
      ScaleDegreeSource.major => 'major',
      ScaleDegreeSource.naturalMinor => 'natural minor',
      ScaleDegreeSource.harmonicMinor => 'harmonic minor',
    };
  }
}

class ScaleDegreeAnalysis {
  const ScaleDegreeAnalysis({
    required this.degree,
    required this.source,
    required this.romanNumeral,
    required this.spokenScaleDegree,
    required this.functionName,
  });

  final ScaleDegree degree;
  final ScaleDegreeSource source;
  final String romanNumeral;
  final String spokenScaleDegree;
  final String functionName;

  bool get isHarmonicMinor => source == ScaleDegreeSource.harmonicMinor;
}
