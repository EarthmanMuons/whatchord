import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/providers/shared_preferences_provider.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../models/inferred_key_state.dart';
import '../persistence/key_preferences_keys.dart';
import 'inferred_key_notifier.dart';

/// Who drives the selected tonality: the user through the picker, or the key
/// detector through confident claims.
enum KeyMode { manual, auto }

/// Consecutive events claiming the same key before auto mode adopts it as
/// the selected tonality. Claims are already margin-gated and calm, so this
/// rarely delays adoption; it exists to keep a claim that immediately
/// retracts from respelling the currently sounding chord.
final autoKeyAdoptionStreakProvider = Provider<int>((ref) => 2);

final keyModeProvider = NotifierProvider<KeyModeNotifier, KeyMode>(
  KeyModeNotifier.new,
);

/// Manual/auto key mode plus auto mode's write-back engine.
///
/// In auto mode the selected tonality follows the inferred key: a claim that
/// persists for [autoKeyAdoptionStreakProvider] events (or is already
/// standing fresh when auto is enabled) is adopted via
/// [SelectedTonalityNotifier.setTonality], updating spelling, scale degrees,
/// and ranking context exactly as picking it manually would. Write-back is
/// never silent in manual mode, and any tonality change auto did not write
/// (the picker, a settings restore) drops the mode back to manual so the
/// user always wins.
class KeyModeNotifier extends Notifier<KeyMode> {
  Tonality? _lastAutoWrite;
  Tonality? _streakTonality;
  int _streak = 0;

  @override
  KeyMode build() {
    ref.listen(inferredKeyProvider, _onInferredKey);
    ref.listen(selectedTonalityProvider, _onTonalityChanged);
    final prefs = ref.watch(sharedPreferencesProvider);
    return (prefs.getBool(KeyPreferencesKeys.autoModeEnabled) ?? false)
        ? KeyMode.auto
        : KeyMode.manual;
  }

  Future<void> setMode(KeyMode mode) async {
    if (mode == state) return;
    state = mode;
    if (mode == KeyMode.auto) {
      final inferred = ref.read(inferredKeyProvider);
      if (inferred.claim != null &&
          inferred.freshness == InferredKeyFreshness.fresh) {
        _adopt(inferred.claim!.tonality);
      }
    }
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(
      KeyPreferencesKeys.autoModeEnabled,
      mode == KeyMode.auto,
    );
  }

  void _onInferredKey(InferredKeyState? previous, InferredKeyState next) {
    if (next.freshness == InferredKeyFreshness.none) {
      _streakTonality = null;
      _streak = 0;
      return;
    }
    // Only committed events advance the streak; freshness timer transitions
    // re-emit the same lastEventAt and carry no new evidence.
    if (next.lastEventAt == previous?.lastEventAt) return;
    final claim = next.claim;
    if (claim == null) {
      _streakTonality = null;
      _streak = 0;
      return;
    }
    if (claim.tonality == _streakTonality) {
      _streak += 1;
    } else {
      _streakTonality = claim.tonality;
      _streak = 1;
    }
    if (state == KeyMode.auto &&
        _streak >= ref.read(autoKeyAdoptionStreakProvider)) {
      _adopt(claim.tonality);
    }
  }

  void _adopt(Tonality tonality) {
    _lastAutoWrite = tonality;
    if (tonality == ref.read(selectedTonalityProvider)) return;
    unawaited(
      ref.read(selectedTonalityProvider.notifier).setTonality(tonality),
    );
  }

  void _onTonalityChanged(Tonality? previous, Tonality next) {
    if (state != KeyMode.auto || next == _lastAutoWrite) return;
    state = KeyMode.manual;
    unawaited(
      ref
          .read(sharedPreferencesProvider)
          .setBool(KeyPreferencesKeys.autoModeEnabled, false),
    );
  }
}
