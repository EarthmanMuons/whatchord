import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/providers/shared_preferences_provider.dart';

import '../persistence/onboarding_preferences_keys.dart';

final midiSettingsOnboardingProvider =
    NotifierProvider<
      MidiSettingsOnboardingNotifier,
      MidiSettingsOnboardingState
    >(MidiSettingsOnboardingNotifier.new);

class MidiSettingsOnboardingState {
  const MidiSettingsOnboardingState({required this.hasSeenMidiCoachMark});

  const MidiSettingsOnboardingState.initial() : hasSeenMidiCoachMark = false;

  final bool hasSeenMidiCoachMark;

  bool get shouldShowCoachMark => !hasSeenMidiCoachMark;

  MidiSettingsOnboardingState copyWith({bool? hasSeenMidiCoachMark}) {
    return MidiSettingsOnboardingState(
      hasSeenMidiCoachMark: hasSeenMidiCoachMark ?? this.hasSeenMidiCoachMark,
    );
  }
}

class MidiSettingsOnboardingNotifier
    extends Notifier<MidiSettingsOnboardingState> {
  @override
  MidiSettingsOnboardingState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final hasSeen =
        prefs.getBool(OnboardingPreferencesKeys.hasSeenMidiCoachMark) ?? false;
    return MidiSettingsOnboardingState(hasSeenMidiCoachMark: hasSeen);
  }

  Future<void> markSeen() async {
    if (state.hasSeenMidiCoachMark) return;

    state = state.copyWith(hasSeenMidiCoachMark: true);

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(OnboardingPreferencesKeys.hasSeenMidiCoachMark, true);
  }

  Future<void> reset() async {
    state = const MidiSettingsOnboardingState.initial();

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(OnboardingPreferencesKeys.hasSeenMidiCoachMark);
  }
}
