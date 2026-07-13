import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:whatchord_app/core/providers/shared_preferences_provider.dart';
import 'package:whatchord_app/features/demo/demo.dart';
import 'package:whatchord_app/features/history/history.dart';
import 'package:whatchord_app/features/lookup/lookup.dart';
import 'package:whatchord_app/features/midi/midi_input_source.dart';
import 'package:whatchord_app/features/theory/theory.dart';

class _NotesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => const {};

  void set(Set<int> notes) => state = notes;
}

final _midiNotesProvider = NotifierProvider<_NotesNotifier, Set<int>>(
  _NotesNotifier.new,
);

final _demoNotesProvider = NotifierProvider<_NotesNotifier, Set<int>>(
  _NotesNotifier.new,
);

/// Bypasses the real demo notifier's enter/exit side effects; tests only need
/// the mode flag to flip.
class _StubDemoModeNotifier extends DemoModeNotifier {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const cMajor = {60, 64, 67};
  const fMajor = {65, 69, 72};
  const gMajor = {55, 59, 62};
  const cMajor7 = {60, 64, 67, 71};

  late DateTime now;
  DateTime clock() => now;

  Future<ProviderContainer> makeContainer({
    List<Override> overrides = const [],
  }) async {
    now = DateTime(2026, 1, 1, 12);
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        historyClockProvider.overrideWithValue(clock),
        midiSoundingNoteNumbersProvider.overrideWith(
          (ref) => ref.watch(_midiNotesProvider),
        ),
        demoModeProvider.overrideWith(_StubDemoModeNotifier.new),
        demoSoundingNoteNumbersProvider.overrideWith(
          (ref) => ref.watch(_demoNotesProvider),
        ),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      chordHistoryProvider,
      (previous, next) {},
    );
    addTearDown(subscription.close);
    return container;
  }

  Future<void> play(ProviderContainer container, Set<int> notes) async {
    container.read(_midiNotesProvider.notifier).set(notes);
    await pumpEventQueue();
  }

  void advance(Duration duration) => now = now.add(duration);

  test('commits the previous identity once a new one stabilizes', () async {
    final container = await makeContainer();
    final startedAt = now;

    await play(container, cMajor);
    advance(const Duration(seconds: 2));
    await play(container, fMajor);

    // F has not outlived the debounce yet, so C is still the open chord.
    expect(container.read(chordHistoryProvider), isEmpty);

    advance(const Duration(seconds: 1));
    await play(container, const {});

    final events = container.read(chordHistoryProvider);
    expect(events, hasLength(2));
    expect(events.first.identity.rootPc, 0);
    expect(events.first.identity.quality, ChordQuality.major);
    expect(events.first.timestamp, startedAt);
    // C ended when the F challenger began, not when it stabilized.
    expect(events.first.duration, const Duration(seconds: 2));
    expect(events.last.identity.rootPc, 5);
    expect(events.last.duration, const Duration(seconds: 1));
  });

  test('keeps one continuous event across a transient blip', () async {
    final container = await makeContainer();

    await play(container, cMajor);
    advance(const Duration(seconds: 2));
    await play(container, const {60, 64, 67, 69});
    advance(const Duration(milliseconds: 50));
    await play(container, cMajor);
    advance(const Duration(seconds: 1));
    await play(container, const {});

    final events = container.read(chordHistoryProvider);
    expect(events, hasLength(1));
    expect(events.single.identity.quality, ChordQuality.major);
    // The blip folds into the held chord instead of splitting it.
    expect(
      events.single.duration,
      const Duration(seconds: 3, milliseconds: 50),
    );
  });

  test('debounce timer promotes a stabilized identity by itself', () async {
    final container = await makeContainer();

    await play(container, cMajor);
    advance(const Duration(seconds: 1));
    await play(container, fMajor);
    advance(const Duration(seconds: 1));

    // No further input: the pending timer alone resolves the challenger.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final events = container.read(chordHistoryProvider);
    expect(events, hasLength(1));
    expect(events.single.identity.rootPc, 0);
    expect(events.single.duration, const Duration(seconds: 1));
  });

  test('captures a pedaled overlap as a sequence, not a union chord', () async {
    final container = await makeContainer();

    await play(container, cMajor);
    advance(const Duration(seconds: 2));
    await play(container, {...cMajor, ...fMajor});
    advance(const Duration(milliseconds: 50));
    await play(container, fMajor);
    advance(const Duration(seconds: 1));
    await play(container, const {});

    final events = container.read(chordHistoryProvider);
    expect(events, hasLength(2));
    expect(events.first.identity.rootPc, 0);
    // C runs until the F challenger began; the union blip folds into C.
    expect(events.first.duration, const Duration(seconds: 2, milliseconds: 50));
    expect(events.last.identity.rootPc, 5);
    expect(events.last.duration, const Duration(seconds: 1));
  });

  test('commits the final in-progress chord on release', () async {
    final container = await makeContainer();

    await play(container, cMajor);
    advance(const Duration(seconds: 1));
    await play(container, const {});

    final events = container.read(chordHistoryProvider);
    expect(events, hasLength(1));
    expect(events.single.duration, const Duration(seconds: 1));
  });

  test('drops identities held below the minimum duration', () async {
    final container = await makeContainer();

    await play(container, cMajor);
    advance(const Duration(milliseconds: 50));
    await play(container, fMajor);
    advance(const Duration(seconds: 1));
    await play(container, const {});

    final events = container.read(chordHistoryProvider);
    expect(events, hasLength(1));
    expect(events.single.identity.rootPc, 5);
  });

  test('commits when the sounding set decays below three notes', () async {
    final container = await makeContainer();

    await play(container, cMajor7);
    advance(const Duration(seconds: 1));
    await play(container, const {60});

    var events = container.read(chordHistoryProvider);
    expect(events, hasLength(1));
    expect(events.single.identity.quality, ChordQuality.major7);
    expect(events.single.duration, const Duration(seconds: 1));

    advance(const Duration(seconds: 1));
    await play(container, const {});
    events = container.read(chordHistoryProvider);
    expect(events, hasLength(1));
  });

  test('ignores lookup chords', () async {
    final container = await makeContainer();
    final lookup = container.read(lookupModeProvider.notifier);

    lookup.enter();
    lookup.addNote(0);
    lookup.addNote(4);
    lookup.addNote(7);
    await pumpEventQueue();

    // The analysis chain does see the lookup chord; only capture is gated.
    expect(container.read(chordCandidatesProvider), isNotEmpty);

    advance(const Duration(seconds: 2));
    lookup.exit();
    await pumpEventQueue();

    expect(container.read(chordHistoryProvider), isEmpty);
  });

  test('ignores demo chords, including the toggle-off transition', () async {
    final container = await makeContainer();
    final demo =
        container.read(demoModeProvider.notifier) as _StubDemoModeNotifier;

    demo.set(true);
    await pumpEventQueue();
    container.read(_demoNotesProvider.notifier).set(cMajor);
    await pumpEventQueue();

    expect(container.read(chordCandidatesProvider), isNotEmpty);

    advance(const Duration(seconds: 2));
    demo.set(false);
    await pumpEventQueue();
    container.read(_demoNotesProvider.notifier).set(const {});
    await pumpEventQueue();

    expect(container.read(chordHistoryProvider), isEmpty);

    // Capture resumes for live input once demo is off.
    await play(container, fMajor);
    advance(const Duration(seconds: 1));
    await play(container, const {});
    expect(container.read(chordHistoryProvider), hasLength(1));
  });

  test('preserves ranked candidates and the analysis-time tonality', () async {
    final container = await makeContainer();
    const aMinor = Tonality(Tonic.a, TonalityMode.minor);
    await container.read(selectedTonalityProvider.notifier).setTonality(aMinor);

    // A-C-E-G reads as Am7 with C6 as a near-tie alternative.
    await play(container, const {57, 60, 64, 67});
    advance(const Duration(seconds: 1));
    await play(container, const {});

    final event = container.read(chordHistoryProvider).single;
    expect(event.tonality, aMinor);
    expect(event.identity, event.candidates.first.identity);
    expect(event.cost, event.candidates.first.cost);
    expect(event.candidates.length, greaterThan(1));
    for (var i = 1; i < event.candidates.length; i++) {
      expect(
        event.candidates[i].cost,
        greaterThanOrEqualTo(event.candidates[i - 1].cost),
      );
    }
  });

  test('enforces the history capacity by dropping the oldest', () async {
    final container = await makeContainer(
      overrides: [historyCapacityProvider.overrideWithValue(2)],
    );

    for (final chord in const [cMajor, fMajor, gMajor]) {
      await play(container, chord);
      advance(const Duration(seconds: 1));
    }
    await play(container, const {});

    final events = container.read(chordHistoryProvider);
    expect(events, hasLength(2));
    expect(events.first.identity.rootPc, 5);
    expect(events.last.identity.rootPc, 7);
  });

  test('recentEvents filters by age at read time', () async {
    final container = await makeContainer();

    await play(container, cMajor);
    advance(const Duration(seconds: 2));
    await play(container, fMajor);
    advance(const Duration(seconds: 2));
    await play(container, const {});

    final notifier = container.read(chordHistoryProvider.notifier);
    expect(container.read(chordHistoryProvider), hasLength(2));

    final recent = notifier.recentEvents(const Duration(seconds: 3));
    expect(recent, hasLength(1));
    expect(recent.single.identity.rootPc, 5);

    expect(notifier.recentEvents(const Duration(minutes: 1)), hasLength(2));
  });

  test('clear empties history and abandons the in-progress chord', () async {
    final container = await makeContainer();

    await play(container, cMajor);
    advance(const Duration(seconds: 1));
    await play(container, fMajor);
    advance(const Duration(seconds: 1));

    final notifier = container.read(chordHistoryProvider.notifier);
    notifier.clear();
    expect(container.read(chordHistoryProvider), isEmpty);

    await play(container, const {});
    expect(container.read(chordHistoryProvider), isEmpty);
  });

  test('ChordEvent rejects empty candidates and freezes the list', () async {
    final container = await makeContainer();

    await play(container, cMajor);
    advance(const Duration(seconds: 1));
    await play(container, const {});
    final event = container.read(chordHistoryProvider).single;

    expect(
      () => ChordEvent(
        timestamp: event.timestamp,
        input: event.input,
        voicing: event.voicing,
        candidates: const [],
        tonality: event.tonality,
        duration: event.duration,
      ),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => event.candidates.add(event.candidates.first),
      throwsUnsupportedError,
    );
  });
}
