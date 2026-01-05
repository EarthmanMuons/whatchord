import 'package:meta/meta.dart';

import '../../models/chord_symbol.dart';
import 'chord_extension.dart';

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
  final Set<ChordExtension> extensions;

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

  /// Style-aware base “quality” string (what comes after the root).
  String baseLabel(ChordSymbolStyle style) {
    switch (this) {
      case ChordQualityToken.major:
        return style == ChordSymbolStyle.jazz ? 'Δ' : 'maj';
      case ChordQualityToken.minor:
        return style == ChordSymbolStyle.jazz ? '−' : 'm';
      case ChordQualityToken.diminished:
        return style == ChordSymbolStyle.jazz ? '°' : 'dim';
      case ChordQualityToken.augmented:
        return style == ChordSymbolStyle.jazz ? '+' : 'aug';
      case ChordQualityToken.sus2:
        return 'sus2';
      case ChordQualityToken.sus4:
        return 'sus4';
      case ChordQualityToken.power5:
        return '5';
      case ChordQualityToken.major6:
        return '6';
      case ChordQualityToken.minor6:
        return style == ChordSymbolStyle.jazz ? '−6' : 'm6';
      case ChordQualityToken.dominant7:
        return '7';
      case ChordQualityToken.major7:
        return style == ChordSymbolStyle.jazz ? 'Δ7' : 'maj7';
      case ChordQualityToken.minor7:
        return style == ChordSymbolStyle.jazz ? '−7' : 'm7';
      case ChordQualityToken.halfDiminished7:
        return style == ChordSymbolStyle.jazz ? 'ø7' : 'm7(b5)';
      case ChordQualityToken.diminished7:
        return style == ChordSymbolStyle.jazz ? '°7' : 'dim7';
    }
  }

  /// Whether it is conventional to “promote” 9/11/13 into the headline
  /// (C9, C11, C13, Cmaj9, Cm11, etc.) for this quality/style.
  bool allowsHeadlineExtensionPromotion(ChordSymbolStyle style) {
    // Standard notation for m7(b5) is already parenthesized; headline promotion
    // tends to look odd (m9(b5)). Jazz ø9 exists, but you may or may not want it.
    if (this == ChordQualityToken.halfDiminished7 &&
        style == ChordSymbolStyle.standard) {
      return false;
    }
    return isSeventhFamily;
  }
}
