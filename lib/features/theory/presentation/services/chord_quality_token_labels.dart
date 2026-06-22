import '../../domain/theory_domain.dart';

// Example for major seventh -- symbolic: "Δ7", textual: "maj7",
//   academic: "major seventh", idiomatic: "major seven"
enum ChordQualityLabelForm { symbolic, textual, academic, idiomatic }

const _symbolicMinorSign = '−';

/// Formatting-only labels for chord quality tokens.
extension ChordQualityTokenLabels on ChordQualityToken {
  String label(ChordQualityLabelForm form) {
    switch (form) {
      case ChordQualityLabelForm.symbolic:
        return _symbolLabel();
      case ChordQualityLabelForm.textual:
        return _suffixLabel();
      case ChordQualityLabelForm.academic:
        return _longLabel();
      case ChordQualityLabelForm.idiomatic:
        return _spokenLabel();
    }
  }

  String _symbolLabel() {
    switch (this) {
      case ChordQualityToken.major:
        return '';
      case ChordQualityToken.majorFlat5:
        return '(♭5)';
      case ChordQualityToken.minor:
        return _symbolicMinorSign;
      case ChordQualityToken.minorSharp5:
        return '$_symbolicMinorSign♯5';
      case ChordQualityToken.diminished:
        return '°';
      case ChordQualityToken.augmented:
        return '+';
      case ChordQualityToken.sus2:
        return 'sus2';
      case ChordQualityToken.sus4:
        return 'sus4';
      case ChordQualityToken.sus2sus4:
        return 'sus2sus4';
      case ChordQualityToken.major6:
        return '6';
      case ChordQualityToken.minor6:
        return '${_symbolicMinorSign}6';
      case ChordQualityToken.dominant7:
        return '7';
      case ChordQualityToken.dominant7sus2:
        return '7sus2';
      case ChordQualityToken.dominant7sus4:
        return '7sus4';
      case ChordQualityToken.dominant7Flat5:
        return '7♭5';
      case ChordQualityToken.dominant7Sharp5:
        return '7♯5';
      case ChordQualityToken.major7:
        return 'Δ7';
      case ChordQualityToken.major7sus2:
        return 'Δ7sus2';
      case ChordQualityToken.major7sus4:
        return 'Δ7sus4';
      case ChordQualityToken.major7Flat5:
        return 'Δ7♭5';
      case ChordQualityToken.major7Sharp5:
        return 'Δ7♯5';
      case ChordQualityToken.minor7:
        return '${_symbolicMinorSign}7';
      case ChordQualityToken.minor7Sharp5:
        return '${_symbolicMinorSign}7♯5';
      case ChordQualityToken.minorMajor7:
        return '$_symbolicMinorSignΔ7';
      case ChordQualityToken.halfDiminished7:
        return 'ø7';
      case ChordQualityToken.diminished7:
        return '°7';
    }
  }

  String _suffixLabel() {
    switch (this) {
      case ChordQualityToken.major:
        return '';
      case ChordQualityToken.majorFlat5:
        return '(b5)';
      case ChordQualityToken.minor:
        return 'm';
      case ChordQualityToken.minorSharp5:
        return 'm#5';
      case ChordQualityToken.diminished:
        return 'dim';
      case ChordQualityToken.augmented:
        return 'aug';
      case ChordQualityToken.sus2:
        return 'sus2';
      case ChordQualityToken.sus4:
        return 'sus4';
      case ChordQualityToken.sus2sus4:
        return 'sus2sus4';
      case ChordQualityToken.major6:
        return '6';
      case ChordQualityToken.minor6:
        return 'm6';
      case ChordQualityToken.dominant7:
        return '7';
      case ChordQualityToken.dominant7sus2:
        return '7sus2';
      case ChordQualityToken.dominant7sus4:
        return '7sus4';
      case ChordQualityToken.dominant7Flat5:
        return '7b5';
      case ChordQualityToken.dominant7Sharp5:
        return '7#5';
      case ChordQualityToken.major7:
        return 'maj7';
      case ChordQualityToken.major7sus2:
        return 'maj7sus2';
      case ChordQualityToken.major7sus4:
        return 'maj7sus4';
      case ChordQualityToken.major7Flat5:
        return 'maj7b5';
      case ChordQualityToken.major7Sharp5:
        return 'maj7#5';
      case ChordQualityToken.minor7:
        return 'm7';
      case ChordQualityToken.minor7Sharp5:
        return 'm7#5';
      case ChordQualityToken.minorMajor7:
        return 'mM7';
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
      case ChordQualityToken.majorFlat5:
        return 'major flat five';
      case ChordQualityToken.minor:
        return 'minor';
      case ChordQualityToken.minorSharp5:
        return 'minor sharp five';
      case ChordQualityToken.diminished:
        return 'diminished';
      case ChordQualityToken.augmented:
        return 'augmented';
      case ChordQualityToken.sus2:
        return 'suspended second';
      case ChordQualityToken.sus4:
        return 'suspended fourth';
      case ChordQualityToken.sus2sus4:
        return 'suspended second and fourth';
      case ChordQualityToken.major6:
        return 'major sixth';
      case ChordQualityToken.minor6:
        return 'minor sixth';
      case ChordQualityToken.dominant7:
        return 'dominant seventh';
      case ChordQualityToken.dominant7sus2:
        return 'dominant seventh suspended second';
      case ChordQualityToken.dominant7sus4:
        return 'dominant seventh suspended fourth';
      case ChordQualityToken.dominant7Flat5:
        return 'dominant seventh flat five';
      case ChordQualityToken.dominant7Sharp5:
        return 'dominant seventh sharp five';
      case ChordQualityToken.major7:
        return 'major seventh';
      case ChordQualityToken.major7sus2:
        return 'major seventh suspended second';
      case ChordQualityToken.major7sus4:
        return 'major seventh suspended fourth';
      case ChordQualityToken.major7Flat5:
        return 'major seventh flat five';
      case ChordQualityToken.major7Sharp5:
        return 'major seventh sharp five';
      case ChordQualityToken.minor7:
        return 'minor seventh';
      case ChordQualityToken.minor7Sharp5:
        return 'minor seventh sharp five';
      case ChordQualityToken.minorMajor7:
        return 'minor-major seventh';
      case ChordQualityToken.halfDiminished7:
        return 'half-diminished seventh';
      case ChordQualityToken.diminished7:
        return 'diminished seventh';
    }
  }

