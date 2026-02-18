import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/input/input.dart';

import 'audio_monitor_notifier.dart';

final appAudioMonitorLifecycleProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<InputNoteEvent>>(inputNoteEventsProvider, (
    previous,
    next,
  ) {
    final event = next.asData?.value;
    if (event == null) return;
    ref.read(audioMonitorNotifier.notifier).onInputNoteEvent(event);
  });

  final controller = _AudioMonitorLifecycleController(ref);
  controller.attach();
  ref.onDispose(controller.detach);
});

class _AudioMonitorLifecycleController with WidgetsBindingObserver {
  _AudioMonitorLifecycleController(this._ref);

  final Ref _ref;
  bool _attached = false;

  void attach() {
    if (_attached) return;
    _attached = true;
    WidgetsBinding.instance.addObserver(this);

    // Ensure the monitor notifier is created early.
    _ref.read(audioMonitorNotifier.notifier);
  }

  void detach() {
    if (!_attached) return;
    _attached = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final monitor = _ref.read(audioMonitorNotifier.notifier);

    switch (state) {
      case AppLifecycleState.resumed:
        monitor.setBackgrounded(false);
        break;
      case AppLifecycleState.inactive:
        // iOS system interruptions (alarms/calls) can leave the output unit in
        // a bad state unless we rebuild on resume.
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          monitor.setBackgrounded(true);
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        monitor.setBackgrounded(true);
        break;
    }
  }
}
