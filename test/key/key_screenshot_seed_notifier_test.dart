import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:whatchord/core/providers/shared_preferences_provider.dart';
import 'package:whatchord/features/history/history.dart';
import 'package:whatchord/features/key/key.dart';
import 'package:whatchord/features/midi/midi.dart';
import 'package:whatchord/features/theory/theory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> makeContainer([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Sever the live MIDI chain so the capture providers never reach the
        // real device manager; the seed records events directly.
        midiSoundingNoteNumbersProvider.overrideWith((ref) => const <int>{}),
      ],
    );
    addTearDown(container.dispose);
    container.listen(inferredKeyProvider, (_, _) {});
    container.listen(keyModeProvider, (_, _) {});
    return container;
  }

  test('seeding records evidence and claims G major in auto mode', () async {
    final container = await makeContainer();
    container.read(keyScreenshotSeedProvider.notifier).toggle();
    // Adoption lands a microtask after the claim (see KeyModeNotifier._adopt).
    await pumpEventQueue();

    expect(container.read(keyScreenshotSeedProvider), isTrue);
    expect(container.read(chordHistoryProvider), isNotEmpty);
    expect(container.read(keyModeProvider), KeyMode.auto);

    final inferred = container.read(inferredKeyProvider);
    expect(inferred.freshness, InferredKeyFreshness.fresh);
    expect(inferred.claim, isNotNull);
    expect(inferred.claim!.tonality.tonicPitchClass, 7);
    expect(inferred.claim!.tonality.isMajor, isTrue);
    // Auto write-back adopted the claimed key.
    expect(container.read(selectedTonalityProvider).tonicPitchClass, 7);
  });

  test('seeded timestamps land after the detector reset marker', () async {
    final container = await makeContainer();
    container.read(keyScreenshotSeedProvider.notifier).toggle();

    // The recent chords strip filters on resetAt when a page reopens
    // mid-session; earlier timestamps would hide the seeded chips.
    final resetAt = container.read(inferredKeyProvider).resetAt;
    expect(resetAt, isNotNull);
    for (final event in container.read(chordHistoryProvider)) {
      expect(event.timestamp.isAfter(resetAt!), isTrue);
    }
  });

  test('toggling off clears evidence and restores mode and tonality', () async {
    final container = await makeContainer();
    final tonalityBefore = container.read(selectedTonalityProvider);
    final notifier = container.read(keyScreenshotSeedProvider.notifier);

    notifier.toggle();
    notifier.toggle();

    expect(container.read(keyScreenshotSeedProvider), isFalse);
    expect(container.read(chordHistoryProvider), isEmpty);
    expect(
      container.read(inferredKeyProvider).freshness,
      InferredKeyFreshness.none,
    );
    expect(container.read(keyModeProvider), KeyMode.manual);
    expect(container.read(selectedTonalityProvider), tonalityBefore);
  });

  test('the seed poses as a live MIDI connection', () async {
    final container = await makeContainer();
    container.read(keyScreenshotSeedProvider.notifier).toggle();

    final status = container.read(midiConnectionStatusProvider);
    expect(status.phase, MidiConnectionPhase.connected);
    expect(status.deviceName, 'Demo MIDI');
  });

  test('a pre-seed auto mode survives the round trip', () async {
    final container = await makeContainer({'key.autoModeEnabled': true});
    expect(container.read(keyModeProvider), KeyMode.auto);

    final notifier = container.read(keyScreenshotSeedProvider.notifier);
    notifier.toggle();
    notifier.toggle();

    expect(container.read(keyModeProvider), KeyMode.auto);
  });
}
