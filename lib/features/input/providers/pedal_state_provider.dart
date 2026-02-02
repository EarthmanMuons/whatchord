import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/demo/demo.dart';
import 'package:whatchord/features/midi/midi.dart' show midiNoteStateProvider;

import '../adapters/demo_input_adapter.dart';
import '../adapters/midi_input_adapter.dart';
import '../models/input_pedal_state.dart';

final inputPedalStateProvider = Provider<InputPedalState>((ref) {
  final demoEnabled = ref.watch(demoModeProvider);
  if (demoEnabled) {
    final isDown = ref.watch(demoPedalDownSource);
    return InputPedalState(isDown: isDown, source: InputPedalSource.demo);
  }

  final isDown = ref.watch(midiPedalDownSource);
  final touchOverride = ref.watch(touchPedalOverrideProvider);

  return InputPedalState(
    isDown: isDown,
    source: isDown && touchOverride
        ? InputPedalSource.touch
        : InputPedalSource.midi,
  );
});

final inputPedalControllerProvider = Provider<InputPedalController>((ref) {
  return InputPedalController(ref);
});

final touchPedalOverrideProvider =
    NotifierProvider<TouchPedalOverrideNotifier, bool>(
      TouchPedalOverrideNotifier.new,
    );

class TouchPedalOverrideNotifier extends Notifier<bool> {
  @override
  bool build() {
    ref.listen<bool>(midiPedalDownSource, (_, next) {
      if (!next) state = false;
    });
    return false;
  }

  void set(bool v) => state = v;
}

class InputPedalController {
  final Ref ref;

  InputPedalController(this.ref);

  void toggle() {
    final demoEnabled = ref.read(demoModeProvider);
    if (demoEnabled) {
      ref.read(demoPedalDownProvider.notifier).toggle();
      return;
    }

    final isDown = ref.read(midiPedalDownSource);
    final touchOverride = ref.read(touchPedalOverrideProvider);
    final touchOverrideNotifier = ref.read(touchPedalOverrideProvider.notifier);
    final midi = ref.read(midiNoteStateProvider.notifier);

    if (isDown && !touchOverride) {
      // MIDI is down; latch touch without flipping the pedal up.
      touchOverrideNotifier.set(true);
      midi.setPedalLatch(true);
      midi.setPedalDown(true);
      return;
    }

    if (isDown && touchOverride) {
      // Touch owns the down state; releasing should clear pedal.
      touchOverrideNotifier.set(false);
      midi.setPedalLatch(false);
      midi.setPedalDown(false);
      return;
    }

    // Pedal is up; touch toggles it down.
    touchOverrideNotifier.set(true);
    midi.setPedalLatch(true);
    midi.setPedalDown(true);
  }
}
