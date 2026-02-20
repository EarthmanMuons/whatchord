import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/providers/shared_preferences_provider.dart';

import '../persistence/onboarding_preferences_keys.dart';

final midiSettingsOnboardingProvider =
    NotifierProvider<
      MidiSettingsOnboardingNotifier,
      MidiSettingsOnboardingState
    >(MidiSettingsOnboardingNotifier.new);

class MidiSettingsOnboardingState {
  const MidiSettingsOnboardingState({
    required this.midiSettingsAccessedAt,
    required this.dismissedForSession,
  });

  const MidiSettingsOnboardingState.initial()
    : midiSettingsAccessedAt = null,
      dismissedForSession = false;

  final DateTime? midiSettingsAccessedAt;
  final bool dismissedForSession;

  bool get shouldShowCoachMark =>
      midiSettingsAccessedAt == null && !dismissedForSession;

  MidiSettingsOnboardingState copyWith({
    DateTime? midiSettingsAccessedAt,
    bool? dismissedForSession,
    bool clearMidiSettingsAccessedAt = false,
  }) {
    return MidiSettingsOnboardingState(
      midiSettingsAccessedAt: clearMidiSettingsAccessedAt
          ? null
          : (midiSettingsAccessedAt ?? this.midiSettingsAccessedAt),
      dismissedForSession: dismissedForSession ?? this.dismissedForSession,
    );
  }
}

class MidiSettingsOnboardingNotifier
    extends Notifier<MidiSettingsOnboardingState> {
  @override
  MidiSettingsOnboardingState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final accessedAtMs = prefs.getInt(
      OnboardingPreferencesKeys.midiSettingsAccessedAtMs,
    );

    return MidiSettingsOnboardingState(
      midiSettingsAccessedAt: accessedAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(accessedAtMs),
      dismissedForSession: false,
    );
  }

  void dismissForSession() {
    if (state.midiSettingsAccessedAt != null || state.dismissedForSession) {
      return;
    }
    state = state.copyWith(dismissedForSession: true);
  }

  Future<void> markMidiSettingsAccessed() async {
    if (state.midiSettingsAccessedAt != null) return;

    final now = DateTime.now();
    state = state.copyWith(
      midiSettingsAccessedAt: now,
      dismissedForSession: true,
    );

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(
      OnboardingPreferencesKeys.midiSettingsAccessedAtMs,
      now.millisecondsSinceEpoch,
    );
  }

  Future<void> reset() async {
    state = const MidiSettingsOnboardingState.initial();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(OnboardingPreferencesKeys.midiSettingsAccessedAtMs);
  }
}
