import '../../models/chord_identity.dart';

// Example for major seventh -- symbolic: "Δ7", textual: "maj7",
//   academic: "major seventh", idiomatic: "major seven"
enum ChordQualityLabelForm { symbolic, textual, academic, idiomatic }

/// How a quality's altered fifth relates to its perfect fifth.
enum ChordFifthAlteration { none, flat5, sharp5 }

const _symbolicMinorSign = '−';

/// Formatting-only labels for chord quality tokens.
extension ChordQualityTokenLabels on ChordQualityToken {
  /// The conventional label for a chord of this quality with no added
  /// extensions, e.g. "7♭5", "m7(♭5)", "(♭5)", "ø7".
  String label(ChordQualityLabelForm form) {
    final core = coreLabel(form);
    final fifth = fifthModifierLabel(form);
    if (fifth == null) return core;

    switch (form) {
      case ChordQualityLabelForm.symbolic:
      case ChordQualityLabelForm.textual:
        return fifthParenthesizedWhenLone ? '$core($fifth)' : '$core$fifth';
      case ChordQualityLabelForm.academic:
      case ChordQualityLabelForm.idiomatic:
        return core.isEmpty ? fifth : '$core $fifth';
    }
  }

  /// The fifth-free, parenthesis-free quality core, e.g. "7", "maj7", "m7",
  /// "Δ7", "ø7", "dominant seventh". The half-diminished core keeps the fused ø
  /// / "half-diminished" spelling except in textual form, which spells m7 with a
  /// separate ♭5.
  String coreLabel(ChordQualityLabelForm form) {
    switch (form) {
      case ChordQualityLabelForm.symbolic:
        return _coreSymbol();
      case ChordQualityLabelForm.textual:
        return _coreSuffix();
      case ChordQualityLabelForm.academic:
        return _coreLong();
      case ChordQualityLabelForm.idiomatic:
        return _coreSpoken();
    }
  }

  /// How this quality's fifth is altered.
  ChordFifthAlteration get fifthAlteration {
    switch (this) {
      case ChordQualityToken.majorFlat5:
      case ChordQualityToken.dominant7Flat5:
      case ChordQualityToken.major7Flat5:
      case ChordQualityToken.halfDiminished7:
        return ChordFifthAlteration.flat5;
      case ChordQualityToken.minorSharp5:
      case ChordQualityToken.dominant7Sharp5:
      case ChordQualityToken.major7Sharp5:
      case ChordQualityToken.minor7Sharp5:
        return ChordFifthAlteration.sharp5;
      default:
        return ChordFifthAlteration.none;
    }
  }

  /// Whether a lone altered fifth is conventionally parenthesized for this
  /// quality (Cm7(♭5), C(♭5)) rather than written inline (C7♭5, Cm♯5).
  bool get fifthParenthesizedWhenLone =>
      this == ChordQualityToken.majorFlat5 ||
      this == ChordQualityToken.halfDiminished7;

  /// The altered-fifth token for a given form, or null when the fifth is not
  /// spelled separately: when there is none, or when the quality names it in
  /// itself (the symbolic ø and the academic/idiomatic "half-diminished" all
  /// imply the ♭5).
  String? fifthModifierLabel(ChordQualityLabelForm form) {
    final alteration = fifthAlteration;
    if (alteration == ChordFifthAlteration.none) return null;

    // Half-diminished names the fifth into its quality everywhere but textual.
    if (this == ChordQualityToken.halfDiminished7 &&
        form != ChordQualityLabelForm.textual) {
      return null;
    }

    final isFlat = alteration == ChordFifthAlteration.flat5;
    switch (form) {
      case ChordQualityLabelForm.symbolic:
        return isFlat ? '♭5' : '♯5';
      case ChordQualityLabelForm.textual:
        return isFlat ? 'b5' : '#5';
      case ChordQualityLabelForm.academic:
      case ChordQualityLabelForm.idiomatic:
        return isFlat ? 'flat five' : 'sharp five';
    }
  }

