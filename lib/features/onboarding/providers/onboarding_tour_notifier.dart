import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/providers/shared_preferences_provider.dart';

import '../persistence/onboarding_preferences_keys.dart';

final onboardingTourProvider =
    NotifierProvider<OnboardingTourNotifier, OnboardingTourState>(
      OnboardingTourNotifier.new,
    );

class OnboardingTourState {
  const OnboardingTourState({required this.hasSeenTour});

  const OnboardingTourState.initial() : hasSeenTour = false;

  final bool hasSeenTour;

  /// Whether the guided tour should auto-start (first launch only).
  bool get shouldStartTour => !hasSeenTour;

  OnboardingTourState copyWith({bool? hasSeenTour}) {
    return OnboardingTourState(hasSeenTour: hasSeenTour ?? this.hasSeenTour);
  }
}

class OnboardingTourNotifier extends Notifier<OnboardingTourState> {
  @override
  OnboardingTourState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final hasSeen =
        prefs.getBool(OnboardingPreferencesKeys.hasSeenTour) ?? false;
    return OnboardingTourState(hasSeenTour: hasSeen);
  }

  Future<void> markSeen() async {
    if (state.hasSeenTour) return;

    state = state.copyWith(hasSeenTour: true);

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(OnboardingPreferencesKeys.hasSeenTour, true);
  }

  Future<void> reset() async {
    state = const OnboardingTourState.initial();

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(OnboardingPreferencesKeys.hasSeenTour);
  }
}
