import 'package:meta/meta.dart';
import 'package:whatchord_theory/whatchord_theory.dart';

/// UI-facing identity produced by analysis, depending on input cardinality.
///
/// - 1 note -> NoteDisplay
/// - 2 notes -> IntervalDisplay
/// - 3+ notes -> ChordDisplay
@immutable
sealed class IdentityDisplay {
  const IdentityDisplay({
    required this.longLabel,
    String? semanticLabel,
    this.secondaryLabel,
    this.debugText,
  }) : semanticLabel = semanticLabel ?? longLabel;

  /// User-facing explanation shown in analysis details.
  ///
  /// Examples:
  /// - "C major seventh"
  /// - "F♯ half-diminished seventh over A"
  /// - "Perfect fifth"
  final String longLabel;

  /// Plain-English label for accessibility.
  final String semanticLabel;

  /// Optional second-line label (e.g., "Note", "Interval", "Chord: 1st inversion").
  final String? secondaryLabel;

  /// Optional debug payload; when present, enables "View debug info".
  final String? debugText;

  bool get hasSecondaryLabel =>
      secondaryLabel != null && secondaryLabel!.trim().isNotEmpty;
}

@immutable
final class NoteDisplay extends IdentityDisplay {
  const NoteDisplay({
    required this.noteName,
    required super.longLabel,
    super.secondaryLabel,
    super.debugText,
  });

  final String noteName;
}

@immutable
final class IntervalDisplay extends IdentityDisplay {
  const IntervalDisplay({
    required this.referenceName,
    required this.intervalLabel,
    required super.longLabel,
    super.secondaryLabel,
    super.debugText,
  });

  /// Reference pitch name (typically the bass or chosen anchor).
  final String referenceName;

  /// Interval label text shown as the primary identity (e.g., "Minor 3rd").
  final String intervalLabel;
}

@immutable
final class ChordDisplay extends IdentityDisplay {
  const ChordDisplay({
    required this.symbol,
    required super.longLabel,
    super.semanticLabel,
    super.secondaryLabel,
    super.debugText,
  });

  final ChordSymbol symbol;
}
