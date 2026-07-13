import 'package:meta/meta.dart';

/// How chord qualities render: compact symbols ("Δ7") or spelled text
/// ("maj7").
enum ChordNotationStyle { symbolic, textual }

/// Note naming system for rendered names (C vs. H vs. Do).
enum NoteNameSystem { international, german, fixedDo }

/// A structured chord symbol: root, quality suffix, and optional slash bass.
@immutable
class ChordSymbol {
  /// Canonical ASCII root name (e.g. "C", "F#", "Bb").
  final String root;

  /// Quality suffix as rendered (e.g. "maj", "m7(b5)"; may be empty).
  final String quality;

  /// Slash bass name; null when absent, non-empty and trimmed when present.
  final String? bass;

  const ChordSymbol._({
    required this.root,
    required this.quality,
    required this.bass,
  });

  /// Builds a symbol, normalizing [bass] so it is null or non-empty.
  factory ChordSymbol({
    required String root,
    String quality = '',
    String? bass,
  }) {
    return ChordSymbol._(
      root: root,
      quality: quality,
      bass: _normalizeOptionalToken(bass),
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
    return bass == null ? base : '$base/$bass';
  }

  static String? _normalizeOptionalToken(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
