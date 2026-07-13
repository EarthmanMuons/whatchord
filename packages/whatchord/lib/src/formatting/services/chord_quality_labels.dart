import '../../models/chord_identity.dart';

/// Which naming register a quality label is rendered for.
///
/// Example for major seventh -- symbolic: "Δ7", textual: "maj7",
/// academic: "major seventh", idiomatic: "major seven".
enum ChordQualityLabelForm { symbolic, textual, academic, idiomatic }

/// How a quality's altered fifth relates to its perfect fifth.
enum _Fifth { none, flat, sharp }

const _symbolicMinorSign = '−';

/// Formatting-only labels for chord qualities.
extension ChordQualityLabels on ChordQuality {
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

  _Fifth get _fifth {
    switch (this) {
      case ChordQuality.majorFlat5:
      case ChordQuality.dominant7Flat5:
      case ChordQuality.major7Flat5:
      case ChordQuality.halfDiminished7:
        return _Fifth.flat;
      case ChordQuality.minorSharp5:
      case ChordQuality.dominant7Sharp5:
      case ChordQuality.major7Sharp5:
      case ChordQuality.minor7Sharp5:
        return _Fifth.sharp;
      default:
        return _Fifth.none;
    }
  }

  /// Whether a lone altered fifth is conventionally parenthesized for this
  /// quality (Cm7(♭5), C(♭5)) rather than written inline (C7♭5, Cm♯5).
  bool get fifthParenthesizedWhenLone =>
      this == ChordQuality.majorFlat5 || this == ChordQuality.halfDiminished7;

