import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../input/sounding_notes_providers.dart';

@immutable
class MidiIdleState {
  const MidiIdleState({
    required this.cooldown,
    required this.hasSeenActivity,
    required this.isEngagedNow,
    required this.lastReleaseAt,
    required this.isEligible,
  });

  final Duration cooldown;

  /// True once we have ever observed engagement (notes/pedal) at least once.
  final bool hasSeenActivity;

  /// True while user currently has any keys down (or pedal down if included).
  final bool isEngagedNow;

  /// Timestamp of the most recent "fully released" moment (notes empty + pedal up).
  /// Null until we have ever observed a full release after activity.
  final DateTime? lastReleaseAt;

  /// Convenience: "eligible to show idle UI"
  /// - True on first load (before any activity)
  /// - False while engaged
  /// - True only after cooldown since lastReleaseAt
  final bool isEligible;

  MidiIdleState copyWith({
    Duration? cooldown,
    bool? hasSeenActivity,
    bool? isEngagedNow,
    DateTime? lastReleaseAt,
    bool? isEligible,
  }) {
    return MidiIdleState(
      cooldown: cooldown ?? this.cooldown,
      hasSeenActivity: hasSeenActivity ?? this.hasSeenActivity,
      isEngagedNow: isEngagedNow ?? this.isEngagedNow,
      lastReleaseAt: lastReleaseAt ?? this.lastReleaseAt,
      isEligible: isEligible ?? this.isEligible,
    );
  }
}

final midiIdleCooldownProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 8);
});

final midiIdleProvider = NotifierProvider<MidiIdleNotifier, MidiIdleState>(
  MidiIdleNotifier.new,
);

/// If you prefer a boolean-only API for consumers:
final midiIdleEligibleProvider = Provider<bool>((ref) {
  return ref.watch(midiIdleProvider).isEligible;
});

class MidiIdleNotifier extends Notifier<MidiIdleState> {
  Timer? _timer;

  @override
  MidiIdleState build() {
    final cooldown = ref.watch(midiIdleCooldownProvider);

    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });

    ref.listen<Duration>(midiIdleCooldownProvider, (prev, next) {
      state = state.copyWith(cooldown: next);
      _scheduleFromRelease();
    });

    final initial = MidiIdleState(
      cooldown: cooldown,
      hasSeenActivity: false,
      isEngagedNow: false,
      lastReleaseAt: null,
      isEligible: true,
    );

    state = initial;

    // Engagement is defined strictly by whether any notes are sounding.
    // Sustain pedal state (manual or MIDI) must not directly affect engagement.
    ref.listen<int>(
      soundingNotesProvider.select((s) => s.length),
      (prev, next) => _updateEngagement(engagedNow: next > 0),
      fireImmediately: true,
    );

    return initial;
  }

  void _updateEngagement({required bool engagedNow}) {
    final wasEngaged = state.isEngagedNow;

    // If state didn't actually change, do nothing.
    if (wasEngaged == engagedNow) return;

    // Transition: idle/released -> engaged
    if (engagedNow) {
      _timer?.cancel();
      _timer = null;

      state = state.copyWith(
        hasSeenActivity: true,
        isEngagedNow: true,
        // Not eligible while engaged.
        isEligible: false,
      );
      return;
    }

    // Transition: engaged -> fully released
    final releaseAt = DateTime.now();

    state = state.copyWith(
      hasSeenActivity: true,
      isEngagedNow: false,
      lastReleaseAt: releaseAt,
      // Not eligible until cooldown elapses.
      isEligible: false,
    );

    _scheduleFromRelease();
  }

  void _scheduleFromRelease() {
    _timer?.cancel();
    _timer = null;

    // If we haven't seen any activity ever, stay eligible.
    if (!state.hasSeenActivity) {
      state = state.copyWith(isEligible: true);
      return;
    }

    // If engaged now, never eligible.
    if (state.isEngagedNow) {
      state = state.copyWith(isEligible: false);
      return;
    }

    final releaseAt = state.lastReleaseAt;
    if (releaseAt == null) {
      // We have seen activity but no recorded release yet; be conservative.
      state = state.copyWith(isEligible: false);
      return;
    }

    final now = DateTime.now();
    final remaining = state.cooldown - now.difference(releaseAt);

    if (remaining <= Duration.zero) {
      state = state.copyWith(isEligible: true);
      return;
    }

    _timer = Timer(remaining, () {
      // Only flip eligible if we are still not engaged and the release timestamp
      // hasn't changed under us (i.e., no re-engagement since scheduling).
      final currentReleaseAt = state.lastReleaseAt;
      if (state.isEngagedNow) return;
      if (currentReleaseAt == null) return;

      final quietFor = DateTime.now().difference(currentReleaseAt);
      if (quietFor >= state.cooldown) {
        state = state.copyWith(isEligible: true);
      } else {
        _scheduleFromRelease();
      }
    });
  }
}