  String _spokenLabel() {
    switch (this) {
      case ChordQualityToken.major:
        return '';
      case ChordQualityToken.majorFlat5:
        return 'flat five';
      case ChordQualityToken.minor:
        return 'minor';
      case ChordQualityToken.minorSharp5:
        return 'minor sharp five';
      case ChordQualityToken.diminished:
        return 'diminished';
      case ChordQualityToken.augmented:
        return 'augmented';
      case ChordQualityToken.sus2:
        return 'sus two';
      case ChordQualityToken.sus4:
        return 'sus';
      case ChordQualityToken.sus2sus4:
        return 'sus two sus four';
      case ChordQualityToken.major6:
        return 'six';
      case ChordQualityToken.minor6:
        return 'minor six';
      case ChordQualityToken.dominant7:
        return 'seven';
      case ChordQualityToken.dominant7sus2:
        return 'seven sus two';
      case ChordQualityToken.dominant7sus4:
        return 'seven sus';
      case ChordQualityToken.dominant7Flat5:
        return 'seven flat five';
      case ChordQualityToken.dominant7Sharp5:
        return 'seven sharp five';
      case ChordQualityToken.major7:
        return 'major seven';
      case ChordQualityToken.major7sus2:
        return 'major seven sus two';
      case ChordQualityToken.major7sus4:
        return 'major seven sus';
      case ChordQualityToken.major7Flat5:
        return 'major seven flat five';
      case ChordQualityToken.major7Sharp5:
        return 'major seven sharp five';
      case ChordQualityToken.minor7:
        return 'minor seven';
      case ChordQualityToken.minor7Sharp5:
        return 'minor seven sharp five';
      case ChordQualityToken.minorMajor7:
        return 'minor major seven';
      case ChordQualityToken.halfDiminished7:
        return 'half-diminished';
      case ChordQualityToken.diminished7:
        return 'diminished seven';
    }
  }
}

extension ChordQualityTokenAcademicStructure on ChordQualityToken {
  /// The fifth-altering modifier embedded in this quality token's academic label,
  /// if any. The formatter extracts this and folds it into the "with..." phrase
  /// so it joins naturally with other extensions and alterations.
  String? get embeddedAcademicFifthModifier {
    switch (this) {
      case ChordQualityToken.majorFlat5:
      case ChordQualityToken.dominant7Flat5:
      case ChordQualityToken.major7Flat5:
        return 'flat five';
      case ChordQualityToken.minorSharp5:
      case ChordQualityToken.dominant7Sharp5:
      case ChordQualityToken.major7Sharp5:
      case ChordQualityToken.minor7Sharp5:
        return 'sharp five';
      default:
        return null;
    }
  }

  /// The fifth-altering token embedded in this quality's compact
  /// (symbolic/textual) label, whether written bare (7♭5) or parenthesized
  /// (m7(♭5), (♭5)). The symbol formatter strips this from the base and folds it
  /// into a single trailing parenthetical group once the chord carries other
  /// modifiers, so a symbol never shows parentheses in the middle of the label
  /// or two separate groups (e.g. "9♭5♭9" -> "9(♭5,♭9)", "13(♭5)♭13" ->
  /// "13(♭5,♭13)"). A lone altered fifth is left untouched. Returns null where
  /// the fifth is not spelled as a foldable token: the academic and idiomatic
  /// long forms, and the symbolic half-diminished ø, which implies it.
  String? embeddedFifthAlteration(ChordQualityLabelForm form) {
    final bool isFlat;
    switch (this) {
      case ChordQualityToken.majorFlat5:
      case ChordQualityToken.dominant7Flat5:
      case ChordQualityToken.major7Flat5:
      case ChordQualityToken.halfDiminished7:
        isFlat = true;
      case ChordQualityToken.minorSharp5:
      case ChordQualityToken.dominant7Sharp5:
      case ChordQualityToken.major7Sharp5:
      case ChordQualityToken.minor7Sharp5:
        isFlat = false;
      default:
        return null;
    }

    switch (form) {
      case ChordQualityLabelForm.symbolic:
        // The symbolic half-diminished ø implies the ♭5; there is no token.
        if (this == ChordQualityToken.halfDiminished7) return null;
        return isFlat ? '♭5' : '♯5';
      case ChordQualityLabelForm.textual:
        return isFlat ? 'b5' : '#5';
      case ChordQualityLabelForm.academic:
      case ChordQualityLabelForm.idiomatic:
        return null;
    }
  }
}
