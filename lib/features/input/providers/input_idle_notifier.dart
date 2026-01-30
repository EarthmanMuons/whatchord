import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/demo/providers/demo_mode_notifier.dart';

import 'sounding_notes_providers.dart';

@immutable
class InputIdleState {
  const InputIdleState({
    required this.cooldown,
    required this.hasSeenEngagement,
    required this.isEngagedNow,
    required this.lastReleaseAt,
    required this.isEligible,
  });

  final Duration cooldown;

  /// True once we have ever observed engagement (notes) at least once.
  final bool hasSeenEngagement;

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

  InputIdleState copyWith({
    Duration? cooldown,
    bool? hasSeenEngagement,
    bool? isEngagedNow,
    DateTime? lastReleaseAt,
    bool? isEligible,
  }) {
    return InputIdleState(
      cooldown: cooldown ?? this.cooldown,
      hasSeenEngagement: hasSeenEngagement ?? this.hasSeenEngagement,
      isEngagedNow: isEngagedNow ?? this.isEngagedNow,
      lastReleaseAt: lastReleaseAt ?? this.lastReleaseAt,
      isEligible: isEligible ?? this.isEligible,
    );
  }
}

final inputIdleCooldownProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 8);
});

final inputIdleProvider = NotifierProvider<InputIdleNotifier, InputIdleState>(
  InputIdleNotifier.new,
);

/// If you prefer a boolean-only API for consumers:
final inputIdleEligibleProvider = Provider<bool>((ref) {
  return ref.watch(inputIdleProvider).isEligible;
});

class InputIdleNotifier extends Notifier<InputIdleState> {
  Timer? _timer;

  @override
  InputIdleState build() {
    final cooldown = ref.watch(inputIdleCooldownProvider);

    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });

    ref.listen<Duration>(inputIdleCooldownProvider, (prev, next) {
      state = state.copyWith(cooldown: next);
      _scheduleFromRelease();
    });

    final initial = InputIdleState(
      cooldown: cooldown,
      hasSeenEngagement: false,
      isEngagedNow: false,
      lastReleaseAt: null,
      isEligible: true,
    );

    state = initial;

    // When demo mode is turning OFF.
    ref.listen<bool>(demoModeProvider, (prev, next) {
      if (prev == true && next == false) {
        markIdleNow();
      }
    });

    // Engagement is defined strictly by whether any notes are sounding.
    // Sustain pedal state (manual or MIDI) must not directly affect engagement.
    ref.listen<int>(
      soundingNotesProvider.select((s) => s.length),
      (prev, next) => _updateEngagement(engagedNow: next > 0),
      fireImmediately: true,
    );

    return initial;
  }

  /// Marks input as idle and immediately eligible.
  ///
  /// Useful when exiting demo / onboarding flows that inject notes through
  /// real plumbing and should not wait out the idle cooldown.
  void markIdleNow() {
    _timer?.cancel();
    _timer = null;

    final now = DateTime.now();

    state = state.copyWith(
      hasSeenEngagement: true,
      isEngagedNow: false,
      // Backdate the release so cooldown is already satisfied.
      lastReleaseAt: now.subtract(state.cooldown),
      isEligible: true,
    );
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
        hasSeenEngagement: true,
        isEngagedNow: true,
        // Not eligible while engaged.
        isEligible: false,
      );
      return;
    }

    // Transition: engaged -> fully released
    final releaseAt = DateTime.now();

    state = state.copyWith(
      hasSeenEngagement: true,
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
    if (!state.hasSeenEngagement) {
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