  String _coreSymbol() {
    switch (this) {
      case ChordQualityToken.major:
        return '';
      case ChordQualityToken.majorFlat5:
        return '';
      case ChordQualityToken.minor:
        return _symbolicMinorSign;
      case ChordQualityToken.minorSharp5:
        return _symbolicMinorSign;
      case ChordQualityToken.diminished:
        return '°';
      case ChordQualityToken.augmented:
        return '+';
      case ChordQualityToken.power:
        return '5';
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
        return '7';
      case ChordQualityToken.dominant7Sharp5:
        return '7';
      case ChordQualityToken.major7:
        return 'Δ7';
      case ChordQualityToken.major7sus2:
        return 'Δ7sus2';
      case ChordQualityToken.major7sus4:
        return 'Δ7sus4';
      case ChordQualityToken.major7Flat5:
        return 'Δ7';
      case ChordQualityToken.major7Sharp5:
        return 'Δ7';
      case ChordQualityToken.minor7:
        return '${_symbolicMinorSign}7';
      case ChordQualityToken.minor7Sharp5:
        return '${_symbolicMinorSign}7';
      case ChordQualityToken.minorMajor7:
        return '$_symbolicMinorSignΔ7';
      case ChordQualityToken.halfDiminished7:
        return 'ø7';
      case ChordQualityToken.diminished7:
        return '°7';
    }
  }

  String _coreSuffix() {
    switch (this) {
      case ChordQualityToken.major:
        return '';
      case ChordQualityToken.majorFlat5:
        return '';
      case ChordQualityToken.minor:
        return 'm';
      case ChordQualityToken.minorSharp5:
        return 'm';
      case ChordQualityToken.diminished:
        return 'dim';
      case ChordQualityToken.augmented:
        return 'aug';
      case ChordQualityToken.power:
        return '5';
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
        return '7';
      case ChordQualityToken.dominant7Sharp5:
        return '7';
      case ChordQualityToken.major7:
        return 'maj7';
      case ChordQualityToken.major7sus2:
        return 'maj7sus2';
      case ChordQualityToken.major7sus4:
        return 'maj7sus4';
      case ChordQualityToken.major7Flat5:
        return 'maj7';
      case ChordQualityToken.major7Sharp5:
        return 'maj7';
      case ChordQualityToken.minor7:
        return 'm7';
      case ChordQualityToken.minor7Sharp5:
        return 'm7';
      case ChordQualityToken.minorMajor7:
        return 'mmaj7';
      case ChordQualityToken.halfDiminished7:
        return 'm7';
      case ChordQualityToken.diminished7:
        return 'dim7';
    }
  }

  String _coreLong() {
    switch (this) {
      case ChordQualityToken.major:
        return 'major';
      case ChordQualityToken.majorFlat5:
        return 'major';
      case ChordQualityToken.minor:
        return 'minor';
      case ChordQualityToken.minorSharp5:
        return 'minor';
      case ChordQualityToken.diminished:
        return 'diminished';
      case ChordQualityToken.augmented:
        return 'augmented';
      case ChordQualityToken.power:
        return 'power chord';
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
        return 'dominant seventh';
      case ChordQualityToken.dominant7Sharp5:
        return 'dominant seventh';
      case ChordQualityToken.major7:
        return 'major seventh';
      case ChordQualityToken.major7sus2:
        return 'major seventh suspended second';
      case ChordQualityToken.major7sus4:
        return 'major seventh suspended fourth';
      case ChordQualityToken.major7Flat5:
        return 'major seventh';
      case ChordQualityToken.major7Sharp5:
        return 'major seventh';
      case ChordQualityToken.minor7:
        return 'minor seventh';
      case ChordQualityToken.minor7Sharp5:
        return 'minor seventh';
      case ChordQualityToken.minorMajor7:
        return 'minor-major seventh';
      case ChordQualityToken.halfDiminished7:
        return 'half-diminished seventh';
      case ChordQualityToken.diminished7:
        return 'diminished seventh';
    }
  }

  String _coreSpoken() {
    switch (this) {
      case ChordQualityToken.major:
        return '';
      case ChordQualityToken.majorFlat5:
        return '';
      case ChordQualityToken.minor:
        return 'minor';
      case ChordQualityToken.minorSharp5:
        return 'minor';
      case ChordQualityToken.diminished:
        return 'diminished';
      case ChordQualityToken.augmented:
        return 'augmented';
      case ChordQualityToken.power:
        return 'five';
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
        return 'seven';
      case ChordQualityToken.dominant7Sharp5:
        return 'seven';
      case ChordQualityToken.major7:
        return 'major seven';
      case ChordQualityToken.major7sus2:
        return 'major seven sus two';
      case ChordQualityToken.major7sus4:
        return 'major seven sus';
      case ChordQualityToken.major7Flat5:
        return 'major seven';
      case ChordQualityToken.major7Sharp5:
        return 'major seven';
      case ChordQualityToken.minor7:
        return 'minor seven';
      case ChordQualityToken.minor7Sharp5:
        return 'minor seven';
      case ChordQualityToken.minorMajor7:
        return 'minor major seven';
      case ChordQualityToken.halfDiminished7:
        return 'half-diminished';
      case ChordQualityToken.diminished7:
        return 'diminished seven';
    }
  }
}
