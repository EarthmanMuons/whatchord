import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'midi_note_state_notifier.dart';

final midiEngagedProvider = Provider<bool>((ref) {
  final hasNotes = ref.watch(
    midiNoteStateProvider.select((s) => s.soundingNotes.isNotEmpty),
  );
  final pedal = ref.watch(isPedalDownProvider);
  return hasNotes || pedal;
});
