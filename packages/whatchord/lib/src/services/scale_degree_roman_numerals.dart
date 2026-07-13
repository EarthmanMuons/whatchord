import '../models/chord_identity.dart';

/// Decorates a triad roman numeral [base] for a seventh-chord [quality]
/// (e.g. "ii" + minor7 -> "ii7", halfDiminished7 -> "iiø7").
String romanNumeralForQuality(String base, ChordQualityToken quality) {
  return switch (quality) {
    ChordQualityToken.dominant7 => '${base}7',
    ChordQualityToken.dominant7Flat5 => '${base}7b5',
    ChordQualityToken.dominant7Sharp5 => '${base}7#5',
    ChordQualityToken.minorSharp5 => '$base#5',
    ChordQualityToken.major7 => '${base}maj7',
    ChordQualityToken.major7Flat5 => '${base}maj7b5',
    ChordQualityToken.major7Sharp5 => '${base}maj7#5',
    ChordQualityToken.minor7 => '${base}7',
    ChordQualityToken.minor7Sharp5 => '${base}7#5',
    ChordQualityToken.minorMajor7 => '$base(maj7)',
    ChordQualityToken.halfDiminished7 => '${_withoutDiminishedSymbol(base)}ø7',
    ChordQualityToken.diminished7 => '${base}7',
    _ => base,
  };
}

String _withoutDiminishedSymbol(String romanNumeral) =>
    romanNumeral.endsWith('°')
    ? romanNumeral.substring(0, romanNumeral.length - 1)
    : romanNumeral;
