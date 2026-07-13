import 'package:meta/meta.dart';

import 'chord_extension.dart';
import 'chord_tone_role.dart';

/// Canonical, style-agnostic chord identity produced by analysis.
///
/// This represents the analytical “truth” of a chord before applying
/// enharmonic spelling, notation style, or UI-level formatting.
@immutable
class ChordIdentity {
  /// Pitch class of the chord root (0..11).
  final int rootPc;

  /// Pitch class of the bass (0..11).
  ///
  /// If equal to [rootPc], the chord has no distinct slash bass.
  final int bassPc;

  /// Core chord quality classification.
  ///
  /// This captures the primary quality used by the analysis engine
  /// (e.g., major, minor, dominant seventh) independent of naming
  /// or display conventions.
  final ChordQuality quality;

  /// Additional chord extensions or alterations, expressed as semitone
  /// offsets above the root (0–11).
  ///
  /// These represent non-essential tones beyond the core quality.
  final Set<ChordExtension> extensions;

  /// Intended chord-tone roles keyed by interval-above-root (0..11).
  ///
  /// This disambiguates enharmonically equivalent intervals by assigning
  /// their theoretical function within the chord.
  ///
  /// Example:
  /// - interval 6 might be ChordToneRole.sharp11 (dominant context),
  ///   or ChordToneRole.flat5 (diminished context).
  final Map<int, ChordToneRole> toneRolesByInterval;

  /// 12-bit mask of *actually present* intervals above root (0..11) in the voicing.
  ///
  /// This is the critical input for pedantic validation:
  /// - detect contradictory chord tones (e.g., b7 present on a "maj7" claim)
  /// - ensure required tones are actually present (avoid scale-degree false positives)
  /// - ensure all extensions implied by tokens are present (or reject)
  /// - detect unexplained tones (tones not accounted for by quality or extensions)
  final int presentIntervalsMask;

  const ChordIdentity({
    required this.rootPc,
    required this.bassPc,
    required this.quality,
    this.extensions = const {},
    this.toneRolesByInterval = const {},
    required this.presentIntervalsMask,
  });

  /// Whether the bass is a different pitch class than the root.
  bool get hasSlashBass => bassPc != rootPc;

  @override
  String toString() =>
      'ChordIdentity(root=$rootPc, bass=$bassPc, quality=$quality, ext=$extensions, roles=$toneRolesByInterval)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChordIdentity &&
          other.rootPc == rootPc &&
          other.bassPc == bassPc &&
          other.quality == quality &&
          _setEquals(other.extensions, extensions) &&
          _mapEquals(other.toneRolesByInterval, toneRolesByInterval) &&
          other.presentIntervalsMask == presentIntervalsMask;

  @override
  int get hashCode => Object.hash(
    rootPc,
    bassPc,
    quality,
    _setHash(extensions),
    _mapHash(toneRolesByInterval),
    presentIntervalsMask,
  );

  static bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }

  static int _setHash<T>(Set<T> s) {
    // Order-independent hash for small sets.
    var h = 0;
    for (final v in s) {
      h ^= v.hashCode;
    }
    return h;
  }

  static bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (!b.containsKey(e.key)) return false;
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  static int _mapHash<K, V>(Map<K, V> m) {
    // Order-independent hash.
    var h = 0;
    for (final e in m.entries) {
      h ^= Object.hash(e.key, e.value);
    }
    return h;
  }
}

/// The core chord qualities the analyzer can name.
///
/// Each token is a complete base quality (triad, sixth, or seventh chord,
/// including suspended and altered-fifth variants); colors beyond the base
/// quality are carried separately as [ChordExtension]s.
enum ChordQuality {
  major,
  majorFlat5,
  minor,
  minorSharp5,
  diminished,
  augmented,
  power,
  sus2,
  sus4,
  sus2sus4,
  major6,
  minor6,
  dominant7,
  dominant7sus2,
  dominant7sus4,
  dominant7Flat5,
  dominant7Sharp5,
  major7,
  major7sus2,
  major7sus4,
  major7Flat5,
  major7Sharp5,
  minor7,
  minor7Sharp5,
  minorMajor7,
  halfDiminished7,
  diminished7,
}

/// Whether a quality is a triad-like or seventh-bearing chord.
enum ChordQualityFamily { triad, seventh }

/// Structural predicates over [ChordQuality].
extension ChordQualitySemantics on ChordQuality {
  /// The [ChordQualityFamily] this quality belongs to.
  ChordQualityFamily get family {
    switch (this) {
      case ChordQuality.dominant7:
      case ChordQuality.dominant7sus2:
      case ChordQuality.dominant7sus4:
      case ChordQuality.dominant7Flat5:
      case ChordQuality.dominant7Sharp5:
      case ChordQuality.major7:
      case ChordQuality.major7sus2:
      case ChordQuality.major7sus4:
      case ChordQuality.major7Flat5:
      case ChordQuality.major7Sharp5:
      case ChordQuality.minor7:
      case ChordQuality.minor7Sharp5:
      case ChordQuality.minorMajor7:
      case ChordQuality.halfDiminished7:
      case ChordQuality.diminished7:
        return ChordQualityFamily.seventh;

      default:
        return ChordQualityFamily.triad;
    }
  }

  /// Whether this quality carries a seventh.
  bool get isSeventhFamily => family == ChordQualityFamily.seventh;

  /// Whether this quality is a sixth chord (major6 or minor6).
  bool get isSixFamily {
    switch (this) {
      case ChordQuality.major6:
      case ChordQuality.minor6:
        return true;
      default:
        return false;
    }
  }

  /// Whether this quality suspends its third (sus2, sus4, or both).
  bool get isSus {
    switch (this) {
      case ChordQuality.sus2:
      case ChordQuality.sus4:
      case ChordQuality.sus2sus4:
      case ChordQuality.dominant7sus2:
      case ChordQuality.dominant7sus4:
      case ChordQuality.major7sus2:
      case ChordQuality.major7sus4:
        return true;
      default:
        return false;
    }
  }

  /// Whether musicians almost never reach for this quality name because it
  /// usually respells a more common chord (the analyzer's rare vocabulary
  /// pricing tier).
  bool get isRareVocabulary {
    switch (this) {
      case ChordQuality.minorSharp5:
      case ChordQuality.minor7Sharp5:
      case ChordQuality.majorFlat5:
      case ChordQuality.major7Flat5:
      case ChordQuality.dominant7sus2:
      case ChordQuality.major7sus2:
        return true;
      default:
        return false;
    }
  }

  /// Whether a raised eleventh is the natural Lydian color on this quality
  /// rather than an alteration.
  ///
  /// On chords built from a natural major third over a perfect fifth (major,
  /// major6, major7), the #11 is the characteristic, consonant Lydian extension
  /// — unlike the genuinely altered colors (b9, #9, b13) or a natural 11, which
  /// clashes with the major third. Treating it as an alteration penalizes the
  /// expected root-position Lydian chord (e.g. B6/9#11) below remote slash
  /// readings. Scoped to these qualities only: on dominant or altered-fifth
  /// chords the #11 participates in the altered-dominant palette and is handled
  /// separately.
  bool get sharp11IsNaturalColor {
    switch (this) {
      case ChordQuality.major:
      case ChordQuality.major6:
      case ChordQuality.major7:
        return true;
      default:
        return false;
    }
  }
}
