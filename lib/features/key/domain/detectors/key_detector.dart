import 'package:whatchord_app/features/history/history_domain.dart';

import '../models/key_estimate.dart';

/// A causal, streaming key detector over committed chord events.
///
/// Implementations consume events strictly in order and may keep internal
/// state between events, but must never look ahead: the frame returned for an
/// event reflects only that event and its predecessors. This is the same
/// contract the app's live history stream imposes, and the offline harness
/// replays fixtures through it unchanged.
abstract class KeyDetector {
  /// Stable identifier used in harness reports and logs.
  String get name;

  /// Detector configuration summary for reports; keep it short and complete
  /// enough to reproduce the run.
  String get configuration;

  /// Clears all accumulated state before a new stream.
  void reset();

  /// Consumes the next committed chord event and returns the current frame.
  KeyEstimateFrame onEvent(ChordEvent event);
}
