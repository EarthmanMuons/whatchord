import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord_app/core/providers/shared_preferences_provider.dart';

import '../persistence/explore_preferences_keys.dart';

final exploreChordMemberDegreesProvider =
    NotifierProvider<ExploreMemberDegreesNotifier, bool>(
      ExploreMemberDegreesNotifier.new,
    );

class ExploreMemberDegreesNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(ExplorePreferencesKeys.showChordMemberDegrees) ??
        false;
  }

  Future<void> setShowDegrees(bool showDegrees) async {
    state = showDegrees;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(
      ExplorePreferencesKeys.showChordMemberDegrees,
      showDegrees,
    );
  }
}
