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
  final ChordQualityToken quality;

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

  const ChordIdentity({
    required this.rootPc,
    required this.bassPc,
    required this.quality,
    this.extensions = const {},
    this.toneRolesByInterval = const {},
  });

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
          _mapEquals(other.toneRolesByInterval, toneRolesByInterval);

  @override
  int get hashCode => Object.hash(
    rootPc,
    bassPc,
    quality,
    _setHash(extensions),
    _mapHash(toneRolesByInterval),
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

enum ChordQualityToken {
  major,
  minor,
  diminished,
  augmented,
  sus2,
  sus4,
  power5,
  major6,
  minor6,
  dominant7,
  major7,
  minor7,
  halfDiminished7,
  diminished7,
}

enum ChordQualityFamily { triad, seventh }

extension ChordQualityTokenSemantics on ChordQualityToken {
  ChordQualityFamily get family {
    switch (this) {
      case ChordQualityToken.dominant7:
      case ChordQualityToken.major7:
      case ChordQualityToken.minor7:
      case ChordQualityToken.halfDiminished7:
      case ChordQualityToken.diminished7:
        return ChordQualityFamily.seventh;

      default:
        return ChordQualityFamily.triad;
    }
  }

  bool get isSeventhFamily => family == ChordQualityFamily.seventh;

  bool get isSixFamily {
    switch (this) {
      case ChordQualityToken.major6:
      case ChordQualityToken.minor6:
        return true;
      default:
        return false;
    }
  }

  bool get isSus {
    switch (this) {
      case ChordQualityToken.sus2:
      case ChordQualityToken.sus4:
        return true;
      default:
        return false;
    }
  }
}
