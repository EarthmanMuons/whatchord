import 'package:flutter/foundation.dart';

import 'package:whatkey/whatkey.dart';

/// Evidence age for the inferred key, driving the key button's states
/// (Phase 2 integration spec):
///
/// - [none]: no events since startup or the last reset; the button shows the
///   unknown marker.
/// - [fresh]: evidence is current; a claim displays at full emphasis.
/// - [stale]: no chords for the stale window (scaled with the behavior
///   preset, since shorter emission memory fades sooner); the button dims.
///   After the reset window the detector forgets entirely and returns to
///   [none].
enum InferredKeyFreshness { none, fresh, stale }

/// Live output of the key detector for the UI.
///
/// [ranked] and the claims carry the detector's raw posterior confidences;
/// anything shown to the user passes through `DisplayCalibration` first.
@immutable
class InferredKeyState {
  const InferredKeyState({
    required this.ranked,
    required this.claim,
    required this.lastClaim,
    required this.lastEventAt,
    required this.freshness,
    this.resetAt,
  });

  const InferredKeyState.initial({this.resetAt})
    : ranked = const [],
      claim = null,
      lastClaim = null,
      lastEventAt = null,
      freshness = InferredKeyFreshness.none;

  /// Full posterior over the 24 keys, best first; empty before any event.
  final List<KeyEstimate> ranked;

  /// The current margin-gated claim, or null while the detector abstains.
  final KeyEstimate? claim;

  /// The most recent claim, retained through abstention and staleness so the
  /// button can dim it rather than blank it; cleared only by a reset.
  final KeyEstimate? lastClaim;

  /// Wall-clock time the latest chord event was processed.
  final DateTime? lastEventAt;

  final InferredKeyFreshness freshness;

  /// When the detector last forgot everything; history events from before
  /// this moment no longer contribute to the belief (the recent-chords
  /// display uses this to drop them).
  final DateTime? resetAt;

  /// What the key button should render: the current claim, else the retained
  /// last claim (shown dimmed), else nothing (the unknown marker).
  KeyEstimate? get displayKey => claim ?? lastClaim;

  /// True when [displayKey] deserves full emphasis: a live claim on fresh
  /// evidence. Everything else with a [displayKey] renders dimmed.
  bool get emphasized =>
      claim != null && freshness == InferredKeyFreshness.fresh;

  InferredKeyState copyWith({InferredKeyFreshness? freshness}) =>
      InferredKeyState(
        ranked: ranked,
        claim: claim,
        lastClaim: lastClaim,
        lastEventAt: lastEventAt,
        freshness: freshness ?? this.freshness,
        resetAt: resetAt,
      );
}
