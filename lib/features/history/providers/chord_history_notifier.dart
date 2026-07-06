import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/demo/demo.dart';
import 'package:whatchord/features/lookup/lookup.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../models/chord_event.dart';

/// Memory cap on stored events; the oldest are dropped beyond this count.
final historyCapacityProvider = Provider<int>((ref) => 100);

/// Minimum hold time before an identity is committed to history. Filters out
/// finger rolls and passing voicings during transitions.
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
    candidates: List.unmodifiable(relevant),
    tonality: tonality,
  );
});

/// Sliding-window history of committed live chords, oldest first.
///
/// The unit of history is a held chord identity: the in-progress snapshot is
/// committed when a different identity appears, when the sounding set drops
/// out of chord analysis (below three notes), or when capture is gated off.
/// Snapshots held for less than [historyMinChordDurationProvider] are dropped.
class ChordHistoryNotifier extends Notifier<List<ChordEvent>> {
  DateTime? _startedAt;
  _CaptureFrame? _inProgress;

  @override
  List<ChordEvent> build() {
    _startedAt = null;
    _inProgress = null;
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
    _inProgress = null;
    state = const [];
  }

  /// Events whose start time falls within [window] of now, oldest first.
  List<ChordEvent> recentEvents(Duration window) {
    final cutoff = ref.read(historyClockProvider)().subtract(window);
    return state.where((e) => !e.timestamp.isBefore(cutoff)).toList();
  }

  void _onFrame(_CaptureFrame? frame) {
    final now = ref.read(historyClockProvider)();

    if (frame == null) {
      _commit(now);
      return;
    }

    final current = _inProgress;
    if (current != null &&
        current.candidates.first.identity == frame.candidates.first.identity) {
      return;
    }

    _commit(now);
    _startedAt = now;
    _inProgress = frame;
  }

  void _commit(DateTime now) {
    final startedAt = _startedAt;
    final frame = _inProgress;
    _startedAt = null;
    _inProgress = null;
    if (startedAt == null || frame == null) return;

    final held = now.difference(startedAt);
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
}
