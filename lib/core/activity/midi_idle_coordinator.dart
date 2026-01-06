import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/midi/midi.dart'
    show activeNotesProvider, isPedalDownProvider;

import 'midi_activity_tracker.dart';

final midiIdleCoordinatorProvider = Provider<void>((ref) {
  void recompute() {
    final notes = ref.read(activeNotesProvider);
    final pedal = ref.read(isPedalDownProvider);

    // Engagement rule: held notes OR pedal down count as "active".
    final engagedNow = notes.isNotEmpty || pedal;

    ref
        .read(midiIdleProvider.notifier)
        .updateEngagement(engagedNow: engagedNow);
  }

  // Initialize once.
  recompute();

  // Recompute on state changes.
  ref.listen(activeNotesProvider, (_, _) => recompute());
  ref.listen(isPedalDownProvider, (_, _) => recompute());
});
