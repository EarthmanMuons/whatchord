import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/providers/app_theme_mode_notifier.dart';
import 'package:whatchord/features/theory/domain/models/tonality.dart';
import 'package:whatchord/features/theory/state/providers/selected_tonality_notifier.dart';

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

  void _enterDemo() {
    // Capture current app state so we can restore later.
    _snapshot = _DemoSnapshot(
      themeMode: ref.read(appThemeModeProvider),
      tonality: ref.read(selectedTonalityProvider),
    );

    // Set a known baseline when demo starts.
    ref.read(appThemeModeProvider.notifier).setThemeMode(ThemeMode.light);
    ref
        .read(selectedTonalityProvider.notifier)
        .setTonality(const Tonality('C', TonalityMode.major));
  }

  void _exitDemo() {
    final snap = _snapshot;
    _snapshot = null;
    if (snap == null) return;

    // Restore real app state.
    ref.read(appThemeModeProvider.notifier).setThemeMode(snap.themeMode);
    ref.read(selectedTonalityProvider.notifier).setTonality(snap.tonality);
  }
}

final demoModeProvider = NotifierProvider<DemoModeNotifier, bool>(
  DemoModeNotifier.new,
);
