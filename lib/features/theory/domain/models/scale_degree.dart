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

  String spokenRomanNumeralForMode(TonalityMode mode) {
    if (mode == TonalityMode.major) {
      return switch (this) {
        ScaleDegree.one => 'I',
        ScaleDegree.two => 'ii',
        ScaleDegree.three => 'iii',
        ScaleDegree.four => 'IV',
        ScaleDegree.five => 'V',
        ScaleDegree.six => 'vi',
        ScaleDegree.seven => 'vii diminished',
      };
    }

    return switch (this) {
      ScaleDegree.one => 'i',
      ScaleDegree.two => 'ii diminished',
      ScaleDegree.three => 'flat III',
      ScaleDegree.four => 'iv',
      ScaleDegree.five => 'v',
      ScaleDegree.six => 'flat VI',
      ScaleDegree.seven => 'flat VII',
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
