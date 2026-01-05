import '../engine/models/chord_extension.dart';
import '../engine/models/chord_identity.dart';
import '../models/chord_symbol.dart';

/// Formats the "quality" portion of a chord symbol (everything after the root),
/// plus optional slash bass is handled by your ChordSymbol.
/// Root spelling is handled elsewhere (note spelling).
class ChordSymbolFormatter {
  static String formatQuality({
    required ChordQualityToken quality,
    required Set<ChordExtension> extensions,
    required ChordSymbolStyle style,
  }) {
    // Base quality string from the enum (style-aware).
    var base = quality.baseLabel(style);

    // Canonical, stable ordering.
    final ordered = extensions.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final isSixChord =
        quality == ChordQualityToken.major6 ||
        quality == ChordQualityToken.minor6;

    if (isSixChord && extensions.contains(ChordExtension.add9)) {
      // Prefer conventional "6/9" spelling.
      // Remove add9 from modifiers later; represent it directly in base.
      base = '$base/9';
    }

    // "Seventh-ness" is determined by the quality token, not by extensions.
    // This is critical: your engine encodes the 7th as part of the chord quality
    // (dominant7 / major7 / minor7 / etc.), not as an explicit extension member.
    final hasSeventhQuality = quality.isSeventhFamily;

    // Only consider true extensions (9/11/13) for headline promotion.
    // add9/add11/add13 are add-tones and should never promote the chord name.
    final has9 = extensions.contains(ChordExtension.nine);
    final has11 = extensions.contains(ChordExtension.eleven);
    final has13 = extensions.contains(ChordExtension.thirteen);

    // Headline promotion: choose highest of 13/11/9 only when:
    // - style allows it AND
    // - the chord is already a seventh-family chord (i.e. "7" exists to replace).
    ChordExtension? headline;
    if (hasSeventhQuality && quality.allowsHeadlineExtensionPromotion(style)) {
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

    final absorbedAdd9 = isSixChord && base.endsWith('/9');

    for (final e in ordered) {
      if (e == headline) continue;
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
    // - alterations and numeric extensions generally in parentheses (7(b9,#11))
    // - add-tones often attached directly: maj7add9 or maj7(add9) both seen
    // We apply a simple, consistent rule:
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
    // Do NOT rewrite complex parenthesized base labels like "m7(b5)".
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
