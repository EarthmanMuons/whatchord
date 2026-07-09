import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:whatchord/core/providers/shared_preferences_provider.dart';
import 'package:whatchord/features/key/key.dart';

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

  test('defaults to stable', () async {
    final container = await makeContainer();
    expect(container.read(keyBehaviorProvider), KeyBehavior.stable);
  });

  test('persists and restores the selected behavior', () async {
    final container = await makeContainer();
    await container
        .read(keyBehaviorProvider.notifier)
        .setBehavior(KeyBehavior.reactive);
    expect(container.read(keyBehaviorProvider), KeyBehavior.reactive);

    final persisted = container
        .read(sharedPreferencesProvider)
        .getString(KeyPreferencesKeys.behavior);
    final restored = await makeContainer({
      KeyPreferencesKeys.behavior: persisted!,
    });
    expect(restored.read(keyBehaviorProvider), KeyBehavior.reactive);
  });

  test('an unknown persisted value falls back to stable', () async {
    final container = await makeContainer({
      KeyPreferencesKeys.behavior: 'frenetic',
    });
    expect(container.read(keyBehaviorProvider), KeyBehavior.stable);
  });

  test('the stable preset matches the shipped constants', () async {
    expect(
      KeyBehavior.stable.emissionHalfLife,
      const Duration(seconds: HmmKeyDetector.defaultEmissionHalfLifeSeconds),
    );
    expect(
      KeyBehavior.stable.displayTemperature,
      DisplayCalibration.temperature,
    );
  });
}
