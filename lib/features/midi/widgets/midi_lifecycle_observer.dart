import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/midi_connection_notifier.dart';
import '../providers/midi_service_providers.dart';

/// Installs a WidgetsBindingObserver that coordinates MIDI behavior across
/// background/foreground transitions.
final midiLifecycleObserverProvider = Provider<void>((ref) {
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (_ref.mounted) {
        _ref
            .read(midiConnectionProvider.notifier)
            .tryAutoReconnect(reason: 'startup');
      }
    });
  }

  void _detach() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final connection = _ref.read(midiConnectionProvider.notifier);
    final service = _ref.read(midiServiceProvider);

    switch (state) {
      case AppLifecycleState.resumed:
        service.setBackgrounded(false);
        connection.setBackgrounded(false);
        connection.tryAutoReconnect(reason: 'resume');
        break;

      case AppLifecycleState.inactive:
        // Often transient (permission dialogs, app switcher). Avoid scan churn.
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        service.setBackgrounded(true);
        connection.setBackgrounded(true);
        connection.stopScanning();
        break;
    }
  }
}
