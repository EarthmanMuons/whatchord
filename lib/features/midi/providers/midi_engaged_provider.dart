import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'midi_note_state_notifier.dart';

/// Whether the user is considered "engaged" for idle / prompt purposes.
///
/// IMPORTANT:
/// Engagement is defined strictly by whether any notes are currently sounding.
/// Sustain pedal state (manual or MIDI) must NOT affect engagement.
///
/// Rationale:
/// - The pedal is a modifier, not an action.
/// - Manual pedal toggles should not dismiss idle UI.
/// - Hardware pedal alone should not count as activity.
///
/// If this definition changes, audit:
/// - midiIdleCoordinatorProvider
/// - idle / prompt UI behavior
final midiEngagedProvider = Provider<bool>((ref) {
  return ref.watch(
    midiNoteStateProvider.select((s) => s.soundingNotes.isNotEmpty),
  );
});
