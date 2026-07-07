import 'package:meta/meta.dart';

import 'package:whatchord/features/theory/domain/theory_domain.dart';

/// One key hypothesis with the detector's confidence in it.
///
/// Confidence is detector-defined and unitless; it orders hypotheses within a
/// frame and drives that detector's abstention threshold. It is not
/// comparable across detectors.
@immutable
class KeyEstimate {
  final Tonality tonality;
  final double confidence;

  const KeyEstimate({required this.tonality, required this.confidence});

  @override
  String toString() =>
      'KeyEstimate($tonality, ${confidence.toStringAsFixed(3)})';
}

/// A detector's output after one chord event.
///
/// [ranked] is the full hypothesis list, best first, kept for diagnostics.
/// [claim] is the top-1 claim metrics score, or null when the detector
/// abstains; abstention is a first-class outcome, not a failure.
@immutable
class KeyEstimateFrame {
  final List<KeyEstimate> ranked;
  final KeyEstimate? claim;

  const KeyEstimateFrame({required this.ranked, required this.claim});

  const KeyEstimateFrame.abstain(this.ranked) : claim = null;

  bool get isAbstention => claim == null;

  @override
  String toString() => claim == null
      ? 'KeyEstimateFrame(abstain, ${ranked.length} ranked)'
      : 'KeyEstimateFrame($claim, ${ranked.length} ranked)';
}
