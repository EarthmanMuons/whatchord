import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/demo/demo.dart';
import 'package:whatchord/features/lookup/lookup.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../models/chord_event.dart';

/// Memory cap on stored events; the oldest are dropped beyond this count.
final historyCapacityProvider = Provider<int>((ref) => 100);

/// How long an identity must persist to count as real. Serves double duty:
/// a challenger identity must outlive this to end the current chord
/// (debounce), and a committed chord must have been held this long to be
/// recorded. Split into separate providers if tuning ever needs them apart.
final historyMinChordDurationProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 200),
);

/// Clock behind event timestamps and durations; injectable for tests.
final historyClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final chordHistoryProvider =
    NotifierProvider<ChordHistoryNotifier, List<ChordEvent>>(
      ChordHistoryNotifier.new,
    );

typedef _CaptureFrame = ({
  ChordInput input,
  ObservedVoicing voicing,
  List<ChordCandidate> candidates,
  Tonality tonality,
});

extension on _CaptureFrame {
  ChordIdentity get identity => candidates.first.identity;
}

/// The analyzed live chord currently eligible for capture, or null while demo
/// or lookup is active or fewer than three notes sound.
///
/// Gating capture here rather than at commit time is what keeps demo and
/// lookup chords out of history: their toggle-off transitions land after the
/// mode flags have already flipped, so a commit-time check would let a stale
/// non-live chord through.
final _captureFrameProvider = Provider<_CaptureFrame?>((ref) {
  if (ref.watch(demoModeProvider)) return null;
  if (ref.watch(lookupActiveProvider)) return null;

  final candidates = ref.watch(chordCandidatesProvider);
  if (candidates.isEmpty) return null;

  final input = ref.watch(chordInputProvider);
  final voicing = ref.watch(observedVoicingProvider);
  if (input == null || voicing == null) return null;

  final tonality = ref.watch(analysisContextProvider.select((c) => c.tonality));

  // Chosen candidate plus its surfaced near-tie alternatives, so history and
  // the UI agree on what counts as a relevant alternative.
  final relevant = <ChordCandidate>[
    candidates.first,
    ...ChordCandidateRanking.alternatives(candidates),
  ];

  return (
    input: input,
    voicing: voicing,
    candidates: relevant,
    tonality: tonality,
  );
});

/// Sliding-window history of committed live chords, oldest first.
///
/// The unit of history is a held chord identity. A different identity showing
/// up does not end the current chord immediately: it becomes a pending
/// challenger, and only ends (commits) the current chord once it has itself
/// persisted past [historyMinChordDurationProvider]. A challenger that
/// vanishes back into the current identity was a finger roll or passing
/// voicing, and the current chord continues as one uninterrupted event.
/// Release, decay below three notes, and capture gating-off all end the
/// current chord directly.
///
/// Events snapshot their frame (input, voicing, candidates, tonality) at
/// identity onset. Same-identity changes mid-hold, like an added octave
/// doubling or a manual tonality switch, neither update the snapshot nor
/// re-segment the event; the stored candidates stay consistent with the
/// stored tonality they were ranked under.
class ChordHistoryNotifier extends Notifier<List<ChordEvent>> {
  DateTime? _startedAt;
  _CaptureFrame? _current;
  DateTime? _pendingSince;
  _CaptureFrame? _pending;
  Timer? _pendingTimer;

  @override
  List<ChordEvent> build() {
    _startedAt = null;
    _current = null;
    _clearPending();
    ref.onDispose(_clearPending);
    ref.listen(
      _captureFrameProvider,
      (previous, next) => _onFrame(next),
      fireImmediately: true,
    );
    return const [];
  }

  void record(ChordEvent event) {
    final capacity = ref.read(historyCapacityProvider);
    final appended = <ChordEvent>[...state, event];
    final overflow = appended.length - capacity;
    state = List.unmodifiable(
      overflow > 0 ? appended.sublist(overflow) : appended,
    );
  }

  void clear() {
    _startedAt = null;
    _current = null;
    _clearPending();
    state = const [];
  }

  /// Events whose start time falls within [window] of now, oldest first.
  List<ChordEvent> recentEvents(Duration window) {
    final cutoff = ref.read(historyClockProvider)().subtract(window);
    return state.where((e) => !e.timestamp.isBefore(cutoff)).toList();
  }

  void _onFrame(_CaptureFrame? frame) {
    final now = ref.read(historyClockProvider)();
    _resolvePending(now);

    if (frame == null) {
      // The current chord ended when an unresolved challenger began, else now.
      final end = _pendingSince ?? now;
      _clearPending();
      _commitCurrent(end);
      return;
    }

    if (_current != null && frame.identity == _current!.identity) {
      // Back to (or still) the stable identity: any challenger was a blip.
      _clearPending();
      return;
    }

    if (_pending != null && frame.identity == _pending!.identity) {
      // The challenger continues; its stabilization clock keeps running.
      return;
    }

    if (_current == null) {
      // Nothing to protect with a debounce; the identity starts immediately
      // and the commit-time duration check drops it if it turns out fleeting.
      _startedAt = now;
      _current = frame;
      return;
    }

    _clearPending();
    _pendingSince = now;
    _pending = frame;
    _schedulePendingTimer();
  }

  /// Promotes the pending challenger once it has outlived the debounce:
  /// commits the current chord as ending at the challenger's onset, and the
  /// challenger becomes the current chord, backdated to that onset.
  void _resolvePending(DateTime now) {
    final pending = _pending;
    final since = _pendingSince;
    if (pending == null || since == null) return;
    if (now.difference(since) < ref.read(historyMinChordDurationProvider)) {
      return;
    }

    _clearPending();
    _commitCurrent(since);
    _startedAt = since;
    _current = pending;
  }

  void _commitCurrent(DateTime end) {
    final startedAt = _startedAt;
    final frame = _current;
    _startedAt = null;
    _current = null;
    if (startedAt == null || frame == null) return;

    final held = end.difference(startedAt);
    if (held < ref.read(historyMinChordDurationProvider)) return;

    record(
      ChordEvent(
        timestamp: startedAt,
        input: frame.input,
        voicing: frame.voicing,
        candidates: frame.candidates,
        tonality: frame.tonality,
        duration: held,
      ),
    );
  }

  /// Without this timer, a stabilized challenger would only be noticed at the
  /// next input change, delaying the previous chord's commit by one chord.
  void _schedulePendingTimer() {
    _pendingTimer?.cancel();
    _pendingTimer = Timer(ref.read(historyMinChordDurationProvider), () {
      _pendingTimer = null;
      _resolvePending(ref.read(historyClockProvider)());
    });
  }

  void _clearPending() {
    _pendingTimer?.cancel();
    _pendingTimer = null;
    _pendingSince = null;
    _pending = null;
  }
}
