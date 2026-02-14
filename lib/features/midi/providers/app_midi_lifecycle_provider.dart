import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../midi_debug.dart';
import '../providers/midi_connection_notifier.dart';
import '../providers/midi_device_manager.dart';
import '../providers/midi_preferences_notifier.dart';

/// Installs app-wide MIDI lifecycle handling to coordinate behavior across
/// background and foreground transitions.
final appMidiLifecycleProvider = Provider<void>((ref) {
  final controller = _MidiLifecycleController(ref);
  controller._attach();
  ref.onDispose(controller._detach);
});

class _MidiLifecycleController with WidgetsBindingObserver {
  final Ref _ref;
  _MidiLifecycleController(this._ref);

  static const bool _debugLog = midiDebug;

  bool _attached = false;

  void _attach() {
    if (_attached) return;
    _attached = true;
    if (_debugLog) debugPrint('[LIFE] attach');
    WidgetsBinding.instance.addObserver(this);

    // Ensure the MIDI device manager is created early so it can install listeners and seed state.
    _ref.read(midiDeviceManagerProvider);

    // Attempt reconnect at startup (foreground).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = _ref.read(midiPreferencesProvider);
      final lastConnectedId = prefs.lastConnectedDeviceId;

      if (_debugLog) {
        debugPrint(
          '[LIFE] startup autoReconnect=${prefs.autoReconnect} '
          'lastId=${lastConnectedId ?? "null"}',
        );
      }
      if (prefs.autoReconnect &&
          lastConnectedId != null &&
          lastConnectedId.trim().isNotEmpty) {
        _ref
            .read(midiConnectionStateProvider.notifier)
            .tryAutoReconnect(reason: 'startup');
      }
    });
  }

  void _detach() {
    if (!_attached) return;
    _attached = false;
    if (_debugLog) debugPrint('[LIFE] detach');
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final connectionState = _ref.read(midiConnectionStateProvider.notifier);
    final midi = _ref.read(midiDeviceManagerProvider.notifier);

    if (_debugLog) debugPrint('[LIFE] state=$state');
    switch (state) {
      case AppLifecycleState.resumed:
        midi.setBackgrounded(false);
        connectionState.setBackgrounded(false);

        // IMPORTANT: On iOS especially, the OS may drop Bluetooth connections while the
        // app is backgrounded without our watchdog running. Reconcile first so
        // we don't keep showing a stale "Connected" state and short-circuit reconnect.
        Future.microtask(() async {
          await midi.reconcileConnectedDevice(
            reason: 'resume',
            scanIfNeeded: true,
          );
          await connectionState.tryAutoReconnect(reason: 'resume');
        });
        break;

      case AppLifecycleState.inactive:
        // Often transient (permission dialogs, app switcher). Avoid scan churn.
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        midi.setBackgrounded(true);
        connectionState.setBackgrounded(true);
        // Fire-and-forget: we only need best-effort scan stop while backgrounding.
        unawaited(connectionState.stopScanning());
        break;
    }
  }
}