  /// The altered-fifth token for a given form, or null when the fifth is not
  /// spelled separately: when there is none, or when the quality names it in
  /// itself (the symbolic ø and the academic/idiomatic "half-diminished" all
  /// imply the ♭5).
  String? fifthModifierLabel(ChordQualityLabelForm form) {
    final alteration = _fifth;
    if (alteration == _Fifth.none) return null;

    // Half-diminished names the fifth into its quality everywhere but textual.
    if (this == ChordQuality.halfDiminished7 &&
        form != ChordQualityLabelForm.textual) {
      return null;
    }

    final isFlat = alteration == _Fifth.flat;
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
      case ChordQuality.major:
        return '';
      case ChordQuality.majorFlat5:
        return '';
      case ChordQuality.minor:
        return _symbolicMinorSign;
      case ChordQuality.minorSharp5:
        return _symbolicMinorSign;
      case ChordQuality.diminished:
        return '°';
      case ChordQuality.augmented:
        return '+';
      case ChordQuality.power:
        return '5';
      case ChordQuality.sus2:
        return 'sus2';
      case ChordQuality.sus4:
        return 'sus4';
      case ChordQuality.sus2sus4:
        return 'sus2sus4';
      case ChordQuality.major6:
        return '6';
      case ChordQuality.minor6:
        return '${_symbolicMinorSign}6';
      case ChordQuality.dominant7:
        return '7';
      case ChordQuality.dominant7sus2:
        return '7sus2';
      case ChordQuality.dominant7sus4:
        return '7sus4';
      case ChordQuality.dominant7Flat5:
        return '7';
      case ChordQuality.dominant7Sharp5:
        return '7';
      case ChordQuality.major7:
        return 'Δ7';
      case ChordQuality.major7sus2:
        return 'Δ7sus2';
      case ChordQuality.major7sus4:
        return 'Δ7sus4';
      case ChordQuality.major7Flat5:
        return 'Δ7';
      case ChordQuality.major7Sharp5:
        return 'Δ7';
      case ChordQuality.minor7:
        return '${_symbolicMinorSign}7';
      case ChordQuality.minor7Sharp5:
        return '${_symbolicMinorSign}7';
      case ChordQuality.minorMajor7:
        return '$_symbolicMinorSignΔ7';
      case ChordQuality.halfDiminished7:
        return 'ø7';
      case ChordQuality.diminished7:
        return '°7';
    }
  }

  String _coreSuffix() {
    switch (this) {
      case ChordQuality.major:
        return '';
      case ChordQuality.majorFlat5:
        return '';
      case ChordQuality.minor:
        return 'm';
      case ChordQuality.minorSharp5:
        return 'm';
      case ChordQuality.diminished:
        return 'dim';
      case ChordQuality.augmented:
        return 'aug';
      case ChordQuality.power:
        return '5';
      case ChordQuality.sus2:
        return 'sus2';
      case ChordQuality.sus4:
        return 'sus4';
      case ChordQuality.sus2sus4:
        return 'sus2sus4';
      case ChordQuality.major6:
        return '6';
      case ChordQuality.minor6:
        return 'm6';
      case ChordQuality.dominant7:
        return '7';
      case ChordQuality.dominant7sus2:
        return '7sus2';
      case ChordQuality.dominant7sus4:
        return '7sus4';
      case ChordQuality.dominant7Flat5:
        return '7';
      case ChordQuality.dominant7Sharp5:
        return '7';
      case ChordQuality.major7:
        return 'maj7';
      case ChordQuality.major7sus2:
        return 'maj7sus2';
      case ChordQuality.major7sus4:
        return 'maj7sus4';
      case ChordQuality.major7Flat5:
        return 'maj7';
      case ChordQuality.major7Sharp5:
        return 'maj7';
      case ChordQuality.minor7:
        return 'm7';
      case ChordQuality.minor7Sharp5:
        return 'm7';
      case ChordQuality.minorMajor7:
        return 'mmaj7';
      case ChordQuality.halfDiminished7:
        return 'm7';
      case ChordQuality.diminished7:
        return 'dim7';
    }
  }

  String _coreLong() {
    switch (this) {
      case ChordQuality.major:
        return 'major';
      case ChordQuality.majorFlat5:
        return 'major';
      case ChordQuality.minor:
        return 'minor';
      case ChordQuality.minorSharp5:
        return 'minor';
      case ChordQuality.diminished:
        return 'diminished';
      case ChordQuality.augmented:
        return 'augmented';
      case ChordQuality.power:
        return 'power chord';
      case ChordQuality.sus2:
        return 'suspended second';
      case ChordQuality.sus4:
        return 'suspended fourth';
      case ChordQuality.sus2sus4:
        return 'suspended second and fourth';
      case ChordQuality.major6:
        return 'major sixth';
      case ChordQuality.minor6:
        return 'minor sixth';
      case ChordQuality.dominant7:
        return 'dominant seventh';
      case ChordQuality.dominant7sus2:
        return 'dominant seventh suspended second';
      case ChordQuality.dominant7sus4:
        return 'dominant seventh suspended fourth';
      case ChordQuality.dominant7Flat5:
        return 'dominant seventh';
      case ChordQuality.dominant7Sharp5:
        return 'dominant seventh';
      case ChordQuality.major7:
        return 'major seventh';
      case ChordQuality.major7sus2:
        return 'major seventh suspended second';
      case ChordQuality.major7sus4:
        return 'major seventh suspended fourth';
      case ChordQuality.major7Flat5:
        return 'major seventh';
      case ChordQuality.major7Sharp5:
        return 'major seventh';
      case ChordQuality.minor7:
        return 'minor seventh';
      case ChordQuality.minor7Sharp5:
        return 'minor seventh';
      case ChordQuality.minorMajor7:
        return 'minor-major seventh';
      case ChordQuality.halfDiminished7:
        return 'half-diminished seventh';
      case ChordQuality.diminished7:
        return 'diminished seventh';
    }
  }

  String _coreSpoken() {
    switch (this) {
      case ChordQuality.major:
        return '';
      case ChordQuality.majorFlat5:
        return '';
      case ChordQuality.minor:
        return 'minor';
      case ChordQuality.minorSharp5:
        return 'minor';
      case ChordQuality.diminished:
        return 'diminished';
      case ChordQuality.augmented:
        return 'augmented';
      case ChordQuality.power:
        return 'five';
      case ChordQuality.sus2:
        return 'sus two';
      case ChordQuality.sus4:
        return 'sus';
      case ChordQuality.sus2sus4:
        return 'sus two sus four';
      case ChordQuality.major6:
        return 'six';
      case ChordQuality.minor6:
        return 'minor six';
      case ChordQuality.dominant7:
        return 'seven';
      case ChordQuality.dominant7sus2:
        return 'seven sus two';
      case ChordQuality.dominant7sus4:
        return 'seven sus';
      case ChordQuality.dominant7Flat5:
        return 'seven';
      case ChordQuality.dominant7Sharp5:
        return 'seven';
      case ChordQuality.major7:
        return 'major seven';
      case ChordQuality.major7sus2:
        return 'major seven sus two';
      case ChordQuality.major7sus4:
        return 'major seven sus';
      case ChordQuality.major7Flat5:
        return 'major seven';
      case ChordQuality.major7Sharp5:
        return 'major seven';
      case ChordQuality.minor7:
        return 'minor seven';
      case ChordQuality.minor7Sharp5:
        return 'minor seven';
      case ChordQuality.minorMajor7:
        return 'minor major seven';
      case ChordQuality.halfDiminished7:
        return 'half-diminished';
      case ChordQuality.diminished7:
        return 'diminished seven';
    }
  }
}
