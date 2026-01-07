import 'package:meta/meta.dart';

import 'chord_symbol.dart';

/// UI-facing identity produced by analysis, depending on input cardinality.
///
/// - 1 note -> NoteDisplay
/// - 2 notes -> IntervalDisplay
/// - 3+ notes -> ChordDisplay
@immutable
sealed class IdentityDisplay {
  const IdentityDisplay({this.secondaryLabel});

  /// Optional second-line label (e.g., "Note", "Interval", "Chord: 1st inversion").
  final String? secondaryLabel;

  bool get hasSecondaryLabel =>
      secondaryLabel != null && secondaryLabel!.trim().isNotEmpty;
}

@immutable
final class NoteDisplay extends IdentityDisplay {
  const NoteDisplay({required this.noteName, super.secondaryLabel});

  final String noteName;
}

@immutable
final class IntervalDisplay extends IdentityDisplay {
  const IntervalDisplay({
    required this.bassName,
    required this.intervalLabel,
    super.secondaryLabel,
  });

  /// The pitch name used as the reference.
  final String bassName;

  /// Interval label text (e.g., "m3", "P8", "m9").
  final String intervalLabel;

  /// Convenience for the primary line (e.g., "C m3").
  String get displayText => '$bassName $intervalLabel';
}

@immutable
final class ChordDisplay extends IdentityDisplay {
  const ChordDisplay({required this.symbol, super.secondaryLabel});

  final ChordSymbol symbol;
}
