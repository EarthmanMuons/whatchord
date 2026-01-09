import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'activity_tracker.dart';

/// Marks internal activity whenever the app is resumed (e.g., device
/// lock/unlock), so the idle blackout clears even without pointer input.
final appResumeWakeupProvider = Provider<void>((ref) {
  final tracker = ref.read(activityTrackerProvider.notifier);

  final listener = AppLifecycleListener(
    onResume: () {
      // Run after the current lifecycle callback completes.
      scheduleMicrotask(() {
        tracker.markActivity(ActivitySource.internal);
      });
    },
  );

  ref.onDispose(listener.dispose);
});
