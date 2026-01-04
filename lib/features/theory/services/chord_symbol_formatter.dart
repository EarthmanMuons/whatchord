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

    final has9 = extensions.contains(ChordExtension.nine);
    final has11 = extensions.contains(ChordExtension.eleven);
    final has13 = extensions.contains(ChordExtension.thirteen);

    // Headline promotion: choose highest of 13/11/9 when allowed.
    ChordExtension? headline;
    if (quality.allowsHeadlineExtensionPromotion(style)) {
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

    for (final e in ordered) {
      if (e == headline) continue;

      // Do not show natural 9/11/13 if they were *not* promoted? Conventional is:
      // - If you have 7 + 9 and didn't promote, it's usually because promotion wasn't allowed.
      //   In that case, showing "(9)" is still useful. So keep it.
      //
      // Add-tones are always explicit.
      mods.add(e.label);
    }

    if (mods.isEmpty) return base;

    // Conventional formatting:
    // - alterations and numeric extensions generally in parentheses (7(b9,#11))
    // - add-tones often attached directly: maj7add9 or maj7(add9) both seen
    // We will apply a simple, consistent rule:
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
    if (base.endsWith('7')) return '${base.substring(0, base.length - 1)}$ext';

    return base;
  }
}
