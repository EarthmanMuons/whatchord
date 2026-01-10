import '../engine/models/chord_extension.dart';
import '../engine/models/chord_identity.dart';
import '../models/chord_symbol.dart' show ChordNotationStyle;
import '../services/chord_quality_token_labels.dart';

/// Formats the "quality+extensions" portion of a chord symbol.
class ChordQualityFormatter {
  static String format({
    required ChordQualityToken quality,
    required Set<ChordExtension> extensions,
    required ChordNotationStyle notation,
    ChordQualityLabelForm? qualityFormOverride,
  }) {
    final form = qualityFormOverride ?? _defaultQualityFormFor(notation);

    var base = quality.label(form);

    // Canonical ordering.
    final ordered = extensions.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Conventional 6/9 spelling (a six-family chord plus add9).
    if (quality.isSixFamily && extensions.contains(ChordExtension.add9)) {
      base = '$base/9';
    }

    // Headline promotion (9/11/13) for eligible seventh-family chords.
    final has9 = extensions.contains(ChordExtension.nine);
    final has11 = extensions.contains(ChordExtension.eleven);
    final has13 = extensions.contains(ChordExtension.thirteen);

    ChordExtension? headline;
    if (quality.isSeventhFamily &&
        _allowsHeadlinePromotion(quality: quality, form: form)) {
      if (has13) {
        headline = ChordExtension.thirteen;
      } else if (has11) {
        headline = ChordExtension.eleven;
      } else if (has9) {
        headline = ChordExtension.nine;
      }
    }

    if (headline != null) {
      base = _replaceSeventhWithExtension(base, headline.label);
    }

    final mods = <String>[];
    final absorbedAdd9 = quality.isSixFamily && base.endsWith('/9');

    for (final e in ordered) {
      if (e == headline) continue;
      if (absorbedAdd9 && e == ChordExtension.add9) continue;

      if (headline == ChordExtension.thirteen) {
        if (e == ChordExtension.nine || e == ChordExtension.eleven) continue;
      } else if (headline == ChordExtension.eleven) {
        if (e == ChordExtension.nine) continue;
      }

      mods.add(e.label);
    }

    if (mods.isEmpty) return base;

    final useParens = mods.any(
      (m) =>
          m.startsWith('b') ||
          m.startsWith('#') ||
          m == '9' ||
          m == '11' ||
          m == '13',
    );

    if (useParens) {
      return '$base(${mods.join(',')})';
    }

    return '$base${mods.join()}';
  }

  static ChordQualityLabelForm _defaultQualityFormFor(
    ChordNotationStyle notation,
  ) {
    return notation == ChordNotationStyle.jazz
        ? ChordQualityLabelForm.symbol
        : ChordQualityLabelForm.short;
  }

  /// Whether it is conventional to "promote" 9/11/13 into the headline
  /// (C9, C11, C13, Cmaj9, Cm11, etc.) for this quality/form.
  static bool _allowsHeadlinePromotion({
    required ChordQualityToken quality,
    required ChordQualityLabelForm form,
  }) {
    // The short form for m7(b5) is already parenthesized;
    // headline promotion tends to look odd (m9(b5)).
    if (quality == ChordQualityToken.halfDiminished7 &&
        form == ChordQualityLabelForm.short) {
      return false;
    }

    // Seventh-family qualities are the ones that headline 9/11/13.
    switch (quality) {
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

  static String _replaceSeventhWithExtension(String base, String ext) {
    if (base.contains('(')) return base;

    if (base == '7') return ext;
    if (base.endsWith('7')) {
      return '${base.substring(0, base.length - 1)}$ext';
    }
    return base;
  }
}
