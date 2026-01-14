import '../domain/theory_domain.dart' show ChordQualityToken;

enum ChordQualityLabelForm { symbol, short, long }

/// Formatting-only labels for chord quality tokens.
extension ChordQualityTokenLabels on ChordQualityToken {
  String label(ChordQualityLabelForm form) {
    switch (form) {
      case ChordQualityLabelForm.symbol:
        return _symbolLabel();
      case ChordQualityLabelForm.short:
        return _shortLabel();
      case ChordQualityLabelForm.long:
        return _longLabel();
    }
  }

  String _symbolLabel() {
    switch (this) {
      case ChordQualityToken.major:
        return '';
      case ChordQualityToken.minor:
        return '−';
      case ChordQualityToken.diminished:
        return '°';
      case ChordQualityToken.augmented:
        return '+';
      case ChordQualityToken.sus2:
        return 'sus2';
      case ChordQualityToken.sus4:
        return 'sus4';
      case ChordQualityToken.power5:
        return '5';
      case ChordQualityToken.major6:
        return '6';
      case ChordQualityToken.minor6:
        return '−6';
      case ChordQualityToken.dominant7:
        return '7';
      case ChordQualityToken.major7:
        return 'Δ7';
      case ChordQualityToken.minor7:
        return '−7';
      case ChordQualityToken.halfDiminished7:
        return 'ø7';
      case ChordQualityToken.diminished7:
        return '°7';
    }
  }

  String _shortLabel() {
    switch (this) {
      case ChordQualityToken.major:
        return '';
      case ChordQualityToken.minor:
        return 'm';
      case ChordQualityToken.diminished:
        return 'dim';
      case ChordQualityToken.augmented:
        return 'aug';
      case ChordQualityToken.sus2:
        return 'sus2';
      case ChordQualityToken.sus4:
        return 'sus4';
      case ChordQualityToken.power5:
        return '5';
      case ChordQualityToken.major6:
        return '6';
      case ChordQualityToken.minor6:
        return 'm6';
      case ChordQualityToken.dominant7:
        return '7';
      case ChordQualityToken.major7:
        return 'maj7';
      case ChordQualityToken.minor7:
        return 'm7';
      case ChordQualityToken.halfDiminished7:
        return 'm7(b5)';
      case ChordQualityToken.diminished7:
        return 'dim7';
    }
  }

  String _longLabel() {
    switch (this) {
      case ChordQualityToken.major:
        return 'major';
      case ChordQualityToken.minor:
        return 'minor';
      case ChordQualityToken.diminished:
        return 'diminished';
      case ChordQualityToken.augmented:
        return 'augmented';
      case ChordQualityToken.sus2:
        return 'suspended second';
      case ChordQualityToken.sus4:
        return 'suspended fourth';
      case ChordQualityToken.power5:
        return 'power chord';
      case ChordQualityToken.major6:
        return 'major sixth';
      case ChordQualityToken.minor6:
        return 'minor sixth';
      case ChordQualityToken.dominant7:
        return 'dominant seventh';
      case ChordQualityToken.major7:
        return 'major seventh';
      case ChordQualityToken.minor7:
        return 'minor seventh';
      case ChordQualityToken.halfDiminished7:
        return 'half-diminished seventh';
      case ChordQualityToken.diminished7:
        return 'diminished seventh';
    }
  }
}
