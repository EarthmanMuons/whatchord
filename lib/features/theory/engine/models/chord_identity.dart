import 'package:meta/meta.dart';

/// Canonical, style-agnostic chord identity.
///
/// This is the "truth" returned by analysis (before applying naming style,
/// enharmonic spelling, etc.).
@immutable
class ChordIdentity {
  /// Pitch class of the chord root (0..11).
  final int rootPc;

  /// Pitch class of the bass (0..11). If equal to [rootPc], there is no slash bass.
  final int bassPc;

  /// Core quality token (kept intentionally simple for Step 1).
  ///
  /// In Step 2 we will likely replace/expand this with a richer enum structure
  /// (triad quality + seventh quality, etc.).
  final ChordQualityToken quality;

  /// Extensions/modifiers as pitch-class intervals above root (0..11),
  /// encoded as semitone offsets.
  ///
  /// Example: 2(9), 5(11), 9(13), 1(b9), 3(#9), 6(#11), 8(b13), etc.
  final Set<int> extensions;

  const ChordIdentity({
    required this.rootPc,
    required this.bassPc,
    required this.quality,
    this.extensions = const {},
  });

  bool get hasSlashBass => bassPc != rootPc;

  @override
  String toString() =>
      'ChordIdentity(root=$rootPc, bass=$bassPc, quality=$quality, ext=$extensions)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChordIdentity &&
          other.rootPc == rootPc &&
          other.bassPc == bassPc &&
          other.quality == quality &&
          _setEquals(other.extensions, extensions);

  @override
  int get hashCode =>
      Object.hash(rootPc, bassPc, quality, _setHash(extensions));

  static bool _setEquals(Set<int> a, Set<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }

  static int _setHash(Set<int> s) {
    // Order-independent hash for small integer sets.
    var h = 0;
    for (final v in s) {
      h ^= v.hashCode;
    }
    return h;
  }
}

/// Temporary minimal quality token.
///
/// Step 2 will replace this with a richer representation (triad quality,
/// seventh quality, suspended, etc.) that maps cleanly to your existing
/// formatting preferences (standard vs jazz).
enum ChordQualityToken {
  major,
  minor,
  diminished,
  augmented,
  sus2,
  sus4,
  dominant7,
  major7,
  minor7,
  halfDiminished7,
  diminished7,
}
