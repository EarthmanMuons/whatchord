import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/providers/app_theme_mode_notifier.dart';
import 'package:whatchord/features/theory/domain/models/tonality.dart';
import 'package:whatchord/features/theory/state/providers/selected_tonality_notifier.dart';

import 'demo_sequence_notifier.dart';

final demoModeProvider = NotifierProvider<DemoModeNotifier, bool>(
  DemoModeNotifier.new,
);

class _DemoSnapshot {
  final ThemeMode themeMode;
  final Tonality tonality;

  const _DemoSnapshot({required this.themeMode, required this.tonality});
}

class DemoModeNotifier extends Notifier<bool> {
  _DemoSnapshot? _snapshot;

  @override
  bool build() => false; // Default to off.

  void setEnabled(bool v) {
    if (v == state) return;
    if (v) {
      _enterDemo();
    } else {
      _exitDemo();
    }
    state = v;
  }

  void toggle() => setEnabled(!state);

  void applyCurrentStep() {
    if (!state) return;

    final seq = ref.read(demoSequenceProvider);
    final step = DemoSequenceNotifier.steps[seq.index];

    if (step.themeMode != null) {
      ref.read(appThemeModeProvider.notifier).setThemeMode(step.themeMode!);
    }
    if (step.tonality != null) {
      ref.read(selectedTonalityProvider.notifier).setTonality(step.tonality!);
    }
  }

  void _enterDemo() {
    _snapshot = _DemoSnapshot(
      themeMode: ref.read(appThemeModeProvider),
      tonality: ref.read(selectedTonalityProvider),
    );

    // Important: apply AFTER providers have finished building.
    Future.microtask(applyCurrentStep);
  }

  void _exitDemo() {
    final snap = _snapshot;
    _snapshot = null;
    if (snap == null) return;

    ref.read(appThemeModeProvider.notifier).setThemeMode(snap.themeMode);
    ref.read(selectedTonalityProvider.notifier).setTonality(snap.tonality);

    // Reset demo sequence so next session starts clean.
    ref.read(demoSequenceProvider.notifier).reset();
  }
}
