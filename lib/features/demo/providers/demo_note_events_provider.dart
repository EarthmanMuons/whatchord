import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/input/models/input_note_event.dart';

import 'demo_mode_notifier.dart';
import 'demo_note_state_notifier.dart';

final demoNoteEventsProvider = Provider.autoDispose<Stream<InputNoteEvent>>((
  ref,
) {
  // Use async delivery to avoid re-entrant add() calls when demo mode and note
  // state updates happen in the same provider notification stack.
  final controller = StreamController<InputNoteEvent>.broadcast();
  var demoEnabled = ref.read(demoModeProvider);
  var lastDemoNotes = demoEnabled
      ? Set<int>.unmodifiable(ref.read(demoSoundingNoteNumbersProvider))
      : const <int>{};

  ref.listen<bool>(demoModeProvider, (previous, next) {
    if (previous == true && !next) {
      final notes = lastDemoNotes.toList()..sort();
      for (final note in notes) {
        controller.add(
          InputNoteEvent(
            type: InputNoteEventType.noteOff,
            noteNumber: note,
            velocity: 0,
          ),
        );
      }
      lastDemoNotes = const <int>{};
    }

    if (previous != true && next) {
      lastDemoNotes = Set<int>.unmodifiable(
        ref.read(demoSoundingNoteNumbersProvider),
      );
    }

    demoEnabled = next;
  });

  ref.listen<Set<int>>(demoSoundingNoteNumbersProvider, (previous, next) {
    if (!demoEnabled) return;

    final turnedOff = lastDemoNotes.difference(next).toList()..sort();
    final turnedOn = next.difference(lastDemoNotes).toList()..sort();

    for (final note in turnedOff) {
      controller.add(
        InputNoteEvent(
          type: InputNoteEventType.noteOff,
          noteNumber: note,
          velocity: 0,
        ),
      );
    }
    for (final note in turnedOn) {
      controller.add(
        InputNoteEvent(
          type: InputNoteEventType.noteOn,
          noteNumber: note,
          velocity: 100,
        ),
      );
    }

    lastDemoNotes = Set<int>.unmodifiable(next);
  });

  ref.onDispose(() async {
    await controller.close();
  });

  return controller.stream;
});
