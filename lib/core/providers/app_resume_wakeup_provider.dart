import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_activity_state.dart';
import '../providers/app_activity_notifier.dart';

/// Marks internal activity whenever the app is resumed (e.g., device
/// lock/unlock), so the idle blackout clears even without pointer input.
final appResumeWakeupProvider = Provider<void>((ref) {
  final activity = ref.read(appActivityProvider.notifier);

  final listener = AppLifecycleListener(
    onResume: () {
      // Run after the current lifecycle callback completes.
      scheduleMicrotask(() {
        activity.markActivity(AppActivitySource.internal);
      });
    },
  );

  ref.onDispose(listener.dispose);
});
