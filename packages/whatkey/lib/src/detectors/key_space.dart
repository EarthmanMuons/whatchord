import 'package:whatchord/whatchord.dart';

/// The 24-key space shared by every detector: canonical tonalities and the
/// per-key scale membership masks.
abstract final class KeySpace {
  /// One canonical `Tonality` per (pitch class, mode) pair, taken from the key
  /// signature table and ordered so that a tonality's list position equals
  /// [index] of it. Detection is pitch-class based; enharmonic spelling is a
  /// presentation concern. Where two spellings exist the one with fewer
  /// accidentals wins (B over C flat); the six-accidental tie prefers flats
  /// (G flat major, e flat minor), keeping relative pairs consistent.
  static final List<Tonality> canonicalTonalities = _canonicalTonalities();

  static List<Tonality> _canonicalTonalities() {
    final rows = [...keySignatures]
      ..sort((a, b) {
        final byCount = a.accidentalCount.abs().compareTo(
          b.accidentalCount.abs(),
        );
        return byCount != 0
            ? byCount
            : a.accidentalCount.compareTo(b.accidentalCount);
      });
    final byKey = <int, Tonality>{};
    for (final row in rows) {
      for (final tonality in [row.relativeMajor, row.relativeMinor]) {
        byKey.putIfAbsent(index(tonality), () => tonality);
      }
    }
    assert(byKey.length == 24);
    return List.unmodifiable([for (var k = 0; k < 24; k++) byKey[k]!]);
  }

  /// Stable index of a tonality in the 24-key space.
  static int index(Tonality tonality) => tonality.isMinor
      ? minorIndex(tonality.tonicPitchClass)
      : majorIndex(tonality.tonicPitchClass);

  /// Index of the canonical major key with tonic [pc].
  static int majorIndex(int pc) => pc * 2;

  /// Index of the canonical minor key with tonic [pc].
  static int minorIndex(int pc) => pc * 2 + 1;

  /// The canonical major tonality with tonic [pc].
  static Tonality majorTonality(int pc) => canonicalTonalities[majorIndex(pc)];

  /// The canonical minor tonality with tonic [pc].
  static Tonality minorTonality(int pc) => canonicalTonalities[minorIndex(pc)];

  /// Tonic pitch class of the relative major of the minor key on [minorPc].
  static int relativeMajorPc(int minorPc) => (minorPc + 3) % 12;

  /// Tonic pitch class of the relative minor of the major key on [majorPc].
  static int relativeMinorPc(int majorPc) => (majorPc + 9) % 12;

  /// Position of [pc] on the circle of fifths, C at position 0 (7 fifths
  /// span the octave, so successive positions rise by a fifth).
  static int fifthsPosition(int pc) => (pc * 7) % 12;

  /// Pitch class at [position] on the circle of fifths; the fifths mapping
  /// is self-inverse (7 * 7 = 49 = 1 mod 12).
  static int pcAtFifthsPosition(int position) => fifthsPosition(position);

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
  static const Set<ChordQuality> majorTonicQualities = {
    ChordQuality.major,
    ChordQuality.major6,
    ChordQuality.major7,
    ChordQuality.dominant7,
  };

  /// Chord qualities that read as "home" over a minor tonic.
  static const Set<ChordQuality> minorTonicQualities = {
    ChordQuality.minor,
    ChordQuality.minor6,
    ChordQuality.minor7,
    ChordQuality.minorMajor7,
  };

  /// The tonic quality set for [tonality]'s mode.
  static Set<ChordQuality> tonicQualities(Tonality tonality) =>
      tonality.isMajor ? majorTonicQualities : minorTonicQualities;

  /// Chord qualities that read as dominant function on any root.
  static const Set<ChordQuality> dominantQualities = {
    ChordQuality.dominant7,
    ChordQuality.dominant7sus2,
    ChordQuality.dominant7sus4,
    ChordQuality.dominant7Flat5,
    ChordQuality.dominant7Sharp5,
  };
}
