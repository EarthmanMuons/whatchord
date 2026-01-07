import '../engine/models/chord_identity.dart' show ChordQualityToken;
import '../models/chord_symbol.dart' show ChordSymbolStyle;

/// Formatting-only labels for chord quality tokens.
extension ChordQualityTokenLabels on ChordQualityToken {
  /// Style-aware base “quality” string (what comes after the root).
  String baseLabel(ChordSymbolStyle style) {
    switch (this) {
      case ChordQualityToken.major:
        return style == ChordSymbolStyle.jazz ? '' : '';
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

  /// Whether it is conventional to "promote" 9/11/13 into the headline
  /// (C9, C11, C13, Cmaj9, Cm11, etc.) for this quality/style.
  bool allowsHeadlineExtensionPromotion(ChordSymbolStyle style) {
    // Lead sheet notation for m7(b5) is already parenthesized; headline promotion
    // tends to look odd (m9(b5)). Jazz ø9 exists, but you may or may not want it.
    if (this == ChordQualityToken.halfDiminished7 &&
        style == ChordSymbolStyle.leadSheet) {
      return false;
    }
    // Seventh-family qualities are the ones that conventionally headline 9/11/13.
    switch (this) {
      case ChordQualityToken.dominant7:
      case ChordQualityToken.major7:
      case ChordQualityToken.minor7:
      case ChordQualityToken.halfDiminished7:
      case ChordQualityToken.diminished7:
        return true;
      default:
        return false;
    }
  }
}
