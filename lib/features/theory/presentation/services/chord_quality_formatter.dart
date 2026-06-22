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

    if (mods.isEmpty) return base;

    final labels = mods.map((e) => e.shortLabel).toList();
    var useParens = _shouldUseParens(
      quality: quality,
      notation: notation,
      mods: mods,
    );

    // Fold an altered fifth that is baked into the base quality label into the
    // single trailing parenthetical group, so a symbol never shows parentheses
    // in the middle of the label or two separate groups.
    //
    // A parenthesized fifth (m7(b5), (b5)) already opens a group, so any
    // trailing modifier must join it: m13(b5)b13 -> m13(b5,b13). A bare fifth
    // (7b5, m#5) only needs grouping when another alteration would collide with
    // it (C9b5b9 -> C9(b5,b9)) or a group is forming for the other modifiers
    // anyway (C7b5(add13) -> C7(b5,add13)); a bare fifth alongside only an
    // inline add-tone stays inline (Em#5add13), since "add" already delimits it.
    final fifthAlt = quality.embeddedFifthAlteration(form);
    if (fifthAlt != null) {
      final parenForm = '($fifthAlt)';
      final fifthIsParenthesized = base.endsWith(parenForm);
      final fifthIsBare = !fifthIsParenthesized && base.endsWith(fifthAlt);
      final hasCollidingMod = mods.any((e) => !e.isAddTone);
      final shouldFold = fifthIsParenthesized || hasCollidingMod || useParens;

      if (shouldFold && (fifthIsParenthesized || fifthIsBare)) {
        final cut = fifthIsParenthesized ? parenForm.length : fifthAlt.length;
        base = base.substring(0, base.length - cut);
        labels.insert(0, fifthAlt);
        useParens = true;
      }
    }

    if (useParens) {
      return '$base(${labels.join(_modsSeparator(notation))})';
    }

    return '$base${labels.join()}';
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
    // Suspended dominant headline: 7sus4 -> 9sus4, 13sus4, etc.
    // Applies to both sus2 and sus4 forms if you add them later.
    if (base.startsWith('7sus')) {
      // Replace the leading '7' with the extension headline.
      return '$ext${base.substring(1)}';
    }

    if (base.startsWith('maj7sus')) {
      return 'maj$ext${base.substring(4)}';
    }

    if (base.contains('7#5')) {
      return base.replaceFirst('7#5', '$ext#5');
    }

    if (base.contains('7♯5')) {
      return base.replaceFirst('7♯5', '$ext♯5');
    }

    if (base.contains('7b5')) {
      return base.replaceFirst('7b5', '${ext}b5');
    }

    if (base.contains('7♭5')) {
      return base.replaceFirst('7♭5', '$ext♭5');
    }

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
