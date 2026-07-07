import 'package:whatchord/features/theory/domain/theory_domain.dart';

/// The 24-key space shared by every detector: canonical tonalities and the
/// per-key scale membership masks.
abstract final class KeySpace {
  /// One canonical `Tonality` per (pitch class, mode) pair, taken from the key
  /// signature table. Detection is pitch-class based; enharmonic spelling is a
  /// presentation concern.
  static final List<Tonality> canonicalTonalities = _canonicalTonalities();

  static List<Tonality> _canonicalTonalities() {
    final byKey = <int, Tonality>{};
    for (final row in keySignatureRows) {
      for (final tonality in [row.relativeMajor, row.relativeMinor]) {
        byKey.putIfAbsent(index(tonality), () => tonality);
      }
    }
    assert(byKey.length == 24);
    return List.unmodifiable(byKey.values);
  }

  /// Stable index of a tonality in the 24-key space.
  static int index(Tonality tonality) =>
      tonality.tonicPitchClass * 2 + (tonality.isMinor ? 1 : 0);

  /// Scale pitch classes per key. Major keys use the major scale; minor keys
  /// use natural union harmonic minor, mirroring `ScaleDegreeClassifier`'s
  /// sources so the harmonic-minor dominant is diatonic evidence.
  static int scaleMask(Tonality tonality) {
    final relative = tonality.isMajor ? _majorMask : _minorMask;
    final tonic = tonality.tonicPitchClass;
    return ((relative << tonic) | (relative >> (12 - tonic))) & 0xFFF;
  }

  // 0,2,4,5,7,9,11
  static const int _majorMask = 0xAB5;

  // Natural {0,2,3,5,7,8,10} union harmonic {..., 11}: 0,2,3,5,7,8,10,11
  static const int _minorMask = 0xDAD;

  /// Chord qualities that read as "home" over a major tonic. Includes
  /// dominant7 so a blues I7 counts as tonic rather than only as V-of-IV
  /// (log entry 2026-07-07-10).
  static const Set<ChordQualityToken> majorTonicQualities = {
    ChordQualityToken.major,
    ChordQualityToken.major6,
    ChordQualityToken.major7,
    ChordQualityToken.dominant7,
  };

  /// Chord qualities that read as "home" over a minor tonic.
  static const Set<ChordQualityToken> minorTonicQualities = {
    ChordQualityToken.minor,
    ChordQualityToken.minor6,
    ChordQualityToken.minor7,
    ChordQualityToken.minorMajor7,
  };

  /// The tonic quality set for [tonality]'s mode.
  static Set<ChordQualityToken> tonicQualities(Tonality tonality) =>
      tonality.isMajor ? majorTonicQualities : minorTonicQualities;
}
