import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/providers/shared_preferences_provider.dart';

import '../persistence/scale_preferences_keys.dart';

final showScaleDegreesProvider =
    NotifierProvider<ShowScaleDegreesNotifier, bool>(
      ShowScaleDegreesNotifier.new,
    );

class ShowScaleDegreesNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(ScalePreferencesKeys.showScaleDegrees) ?? false;
  }

  Future<void> setShowDegrees(bool showDegrees) async {
    state = showDegrees;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(ScalePreferencesKeys.showScaleDegrees, showDegrees);
  }
}
