import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord_app/core/core.dart';

void main() {
  group('PreviewAnimationController', () {
    late PreviewAnimationController controller;
    late List<PreviewAnimationState> emitted;

    setUp(() {
      emitted = [];
      controller = PreviewAnimationController(onChanged: emitted.add);
    });

    tearDown(() => controller.dispose());

    test('startChord rolls notes in order, then holds the block', () {
      fakeAsync((async) {
        controller.startChord([60, 64, 67]);

        // First note lights immediately (zero-delay schedule runs inline).
        expect(controller.state.activeNotes, {60});
        expect(controller.state.isRunning, isTrue);

        async.elapse(PreviewTimings.rolledStep);
        expect(controller.state.activeNotes, {60, 64});

        // First note's note-off lands at rolledNoteDuration (220ms).
        async.elapse(
          PreviewTimings.rolledNoteDuration - PreviewTimings.rolledStep,
        );
        expect(controller.state.activeNotes, {64});

        // Jump to just after the block chord starts:
        // blockStart = rolledStep * 3 + rolledBlockGap.
        final blockStart =
            PreviewTimings.rolledStep * 3 + PreviewTimings.rolledBlockGap;
        async.elapse(blockStart - PreviewTimings.rolledNoteDuration);
        expect(controller.state.activeNotes, {60, 64, 67});

        async.elapse(PreviewTimings.rolledBlockDuration);
        expect(controller.state, PreviewAnimationState.idle);
        expect(controller.state.isRunning, isFalse);
      });
    });

    test('startChord holds a single note without rolling', () {
      fakeAsync((async) {
        controller.startChord([60]);
        expect(controller.state.activeNotes, {60});

        async.elapse(PreviewTimings.hold - const Duration(milliseconds: 1));
        expect(controller.state.activeNotes, {60});

        async.elapse(const Duration(milliseconds: 1));
        expect(controller.state, PreviewAnimationState.idle);
      });
    });

    test('startChord clamps, dedupes, and sorts input', () {
      fakeAsync((async) {
        controller.startChord([200, 64, 64, -5]);

        // Clamped notes 127 and 0 survive; deduped 64 rolls once. Sorted
        // order means 0 lights first.
        expect(controller.state.activeNotes, {0});

        async.elapse(PreviewTimings.rolledStep * 2);
        expect(controller.state.activeNotes, contains(127));
      });
    });

    test('startRun steps one note at a time, preserving order and repeats', () {
      fakeAsync((async) {
        controller.startRun([60, 62, 60]);
        expect(controller.state.activeNotes, {60});

        async.elapse(PreviewTimings.sequenceStep);
        expect(controller.state.activeNotes, {62});

        async.elapse(PreviewTimings.sequenceStep);
        expect(controller.state.activeNotes, {60});

        async.elapse(PreviewTimings.sequenceStep);
        expect(controller.state, PreviewAnimationState.idle);
      });
    });

    test('cancel resets to idle and stops scheduled updates', () {
      fakeAsync((async) {
        controller.startChord([60, 64, 67]);
        controller.cancel();
        expect(controller.state, PreviewAnimationState.idle);

        final emissionsAtCancel = emitted.length;
        async.elapse(const Duration(seconds: 5));
        expect(emitted.length, emissionsAtCancel);
      });
    });

    test('restarting supersedes the previous choreography', () {
      fakeAsync((async) {
        controller.startChord([60, 64, 67]);
        controller.startRun([72, 74]);
        expect(controller.state.activeNotes, {72});

        // Old chord timers are stale; only the run advances.
        async.elapse(PreviewTimings.sequenceStep);
        expect(controller.state.activeNotes, {74});
      });
    });

    test('skips notifications when the state is unchanged', () {
      fakeAsync((async) {
        controller.cancel();
        expect(emitted, isEmpty);
      });
    });
  });
}
