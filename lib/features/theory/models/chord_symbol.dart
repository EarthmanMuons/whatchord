import 'package:meta/meta.dart';

enum ChordSymbolStyle { leadSheet, jazz }

@immutable
class ChordSymbol {
  final String root; // canonical ASCII, e.g. "C", "F#", "Bb"
  final String quality; // e.g. "maj", "m7(b5)", "" (optional)
  final String? bass; // normalized: null or non-empty, trimmed

  const ChordSymbol._({
    required this.root,
    required this.quality,
    required this.bass,
  });

  /// Use this constructor for normal app code to ensure invariants.
  factory ChordSymbol({
    required String root,
    String quality = '',
    String? bass,
  }) {
    final normalizedBass = _normalizeOptionalToken(bass);
    final normalizedQuality = quality; // optional: normalize if you want
    return ChordSymbol._(
      root: root,
      quality: normalizedQuality,
      bass: normalizedBass,
    );
  }

  /// True iff bass is present (and guaranteed non-empty when true).
  bool get hasBass => bass != null;

  /// Non-nullable accessor you can safely use after checking [hasBass].
  String get bassRequired => bass!;

  /// Optional convenience if you prefer to avoid `!` at call sites.
  String? get bassOrNull => bass;

  @override
  String toString() {
    // Keep this intentionally plain and stable for debugging/logging.
    final base = '$root$quality';
    return bass == null ? base : '$base / $bass';
  }

  static String? _normalizeOptionalToken(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
