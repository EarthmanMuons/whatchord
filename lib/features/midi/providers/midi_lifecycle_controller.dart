import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'midi_link_manager.dart';
import 'midi_providers.dart';

/// Installs a WidgetsBindingObserver that coordinates MIDI behavior across
/// background/foreground transitions.
final midiLifecycleControllerProvider = Provider<void>((ref) {
  final controller = _MidiLifecycleController(ref);
  controller._attach();
  ref.onDispose(controller._detach);
});

class _MidiLifecycleController with WidgetsBindingObserver {
  final Ref _ref;

  _MidiLifecycleController(this._ref);

  void _attach() {
    WidgetsBinding.instance.addObserver(this);

    // Ensure MIDI initialization happens early.
    _ref.read(midiServiceInitProvider);

    // Attempt reconnect at startup (foreground).
    _ref
        .read(midiLinkManagerProvider.notifier)
        .tryAutoReconnect(reason: 'startup');
  }

  void _detach() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final link = _ref.read(midiLinkManagerProvider.notifier);
    final actions = _ref.read(midiConnectionActionsProvider);

    switch (state) {
      case AppLifecycleState.resumed:
        link.setBackgrounded(false);
        link.tryAutoReconnect(reason: 'resume');
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        link.setBackgrounded(true);

        // Stop scanning while backgrounded; the device picker can restart it.
        actions.stopScanning();
        break;
    }
  }
}
