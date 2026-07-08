import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/history/history.dart';

import '../domain/detectors/hmm_key_detector.dart';
import '../models/inferred_key_state.dart';

/// How long without a committed chord before the inferred key is displayed
/// dimmed. Matches the detector's emission half-life: by this point the
/// evidence behind the claim has genuinely half-faded.
final inferredKeyStaleAfterProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 30),
);

/// How long without a committed chord before the detector forgets entirely.
/// The posterior only updates per event, so without this it would hold the
/// previous song's key with full conviction across any silence; past this
/// window a fresh start is more likely than a continuation.
final inferredKeyResetAfterProvider = Provider<Duration>(
  (ref) => const Duration(minutes: 2),
);

final inferredKeyProvider =
    NotifierProvider<InferredKeyNotifier, InferredKeyState>(
      InferredKeyNotifier.new,
    );

/// Live key inference over the committed chord history.
///
/// Owns one [HmmKeyDetector] in the shipped configuration and feeds it each
/// committed event exactly once, in order, never re-running history (the
/// detector is causal and stateful). Detection runs regardless of the
/// manual/auto UI mode so the auto view is warm the moment it opens; the
/// mode only controls presentation and write-back.
///
/// Resets when history is cleared and after [inferredKeyResetAfterProvider]
/// of silence; marks the state stale after [inferredKeyStaleAfterProvider].
class InferredKeyNotifier extends Notifier<InferredKeyState> {
  late HmmKeyDetector _detector;
  Timer? _staleTimer;
  Timer? _resetTimer;

  @override
  InferredKeyState build() {
    _detector = HmmKeyDetector();
    ref.onDispose(_cancelTimers);
    ref.listen(chordHistoryProvider, _onHistory);
    return const InferredKeyState.initial();
  }

  /// Forgets everything: detector posterior, retained claim, timers.
  void reset() {
    _cancelTimers();
    _detector.reset();
    state = const InferredKeyState.initial();
  }

  void _onHistory(List<ChordEvent>? previous, List<ChordEvent> next) {
    if (next.isEmpty) {
      if (previous != null && previous.isNotEmpty) reset();
      return;
    }
    // record() appends exactly one event per state change, so a changed tail
    // is that one new event; an identical tail means no new commit.
    if (previous != null &&
        previous.isNotEmpty &&
        identical(previous.last, next.last)) {
      return;
    }
    _onEvent(next.last);
  }

  void _onEvent(ChordEvent event) {
    final frame = _detector.onEvent(event);
    state = InferredKeyState(
      ranked: frame.ranked,
      claim: frame.claim,
      lastClaim: frame.claim ?? state.lastClaim,
      lastEventAt: ref.read(historyClockProvider)(),
      freshness: InferredKeyFreshness.fresh,
    );
    _rescheduleTimers();
  }

  void _rescheduleTimers() {
    _cancelTimers();
    _staleTimer = Timer(ref.read(inferredKeyStaleAfterProvider), () {
      _staleTimer = null;
      if (state.freshness == InferredKeyFreshness.fresh) {
        state = state.copyWith(freshness: InferredKeyFreshness.stale);
      }
    });
    _resetTimer = Timer(ref.read(inferredKeyResetAfterProvider), reset);
  }

  void _cancelTimers() {
    _staleTimer?.cancel();
    _staleTimer = null;
    _resetTimer?.cancel();
    _resetTimer = null;
  }
}
