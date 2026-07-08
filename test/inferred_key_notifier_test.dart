import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/history/history.dart';
import 'package:whatchord/features/key/key.dart';
import 'package:whatchord/features/theory/theory.dart';

const _cMajorTonality = Tonality(Tonic.c, TonalityMode.major);

ChordEvent _event(int index, List<int> pcs, ChordQualityToken quality) {
  var mask = 0;
  for (final pc in pcs) {
    mask |= 1 << (pc % 12);
  }
  return ChordEvent(
    timestamp: DateTime.fromMillisecondsSinceEpoch(index * 2000),
    input: ChordInput(
      pcMask: mask,
      bassPc: pcs.first % 12,
      noteCount: pcs.length,
    ),
    voicing: ObservedVoicing.fromMidi([for (final pc in pcs) 60 + pc]),
    candidates: [
      ChordCandidate(
        identity: ChordIdentity(
          rootPc: pcs.first % 12,
          bassPc: pcs.first % 12,
          quality: quality,
          presentIntervalsMask: 1,
        ),
        cost: 0,
      ),
    ],
    tonality: _cMajorTonality,
    duration: const Duration(seconds: 2),
  );
}

List<ChordEvent> _cCadence() => [
  _event(0, [0, 4, 7], ChordQualityToken.major),
  _event(1, [5, 9, 0], ChordQualityToken.major),
  _event(2, [7, 11, 2, 5], ChordQualityToken.dominant7),
  _event(3, [0, 4, 7], ChordQualityToken.major),
];

void main() {
  (ProviderContainer, InferredKeyNotifier) setUpContainer({
    Duration staleAfter = const Duration(seconds: 30),
    Duration resetAfter = const Duration(minutes: 2),
  }) {
    final container = ProviderContainer(
      overrides: [
        inferredKeyStaleAfterProvider.overrideWithValue(staleAfter),
        inferredKeyResetAfterProvider.overrideWithValue(resetAfter),
      ],
    );
    addTearDown(container.dispose);
    container.listen(inferredKeyProvider, (_, _) {});
    return (container, container.read(inferredKeyProvider.notifier));
  }

  void record(ProviderContainer container, Iterable<ChordEvent> events) {
    final history = container.read(chordHistoryProvider.notifier);
    events.forEach(history.record);
  }

  test('claims the key from committed history events', () {
    final (container, _) = setUpContainer();
    record(container, _cCadence());

    final state = container.read(inferredKeyProvider);
    expect(state.freshness, InferredKeyFreshness.fresh);
    expect(state.ranked, hasLength(24));
    expect(state.claim, isNotNull);
    expect(state.claim!.tonality.tonicPitchClass, 0);
    expect(state.claim!.tonality.isMajor, isTrue);
    expect(state.displayKey, state.claim);
    expect(state.emphasized, isTrue);
  });

  test('shows no key during warmup abstention', () {
    final (container, _) = setUpContainer();
    record(container, _cCadence().take(2));

    final state = container.read(inferredKeyProvider);
    expect(state.freshness, InferredKeyFreshness.fresh);
    expect(state.claim, isNull);
    expect(state.lastClaim, isNull);
    expect(state.displayKey, isNull);
    expect(state.emphasized, isFalse);
  });

  test(
    'dims after the stale window and forgets after the reset window',
    () async {
      final (container, _) = setUpContainer(
        staleAfter: const Duration(milliseconds: 40),
        resetAfter: const Duration(milliseconds: 120),
      );
      record(container, _cCadence());
      expect(container.read(inferredKeyProvider).emphasized, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 70));
      var state = container.read(inferredKeyProvider);
      expect(state.freshness, InferredKeyFreshness.stale);
      expect(state.displayKey, isNotNull);
      expect(state.emphasized, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      state = container.read(inferredKeyProvider);
      expect(state.freshness, InferredKeyFreshness.none);
      expect(state.displayKey, isNull);
      expect(state.ranked, isEmpty);
    },
  );

  test('a new event within the windows keeps the state fresh', () async {
    final (container, _) = setUpContainer(
      staleAfter: const Duration(milliseconds: 80),
      resetAfter: const Duration(seconds: 10),
    );
    record(container, _cCadence());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    record(container, [
      _event(4, [0, 4, 7], ChordQualityToken.major),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(
      container.read(inferredKeyProvider).freshness,
      InferredKeyFreshness.fresh,
    );
  });

  test('reset after silence restarts the detector warmup', () async {
    final (container, _) = setUpContainer(
      staleAfter: const Duration(milliseconds: 20),
      resetAfter: const Duration(milliseconds: 40),
    );
    record(container, _cCadence());
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(
      container.read(inferredKeyProvider).freshness,
      InferredKeyFreshness.none,
    );

    // One event after a reset must not produce a claim: warmup applies again,
    // proving the detector state was truly discarded.
    record(container, [
      _event(9, [0, 4, 7], ChordQualityToken.major),
    ]);
    final state = container.read(inferredKeyProvider);
    expect(state.freshness, InferredKeyFreshness.fresh);
    expect(state.claim, isNull);
  });

  test('clearing history resets the inferred key', () {
    final (container, _) = setUpContainer();
    record(container, _cCadence());
    expect(container.read(inferredKeyProvider).claim, isNotNull);

    container.read(chordHistoryProvider.notifier).clear();
    final state = container.read(inferredKeyProvider);
    expect(state.freshness, InferredKeyFreshness.none);
    expect(state.displayKey, isNull);
  });

  test('retains the last claim through a later abstention', () {
    final (container, notifier) = setUpContainer();
    record(container, _cCadence());
    final claimed = container.read(inferredKeyProvider).claim;
    expect(claimed, isNotNull);

    // A maximally ambiguous cluster drives the posterior margin down; even if
    // the detector abstains, the display keeps the last claim (dimmed).
    record(container, [
      for (var i = 4; i < 10; i++)
        _event(i, [
          0,
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          10,
          11,
        ], ChordQualityToken.major),
    ]);
    final state = container.read(inferredKeyProvider);
    expect(state.lastClaim, isNotNull);
    expect(state.displayKey, isNotNull);

    notifier.reset();
    expect(container.read(inferredKeyProvider).lastClaim, isNull);
  });
}
