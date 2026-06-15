import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:whatchord/core/providers/shared_preferences_provider.dart';
import 'package:whatchord/features/piano/piano.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> makeContainer([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('defaults to 1.0 scales when nothing is persisted', () async {
    final container = await makeContainer();
    final settings = container.read(pianoViewSettingsProvider);
    expect(settings.widthScale, 1.0);
    expect(settings.heightScale, 1.0);
    expect(settings.isDefault, isTrue);
  });

  test('reads persisted scales, clamped to range', () async {
    final container = await makeContainer({
      'piano.widthScale': 1.5,
      'piano.heightScale': 99.0, // out of range, should clamp to max
    });
    final settings = container.read(pianoViewSettingsProvider);
    expect(settings.widthScale, 1.5);
    expect(settings.heightScale, PianoViewSettings.maxScale);
  });

  test('setWidthScale clamps and persists', () async {
    final container = await makeContainer();
    final notifier = container.read(pianoViewSettingsProvider.notifier);

    await notifier.setWidthScale(2.0);
    expect(container.read(pianoViewSettingsProvider).widthScale, 2.0);

    await notifier.setWidthScale(0.5); // below min
    expect(
      container.read(pianoViewSettingsProvider).widthScale,
      PianoViewSettings.minScale,
    );

    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getDouble('piano.widthScale'), PianoViewSettings.minScale);
  });

  test('reset restores defaults and removes the stored keys', () async {
    final container = await makeContainer({
      'piano.widthScale': 2.0,
      'piano.heightScale': 1.8,
    });
    final notifier = container.read(pianoViewSettingsProvider.notifier);

    await notifier.reset();

    expect(container.read(pianoViewSettingsProvider).isDefault, isTrue);
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getDouble('piano.widthScale'), isNull);
    expect(prefs.getDouble('piano.heightScale'), isNull);
  });
}
