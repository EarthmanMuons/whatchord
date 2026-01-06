import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class MidiActivityState {
  const MidiActivityState({
    required this.lastActivityAt,
    required this.isIdle,
    required this.cooldown,
    required this.hasSeenActivity,
  });

  /// Null means "no MIDI activity has occurred yet in this app run".
  final DateTime? lastActivityAt;

  /// True once we've been inactive for >= cooldown.
  final bool isIdle;

  /// The required quiet period.
  final Duration cooldown;

  /// True once any MIDI activity has happened at least once.
  final bool hasSeenActivity;

  MidiActivityState copyWith({
    DateTime? lastActivityAt,
    bool? isIdle,
    Duration? cooldown,
    bool? hasSeenActivity,
  }) {
    return MidiActivityState(
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      isIdle: isIdle ?? this.isIdle,
      cooldown: cooldown ?? this.cooldown,
      hasSeenActivity: hasSeenActivity ?? this.hasSeenActivity,
    );
  }
}

/// Centralized knob; later you can read from prefs.
final midiIdleCooldownProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 8);
});

final midiActivityProvider =
    NotifierProvider<MidiActivityNotifier, MidiActivityState>(
      MidiActivityNotifier.new,
    );

/// Convenience: "eligible to show MIDI-idle UI" (e.g., your prompt).
/// - True immediately on first load before any MIDI activity.
/// - After MIDI activity occurs, becomes true only after cooldown of silence.
final midiIdleEligibleProvider = Provider<bool>((ref) {
  final s = ref.watch(midiActivityProvider);
  if (!s.hasSeenActivity) return true;
  return s.isIdle;
});

class MidiActivityNotifier extends Notifier<MidiActivityState> {
  Timer? _idleTimer;

  @override
  MidiActivityState build() {
    final cooldown = ref.watch(midiIdleCooldownProvider);

    ref.onDispose(() {
      _idleTimer?.cancel();
      _idleTimer = null;
    });

    // If cooldown changes, reschedule relative to last activity.
    ref.listen<Duration>(midiIdleCooldownProvider, (prev, next) {
      state = state.copyWith(cooldown: next);
      _scheduleIdleTimer();
    });

    final initial = MidiActivityState(
      lastActivityAt: null,
      isIdle:
          true, // "eligible" before any activity is handled via hasSeenActivity=false
      cooldown: cooldown,
      hasSeenActivity: false,
    );

    state = initial;
    return initial;
  }

  /// Call this on any meaningful MIDI interaction (notes/pedal changes, etc.).
  void markMidiActivity() {
    final now = DateTime.now();

    // If you expect extremely frequent MIDI events, throttle a bit.
    final last = state.lastActivityAt;
    final recentlyMarked =
        last != null && now.difference(last) < const Duration(milliseconds: 50);

    if (recentlyMarked) return;

    state = state.copyWith(
      lastActivityAt: now,
      isIdle: false,
      hasSeenActivity: true,
    );

    _scheduleIdleTimer();
  }

  void _scheduleIdleTimer() {
    _idleTimer?.cancel();

    final last = state.lastActivityAt;
    if (last == null) {
      // No activity yet; nothing to schedule.
      return;
    }

    final now = DateTime.now();
    final remaining = state.cooldown - now.difference(last);

    if (remaining <= Duration.zero) {
      if (!state.isIdle) state = state.copyWith(isIdle: true);
      return;
    }

    _idleTimer = Timer(remaining, () {
      // Only flip to idle if no newer activity happened.
      final currentLast = state.lastActivityAt;
      if (currentLast == null) return;

      final quietFor = DateTime.now().difference(currentLast);
      if (quietFor >= state.cooldown) {
        state = state.copyWith(isIdle: true);
      } else {
        // Activity happened close to timer firing; reschedule to be safe.
        _scheduleIdleTimer();
      }
    });
  }
}
