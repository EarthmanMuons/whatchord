import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatkey/whatkey.dart';

import 'package:whatchord_app/core/providers/shared_preferences_provider.dart';

import '../persistence/key_preferences_keys.dart';

final keyBehaviorProvider = NotifierProvider<KeyBehaviorNotifier, KeyBehavior>(
  KeyBehaviorNotifier.new,
);

/// Persisted key detection behavior preset; defaults to the shipped stable
/// configuration. Changing it rebuilds the detector, so detection restarts
/// with the new memory.
class KeyBehaviorNotifier extends Notifier<KeyBehavior> {
  @override
  KeyBehavior build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(KeyPreferencesKeys.behavior);
    return KeyBehavior.values.asNameMap()[saved] ?? KeyBehavior.stable;
  }

  Future<void> setBehavior(KeyBehavior behavior) async {
    if (behavior == state) return;
    state = behavior;
    await ref
        .read(sharedPreferencesProvider)
        .setString(KeyPreferencesKeys.behavior, behavior.name);
  }
}
