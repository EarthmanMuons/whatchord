import '../domain/models/chord_extension.dart';
import '../domain/models/chord_identity.dart';
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
      base = _replaceSeventhWithExtension(base, headline.shortLabel);
    }

    final mods = <ChordExtension>[];
    final absorbedAdd9 = quality.isSixFamily && base.endsWith('/9');

    for (final ext in ordered) {
      if (ext == headline) continue;
      if (absorbedAdd9 && ext == ChordExtension.add9) continue;

      if (headline == ChordExtension.thirteen) {
        if (ext == ChordExtension.nine || ext == ChordExtension.eleven) {
          continue;
        }
      } else if (headline == ChordExtension.eleven) {
        if (ext == ChordExtension.nine) continue;
      }

      final displayExt = _displayExtensionFor(quality: quality, ext: ext);
      mods.add(displayExt);
    }

    if (mods.isEmpty) return base;

    final labels = mods.map((e) => e.shortLabel).toList();
    final useParens = _shouldUseParens(
      quality: quality,
      notation: notation,
      mods: mods,
    );

    if (useParens) {
      return '$base(${labels.join(_modsSeparator(notation))})';
    }

    return '$base${labels.join()}';
  }

  static ChordQualityLabelForm _defaultQualityFormFor(
    ChordNotationStyle notation,
  ) {
    return notation == ChordNotationStyle.symbolic
        ? ChordQualityLabelForm.symbol
        : ChordQualityLabelForm.short;
  }

  /// Whether it is conventional to "promote" 9/11/13 into the headline
  /// (C9, C11, C13, Cmaj9, Cm11, etc.) for this quality/form.
  static bool _allowsHeadlinePromotion({
    required ChordQualityToken quality,
    required ChordQualityLabelForm form,
  }) {
    // Seventh-family qualities are the ones that headline 9/11/13.
    switch (quality) {
      case ChordQualityToken.dominant7:
      case ChordQualityToken.major7:
      case ChordQualityToken.minor7:
      case ChordQualityToken.halfDiminished7:
        return true;
      default:
        return false;
    }
  }

  static ChordExtension _displayExtensionFor({
    required ChordQualityToken quality,
    required ChordExtension ext,
  }) {
    // For fully diminished seventh chords, natural extensions are commonly
    // rendered as added tones: Cdim7(add9), Cdim7(add11), etc.
    if (quality == ChordQualityToken.diminished7 && ext.isNaturalExtension) {
      switch (ext) {
        case ChordExtension.nine:
          return ChordExtension.add9;
        case ChordExtension.eleven:
          return ChordExtension.add11;
        case ChordExtension.thirteen:
          return ChordExtension.add13;
        default:
          return ext;
      }
    }
    return ext;
  }

  static String _replaceSeventhWithExtension(String base, String ext) {
    // If base has a parenthetical modifier, we may still be able to promote:
    // e.g. m7(b5) -> m9(b5)
    final idx = base.indexOf('7(');
    if (idx != -1 && base.endsWith(')')) {
      // Replace the '7' at idx with the headline extension.
      return '${base.substring(0, idx)}$ext${base.substring(idx + 1)}';
    }

    if (base.contains('(')) return base;

    if (base == '7') return ext;
    if (base.endsWith('7')) {
      return '${base.substring(0, base.length - 1)}$ext';
    }
    return base;
  }

  static bool _shouldUseParens({
    required ChordQualityToken quality,
    required ChordNotationStyle notation,
    required List<ChordExtension> mods,
  }) {
    if (quality == ChordQualityToken.diminished7) return true;
    if (mods.isEmpty) return false;

    // Single modifier: generally inline, except add-tones on seventh-family chords.
    if (mods.length == 1) {
      final ext = mods.first;

      // Add-tones are formatted differently depending on harmonic "family".
      // For seventh-family chords, parentheses improve readability (C7(add13)).
      // For triad-like qualities (including sus and power chords), inline add-tones
      // are currently preferred (Cadd9, Csus4add9).
      //
      // NOTE: Some notation styles prefer Csus4(add9). If we want to support that
      // distinction later, this branch is the correct place to specialize sus handling.
      if (ext.isAddTone) {
        return quality.isSeventhFamily;
      }
      return false; // b9, #11, 9, 11, 13 inline when alone
    }

    // Multiple modifiers: group them.
    return true;
  }

  static String _modsSeparator(ChordNotationStyle notation) {
    return notation == ChordNotationStyle.symbolic ? '' : ',';
  }
}
