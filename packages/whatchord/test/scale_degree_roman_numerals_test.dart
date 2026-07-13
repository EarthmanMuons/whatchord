import 'package:test/test.dart';

import 'package:whatchord/whatchord.dart';

void main() {
  group('romanNumeralForQuality', () {
    test('adds seventh-family suffixes to an existing roman base', () {
      expect(romanNumeralForQuality('V', ChordQuality.dominant7), 'V7');
      expect(romanNumeralForQuality('V', ChordQuality.dominant7Sharp5), 'V7#5');
      expect(romanNumeralForQuality('I', ChordQuality.major7), 'Imaj7');
      expect(romanNumeralForQuality('i', ChordQuality.minorMajor7), 'i(maj7)');
    });

    test('replaces diminished triad mark with half-diminished symbol', () {
      expect(
        romanNumeralForQuality('vii°', ChordQuality.halfDiminished7),
        'viiø7',
      );
    });

    test('keeps unsupported qualities on the base roman numeral', () {
      expect(romanNumeralForQuality('I', ChordQuality.major), 'I');
      expect(romanNumeralForQuality('i', ChordQuality.minorSharp5), 'i#5');
    });
  });
}
