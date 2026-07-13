import 'package:test/test.dart';

import 'package:whatchord/whatchord.dart';

void main() {
  group('romanNumeralForQuality', () {
    test('adds seventh-family suffixes to an existing roman base', () {
      expect(romanNumeralForQuality('V', ChordQualityToken.dominant7), 'V7');
      expect(
        romanNumeralForQuality('V', ChordQualityToken.dominant7Sharp5),
        'V7#5',
      );
      expect(romanNumeralForQuality('I', ChordQualityToken.major7), 'Imaj7');
      expect(
        romanNumeralForQuality('i', ChordQualityToken.minorMajor7),
        'i(maj7)',
      );
    });

    test('replaces diminished triad mark with half-diminished symbol', () {
      expect(
        romanNumeralForQuality('vii°', ChordQualityToken.halfDiminished7),
        'viiø7',
      );
    });

    test('keeps unsupported qualities on the base roman numeral', () {
      expect(romanNumeralForQuality('I', ChordQualityToken.major), 'I');
      expect(romanNumeralForQuality('i', ChordQualityToken.minorSharp5), 'i#5');
    });
  });
}
