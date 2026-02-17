import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/demo/demo.dart';
import 'package:whatchord/features/input/input.dart';

import 'audio_monitor_notifier.dart';

final appAudioMonitorLifecycleProvider = Provider<void>((ref) {
  var lastDemoNotes = ref.read(demoModeProvider)
      ? Set<int>.unmodifiable(ref.read(soundingNoteNumbersProvider))
      : const <int>{};

  ref.listen<AsyncValue<InputNoteEvent>>(inputNoteEventsProvider, (
    previous,
    next,
  ) {
    final event = next.asData?.value;
    if (event == null) return;
    ref.read(audioMonitorNotifier.notifier).onInputNoteEvent(event);
  });

  ref.listen<bool>(demoModeProvider, (previous, next) {
    if (previous == true && !next) {
      final monitor = ref.read(audioMonitorNotifier.notifier);
      final notes = lastDemoNotes.toList()..sort();
      for (final note in notes) {
        monitor.onInputNoteEvent(
          InputNoteEvent(
            type: InputNoteEventType.noteOff,
            noteNumber: note,
            velocity: 0,
          ),
        );
      }
      lastDemoNotes = const <int>{};
    }
  });

  ref.listen<Set<int>>(soundingNoteNumbersProvider, (previous, next) {
    if (!ref.read(demoModeProvider)) return;

    final monitor = ref.read(audioMonitorNotifier.notifier);
    final turnedOff = lastDemoNotes.difference(next).toList()..sort();
    final turnedOn = next.difference(lastDemoNotes).toList()..sort();

    for (final note in turnedOff) {
      monitor.onInputNoteEvent(
        InputNoteEvent(
          type: InputNoteEventType.noteOff,
          noteNumber: note,
          velocity: 0,
        ),
      );
    }
    for (final note in turnedOn) {
      monitor.onInputNoteEvent(
        InputNoteEvent(
          type: InputNoteEventType.noteOn,
          noteNumber: note,
          velocity: 100,
        ),
      );
    }

    lastDemoNotes = Set<int>.unmodifiable(next);
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
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        monitor.setBackgrounded(true);
        break;
    }
  }
}
