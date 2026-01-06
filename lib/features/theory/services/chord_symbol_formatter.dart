import '../engine/models/chord_extension.dart';
import '../engine/models/chord_identity.dart';
import '../models/chord_symbol.dart';
import '../services/chord_quality_token_labels.dart';

/// Formats the "quality" portion of a chord symbol (everything after the root),
/// plus optional slash bass is handled by your ChordSymbol.
/// Root spelling is handled elsewhere (note spelling).
///
/// This formatter should remain presentation-focused. Musical semantics about
/// chord families (triad/seventh, six-chords, headline promotion eligibility,
/// and base labels) live in the model layer (ChordQualityTokenSemantics).
class ChordSymbolFormatter {
  static String formatQuality({
    required ChordQualityToken quality,
    required Set<ChordExtension> extensions,
    required ChordSymbolStyle style,
  }) {
    // Style-aware base quality string from the model enum.
    var base = quality.baseLabel(style);

    // Canonical, stable ordering.
    final ordered = extensions.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Conventional 6/9 spelling (a six-family chord plus add9).
    if (quality.isSixFamily && extensions.contains(ChordExtension.add9)) {
      // Represent add9 directly in the base ("6/9" or "m6/9") and suppress
      // add9 from modifiers later.
      base = '$base/9';
    }

    // Headline promotion (9/11/13) is only considered for seventh-family chords,
    // and only when the model says it is conventional for this quality/style.
    //
    // Only *natural* extensions (9/11/13) are eligible for headline promotion.
    // add9/add11/add13 are add-tones and should never promote the chord name.
    final has9 = extensions.contains(ChordExtension.nine);
    final has11 = extensions.contains(ChordExtension.eleven);
    final has13 = extensions.contains(ChordExtension.thirteen);

    ChordExtension? headline;
    if (quality.isSeventhFamily &&
        quality.allowsHeadlineExtensionPromotion(style)) {
      // Prefer highest of 13/11/9.
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

    // Build modifier list, in canonical order, excluding headline if promoted.
    final mods = <String>[];

    final absorbedAdd9 = quality.isSixFamily && base.endsWith('/9');

    for (final e in ordered) {
      // Skip the promoted headline extension from modifiers.
      if (e == headline) continue;

      // Skip add9 when absorbed into 6/9.
      if (absorbedAdd9 && e == ChordExtension.add9) continue;

      // If we promoted a headline extension, suppress lower natural extensions
      // that are conventionally implied by the headline.
      if (headline == ChordExtension.thirteen) {
        if (e == ChordExtension.nine || e == ChordExtension.eleven) continue;
      } else if (headline == ChordExtension.eleven) {
        if (e == ChordExtension.nine) continue;
      }

      mods.add(e.label);
    }

    if (mods.isEmpty) return base;

    // Conventional formatting:
    // - alterations and numeric extensions generally in parentheses: 7(b9,#11)
    // - add-tones are often attached directly: maj7add9 / madd11
    //
    // Simple, consistent rule:
    //   - If any mod starts with b/# or is a pure number (9/11/13), use parentheses
    //   - If mods are only addX, append directly (no parentheses)
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

    // e.g. "maj7add9" / "madd11"
    return '$base${mods.join()}';
  }

  static String _replaceSeventhWithExtension(String base, String ext) {
    // Replace the terminal "7" with 9/11/13 for common base labels.
    //
    // Examples:
    // - "7"    -> "9"
    // - "maj7" -> "maj9"
    // - "m7"   -> "m9"
    // - "Δ7"   -> "Δ9"
    // - "−7"   -> "−9"
    // - "ø7"   -> "ø9"
    // - "°7"   -> "°9"
    //
    // Do NOT rewrite complex/parenthesized base labels like "m7(b5)".
    if (base.contains('(')) return base;

    if (base == '7') return ext;
    if (base.endsWith('7')) {
      return '${base.substring(0, base.length - 1)}$ext';
    }

    // If the style's base label does not end with 7 (unexpected for seventh-family),
    // we cannot safely promote, so leave it unchanged.
    return base;
  }
}
