import 'package:meta/meta.dart';
import 'package:whatchord/whatchord.dart';

/// One key hypothesis with the detector's confidence in it.
///
/// Confidence is detector-defined and unitless; it orders hypotheses within a
/// frame and drives that detector's abstention threshold. It is not
/// comparable across detectors.
@immutable
class KeyEstimate {
  /// The hypothesized key.
  final Tonality tonality;

  /// Detector-defined, unitless confidence; higher is stronger.
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
  /// All key hypotheses, best first.
  final List<KeyEstimate> ranked;

  /// The claimed key, or null when the detector abstains.
  final KeyEstimate? claim;

  const KeyEstimateFrame({required this.ranked, required this.claim});

  /// A frame that declines to claim a key.
  const KeyEstimateFrame.abstain(this.ranked) : claim = null;

  /// Whether the detector declined to claim a key.
  bool get isAbstention => claim == null;

  @override
  String toString() => claim == null
      ? 'KeyEstimateFrame(abstain, ${ranked.length} ranked)'
      : 'KeyEstimateFrame($claim, ${ranked.length} ranked)';
}
