import '../models/chord_identity.dart';

/// Decorates a triad roman numeral [base] for a seventh-chord [quality]
/// (e.g. "ii" + minor7 -> "ii7", halfDiminished7 -> "iiø7").
String romanNumeralForQuality(String base, ChordQuality quality) {
  return switch (quality) {
    ChordQuality.dominant7 => '${base}7',
    ChordQuality.dominant7Flat5 => '${base}7b5',
    ChordQuality.dominant7Sharp5 => '${base}7#5',
    ChordQuality.minorSharp5 => '$base#5',
    ChordQuality.major7 => '${base}maj7',
    ChordQuality.major7Flat5 => '${base}maj7b5',
    ChordQuality.major7Sharp5 => '${base}maj7#5',
    ChordQuality.minor7 => '${base}7',
    ChordQuality.minor7Sharp5 => '${base}7#5',
    ChordQuality.minorMajor7 => '$base(maj7)',
    ChordQuality.halfDiminished7 => '${_withoutDiminishedSymbol(base)}ø7',
    ChordQuality.diminished7 => '${base}7',
    _ => base,
  };
}

String _withoutDiminishedSymbol(String romanNumeral) =>
    romanNumeral.endsWith('°')
    ? romanNumeral.substring(0, romanNumeral.length - 1)
    : romanNumeral;
