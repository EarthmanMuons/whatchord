import '../engine/models/chord_extension.dart';
import '../engine/models/chord_identity.dart';
import '../models/chord_symbol.dart';

// TODO:
// - whether major triads show as maj (standard) vs empty string (common lead sheets)
// - whether minor is m vs min
// - whether alterations should be 7(b9,#11) vs 7(b9,#11,b13) ordering
// - how to treat half-diminished extensions (ø9 style)

/// Formats the "quality" portion of a chord symbol (everything after the root),
/// plus optional slash bass is handled by your ChordSymbol.
/// Root spelling is handled elsewhere (note spelling).
///
/// This keeps analysis separate from presentation rules.
class ChordSymbolFormatter {
  static String formatQuality({
    required ChordQualityToken quality,
    required Set<ChordExtension> extensions,
    required ChordSymbolStyle style,
  }) {
    // 1) Base quality string (style-aware where it matters).
    var base = _baseQuality(quality, style);

    // 2) Promote extensions to headline (9/11/13) when appropriate.
    // We keep this conservative and predictable:
    // - If chord is a 7th family and has 13 -> show 13 (and drop 7).
    // - Else if has 11 -> show 11 (drop 7).
    // - Else if has 9 -> show 9 (drop 7).
    //
    // This matches common lead-sheet conventions.
    final has9 = extensions.contains(ChordExtension.nine);
    final has11 = extensions.contains(ChordExtension.eleven);
    final has13 = extensions.contains(ChordExtension.thirteen);

    final isSevenFamily = _isSevenFamily(quality);

    if (isSevenFamily) {
      if (has13) {
        base = _replaceSevenWith(base, '13');
      } else if (has11) {
        base = _replaceSevenWith(base, '11');
      } else if (has9) {
        base = _replaceSevenWith(base, '9');
      }
    }

    // 3) Build modifiers list: add9/add11/add13 and alterations b9/#9/#11/b13.
    // We do not redundantly print "9" if we promoted to 9/11/13 headline.
    final mods = <String>[];

    void addMod(ChordExtension e, String text) {
      if (extensions.contains(e)) mods.add(text);
    }

    // Adds (only if not promoted):
    if (!isSevenFamily || (!has9 && !has11 && !has13)) {
      addMod(ChordExtension.add9, 'add9');
      addMod(ChordExtension.add11, 'add11');
      addMod(ChordExtension.add13, 'add13');
    } else {
      // If promoted to 9/11/13, add* are not expected.
      // (If they occur, we still show them; they are just uncommon.)
      addMod(ChordExtension.add9, 'add9');
      addMod(ChordExtension.add11, 'add11');
      addMod(ChordExtension.add13, 'add13');
    }

    // Alterations (these commonly appear parenthesized in standard notation).
    // For jazz style you might later choose "alt" or different glyphs; keep it stable for now.
    addMod(ChordExtension.flat9, 'b9');
    addMod(ChordExtension.sharp9, '#9');
    addMod(ChordExtension.sharp11, '#11');
    addMod(ChordExtension.flat13, 'b13');

    if (mods.isEmpty) return base;

    // 4) Apply style formatting. For now:
    // - standard: append in parentheses if any alterations exist, otherwise space-less append for add?
    // To keep it very predictable for users, we will:
    // - if there are any alteration-style tokens (b/#), use parentheses for all mods
    // - else append directly (e.g. "maj7add9") or with parentheses? choose one.
    final hasAlteration = mods.any(
      (m) => m.startsWith('b') || m.startsWith('#'),
    );

    if (hasAlteration) {
      return '$base(${mods.join(',')})';
    }

    // "add9" looks normal without parentheses; keep no separator for typical chord symbols.
    // Example: "maj7add9", "madd11"
    return '$base${mods.join()}';
  }

  static String _baseQuality(ChordQualityToken q, ChordSymbolStyle style) {
    // Standard vs jazz: keep it conservative.
    // You already have a style preference; this mapping is the main hook.
    switch (q) {
      case ChordQualityToken.major:
        return style == ChordSymbolStyle.jazz ? 'Δ' : 'maj';
      case ChordQualityToken.minor:
        return style == ChordSymbolStyle.jazz ? '−' : 'm';
      case ChordQualityToken.diminished:
        return style == ChordSymbolStyle.jazz ? '°' : 'dim';
      case ChordQualityToken.augmented:
        return style == ChordSymbolStyle.jazz ? '+' : 'aug';
      case ChordQualityToken.sus2:
        return 'sus2';
      case ChordQualityToken.sus4:
        return 'sus4';
      case ChordQualityToken.dominant7:
        return '7';
      case ChordQualityToken.major7:
        return style == ChordSymbolStyle.jazz ? 'Δ7' : 'maj7';
      case ChordQualityToken.minor7:
        return style == ChordSymbolStyle.jazz ? '−7' : 'm7';
      case ChordQualityToken.halfDiminished7:
        return style == ChordSymbolStyle.jazz ? 'ø7' : 'm7(b5)';
      case ChordQualityToken.diminished7:
        return style == ChordSymbolStyle.jazz ? '°7' : 'dim7';
    }
  }

  static bool _isSevenFamily(ChordQualityToken q) {
    switch (q) {
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

  static String _replaceSevenWith(String base, String ext) {
    // Examples:
    // - "7" -> "9"
    // - "maj7" -> "maj9"
    // - "Δ7" -> "Δ9"
    // - "m7(b5)" -> "m9(b5)"? (we keep m7(b5) base; headline promotion here is arguable)
    //
    // Conservative: only replace a trailing '7' or a "Δ7"/"−7"/"°7"/"ø7".
    // For "m7(b5)", we do not rewrite to avoid oddities; it will remain "m7(b5)(b9)" etc.
    if (base == '7') return ext;
    if (base.endsWith('7') && !base.contains('(b5)')) {
      return '${base.substring(0, base.length - 1)}$ext';
    }
    return base;
  }
}
