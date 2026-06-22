import '../../domain/theory_domain.dart';
import '../../presentation/models/chord_symbol.dart';
import 'chord_quality_token_labels.dart';

/// Formats the "quality+extensions" portion of a chord symbol.
class ChordQualityFormatter {
  static String format({
    required ChordQualityToken quality,
    required Set<ChordExtension> extensions,
    required ChordNotationStyle notation,
    ChordQualityLabelForm? qualityFormOverride,
  }) {
    final form = qualityFormOverride ?? _defaultQualityFormFor(notation);

    var base = quality.coreLabel(form);

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
      final promoted = _replaceSeventhWithExtension(base, headline.shortLabel);
      if (promoted != base) {
        base = promoted;
      } else {
        // Promotion not supported for this base form; keep headline as a modifier.
        headline = null;
      }
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

    final fifth = quality.fifthModifierLabel(form);

    if (mods.isEmpty) {
      if (fifth == null) return base;
      return quality.fifthParenthesizedWhenLone
          ? '$base($fifth)'
          : '$base$fifth';
    }

    final labels = mods.map((e) => e.shortLabel).toList();
    final useParens = _shouldUseParens(
      quality: quality,
      notation: notation,
      mods: mods,
    );

    if (fifth == null) {
      return useParens
          ? '$base(${labels.join(_modsSeparator(notation))})'
          : '$base${labels.join()}';
    }

    // An altered fifth and other modifiers share one trailing group, so the
    // symbol never has parentheses mid-label or two separate groups. The fifth
    // folds into the group when it is conventionally parenthesized (Cm13(b5,b13)),
    // when another alteration would collide with a bare fifth (C9(b5,b9)), or
    // when a group is forming anyway (C7(b5,add13)). A bare fifth beside a lone
    // inline add-tone stays inline (Em#5add13), since "add" already delimits it.
    final hasCollidingMod = mods.any((e) => !e.isAddTone);
    final fold =
        quality.fifthParenthesizedWhenLone || hasCollidingMod || useParens;

    if (fold) {
      final grouped = [fifth, ...labels].join(_modsSeparator(notation));
      return '$base($grouped)';
    }

    return '$base$fifth${labels.join()}';
  }

  static ChordQualityLabelForm _defaultQualityFormFor(
    ChordNotationStyle notation,
  ) {
    return notation == ChordNotationStyle.symbolic
        ? ChordQualityLabelForm.symbolic
        : ChordQualityLabelForm.textual;
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
      case ChordQualityToken.dominant7sus2:
      case ChordQualityToken.dominant7sus4:
      case ChordQualityToken.dominant7Flat5:
      case ChordQualityToken.dominant7Sharp5:
      case ChordQualityToken.major7:
      case ChordQualityToken.major7sus2:
      case ChordQualityToken.major7sus4:
      case ChordQualityToken.major7Flat5:
      case ChordQualityToken.major7Sharp5:
      case ChordQualityToken.minor7:
      case ChordQualityToken.minor7Sharp5:
      case ChordQualityToken.minorMajor7:
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
    // Suspended headline: 7sus4 -> 9sus4, maj7sus4 -> maj9sus4.
    if (base.startsWith('7sus')) {
      return '$ext${base.substring(1)}';
    }
    if (base.startsWith('maj7sus')) {
      return 'maj$ext${base.substring(4)}';
    }

    // Plain seventh-family cores end in '7': 7 -> 9, maj7 -> maj9, m7 -> m9,
    // Δ7 -> Δ9, ø7 -> ø9, mmaj7 -> mmaj9. Symbolic major7sus (Δ7sus2/Δ7sus4) ends
    // in its suspension and is left unpromoted.
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

    // Suspended seventh-family chords read poorly when modifiers are concatenated:
    // "7sus49" is ambiguous; prefer "7sus4(9)".
    if (quality.isSeventhFamily && quality.isSus) return true;

    // Single modifier: generally inline, except add-tones on seventh-family chords.
    if (mods.length == 1) {
      final ext = mods.first;

      // Added tones read cleanly inline on triad-like qualities, even when
      // altered (Cadd9, Cadd#9, Cadd♭9): the "add" already marks them as
      // non-stacked, so parentheses would be redundant. On seventh-family
      // chords, parentheses still improve readability (C7(add13)).
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
