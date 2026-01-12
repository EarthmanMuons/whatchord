import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/midi/midi.dart' show midiEngagedProvider;

import 'midi_activity_tracker.dart';

// Bridges MIDI engagement state into the idle tracker.
// Engagement semantics are defined in midiEngagedProvider.
final midiIdleCoordinatorProvider = Provider<void>((ref) {
  ref.listen<bool>(
    midiEngagedProvider,
    (_, next) =>
        ref.read(midiIdleProvider.notifier).updateEngagement(engagedNow: next),
    fireImmediately: true,
  );
});
