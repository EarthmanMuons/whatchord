import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_activity_state.dart';

final appActivityProvider =
    NotifierProvider<AppActivityNotifier, AppActivityState>(
      AppActivityNotifier.new,
    );

final idleAfterProvider = Provider<Duration>((ref) {
  return const Duration(minutes: 2);
});

class AppActivityNotifier extends Notifier<AppActivityState> {
  Timer? _idleTimer;

  @override
  AppActivityState build() {
    final idleAfter = ref.watch(idleAfterProvider);
    final now = DateTime.now();

    ref.onDispose(() {
      _idleTimer?.cancel();
      _idleTimer = null;
    });

    // If idleAfter changes, reschedule relative to last activity.
    ref.listen<Duration>(idleAfterProvider, (prev, next) {
      state = state.copyWith(idleAfter: next);
      _scheduleIdleTimer();
    });

    final initial = AppActivityState(
      lastActivityAt: now,
      isIdle: false,
      idleAfter: idleAfter,
      lastSource: null,
    );

    state = initial;
    _scheduleIdleTimer();
    return initial;
  }

  void markActivity([AppActivitySource source = AppActivitySource.internal]) {
    final now = DateTime.now();

    // Throttle noise while still guaranteeing instant wake from idle.
    final recentlyMarked =
        now.difference(state.lastActivityAt) <
        const Duration(milliseconds: 150);

    if (recentlyMarked && state.isIdle == false) return;

    state = state.copyWith(
      lastActivityAt: now,
      isIdle: false,
      lastSource: source,
    );

    _scheduleIdleTimer();
  }

  void _scheduleIdleTimer() {
    _idleTimer?.cancel();

    final now = DateTime.now();
    final remaining = state.idleAfter - now.difference(state.lastActivityAt);

    if (remaining <= Duration.zero) {
      // Already past idle threshold.
      if (!state.isIdle) state = state.copyWith(isIdle: true);
      return;
    }

    _idleTimer = Timer(remaining, () {
      debugPrint('Idle timer fired; entering idle');
      state = state.copyWith(isIdle: true);
    });
  }
}
