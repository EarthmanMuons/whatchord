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
