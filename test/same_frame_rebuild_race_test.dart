import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:whatchord/core/providers/shared_preferences_provider.dart';
import 'package:whatchord/features/history/history.dart';
import 'package:whatchord/features/input/input.dart';
import 'package:whatchord/features/key/key.dart';
import 'package:whatchord/features/lookup/lookup.dart';
import 'package:whatchord/features/midi/midi.dart';
import 'package:whatchord/features/midi/models/midi_note_state.dart';
import 'package:whatchord/features/theory/theory.dart';

class _NotesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => const {};

  void set(Set<int> notes) => state = notes;
}

final _midiNotesProvider = NotifierProvider<_NotesNotifier, Set<int>>(
  _NotesNotifier.new,
);

/// Bypasses the real notifier's MIDI plumbing (device manager, plugin
/// streams); the tests drive note numbers through [_midiNotesProvider].
class _StubMidiNoteStateNotifier extends MidiNoteStateNotifier {
  @override
  MidiNoteState build() =>
      const MidiNoteState(pressed: {}, sustained: {}, isPedalDown: false);
}

/// Regression tests for Riverpod's debug-mode assertion "Tried to rebuild
/// ... multiple times in the same frame".
///
/// Listeners of derived providers fire mid-refresh. A callback that
/// synchronously writes state consumed by providers that already rebuilt in
/// the same pass (a write against the dependency flow) trips the assertion
/// and poisons the scheduler for the rest of the session.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  DateTime clock() => now;

  Future<ProviderContainer> makeContainer({
    Map<String, Object> prefsValues = const {},
  }) async {
    now = DateTime(2026, 1, 1, 12);
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        historyClockProvider.overrideWithValue(clock),
        midiNoteStateProvider.overrideWith(_StubMidiNoteStateNotifier.new),
        midiSoundingNoteNumbersProvider.overrideWith(
          (ref) => ref.watch(_midiNotesProvider),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Mirror the app's always-alive consumers (home page widgets and
    // listenManual subscriptions) so the same elements sit in the refresh
    // pass as in production. Display providers are listened first so they
    // rebuild before the capture/history/key chain notifies.
    for (final subscription in [
      container.listen(soundingNotesProvider, (_, _) {}),
      container.listen(identityDisplayProvider, (_, _) {}),
      container.listen(sustainedNoteNumbersProvider, (_, _) {}),
      container.listen(inputIdleEligibleProvider, (_, _) {}),
      container.listen(lookupModeProvider, (_, _) {}),
      container.listen(chordHistoryProvider, (_, _) {}),
      container.listen(inferredKeyProvider, (_, _) {}),
      container.listen(keyModeProvider, (_, _) {}),
      container.listen(selectedTonalityProvider, (_, _) {}),
    ]) {
      addTearDown(subscription.close);
    }
    return container;
  }

  Future<void> play(ProviderContainer container, Set<int> notes) async {
    // Hold each chord well past historyMinChordDurationProvider so the
    // segmenter commits it when the next chord arrives.
    now = now.add(const Duration(seconds: 2));
    container.read(_midiNotesProvider.notifier).set(notes);
    await pumpEventQueue();
  }

  test(
    'live MIDI notes exit lookup without a same-frame rebuild crash',
    () async {
      final container = await makeContainer();
      await pumpEventQueue();

      final lookup = container.read(lookupModeProvider.notifier);
      lookup.enter();
      lookup.addNote(0);
      lookup.addNote(4);
      lookup.addNote(7);
      await pumpEventQueue();

      expect(container.read(lookupModeProvider).active, isTrue);
      expect(container.read(soundingNoteNumbersProvider), isNotEmpty);

      // Live MIDI input arrives while lookup is active: lookup must exit and
      // the sounding notes must switch to the live notes, without tripping
      // Riverpod's same-frame rebuild assertion.
      await play(container, const {60, 64, 67});

      expect(container.read(lookupModeProvider).active, isFalse);
      expect(container.read(soundingNoteNumbersProvider), const {60, 64, 67});
      expect(
        container.read(soundingNotesProvider).map((n) => n.noteNumber).toSet(),
        const {60, 64, 67},
      );
    },
  );

  test(
    'auto key adoption does not crash the pass that commits a chord',
    () async {
      final container = await makeContainer(
        prefsValues: const {KeyPreferencesKeys.autoModeEnabled: true},
      );
      await pumpEventQueue();
      expect(container.read(keyModeProvider), KeyMode.auto);
      expect(
        container.read(selectedTonalityProvider),
        const Tonality(Tonic.c, TonalityMode.major),
      );

      // A G major cadence: each new chord commits the previous one to history,
      // the detector claims G major after warmup, and once the claim streak is
      // reached, auto mode adopts it while the committing refresh pass is
      // still in flight. The adoption must not re-dirty display providers that
      // already rebuilt in that pass.
      const gMajor = {55, 59, 62};
      const cMajor = {48, 52, 55};
      const d7 = {50, 54, 57, 60};
      for (final chord in const [gMajor, cMajor, d7, gMajor, d7, gMajor]) {
        await play(container, chord);
      }

      expect(
        container.read(selectedTonalityProvider),
        const Tonality(Tonic.g, TonalityMode.major),
      );
      expect(container.read(keyModeProvider), KeyMode.auto);
      expect(container.read(soundingNoteNumbersProvider), gMajor);
      expect(
        container.read(soundingNotesProvider).map((n) => n.noteNumber).toSet(),
        gMajor,
      );
    },
  );
}
