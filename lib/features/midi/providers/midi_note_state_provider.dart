import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/active_note.dart';
import '../models/midi_message.dart';
import '../models/midi_note_state.dart';
import 'midi_providers.dart';

final midiNoteStateProvider =
    NotifierProvider<MidiNoteStateNotifier, MidiNoteState>(
      MidiNoteStateNotifier.new,
    );

class MidiNoteStateNotifier extends Notifier<MidiNoteState> {
  @override
  MidiNoteState build() {
    // Start with empty state
    final initialState = const MidiNoteState(
      pressed: {},
      sustained: {},
      isPedalDown: false,
    );

    // Listen to MIDI messages and update state
    ref.listen(midiMessageStreamProvider, (previous, next) {
      next.when(
        data: (message) {
          if (message != null) {
            _handleMidiMessage(message);
          }
        },
        loading: () {},
        error: (error, stack) {
          debugPrint('MIDI message error: $error');
        },
      );
    });

    return initialState;
  }

  void _handleMidiMessage(MidiMessage message) {
    switch (message.type) {
      case MidiMessageType.noteOn:
        if (message.note != null) {
          noteOn(message.note!);
        }
        break;

      case MidiMessageType.noteOff:
        if (message.note != null) {
          noteOff(message.note!);
        }
        break;

      case MidiMessageType.controlChange:
        // CC64 is the sustain pedal
        if (message.controller == 64 && message.value != null) {
          handlePedalValue(message.value!);
        }
        break;

      default:
        // Ignore other message types
        break;
    }
  }

  void noteOn(int midiNote) {
    final nextPressed = {...state.pressed, midiNote};

    // If a sustained note is re-pressed, remove it from sustained.
    final nextSustained = {...state.sustained}..remove(midiNote);

    state = state.copyWith(pressed: nextPressed, sustained: nextSustained);
  }

  void noteOff(int midiNote) {
    if (!state.pressed.contains(midiNote)) return;

    final nextPressed = {...state.pressed}..remove(midiNote);

    if (state.isPedalDown) {
      final nextSustained = {...state.sustained, midiNote};
      state = state.copyWith(pressed: nextPressed, sustained: nextSustained);
    } else {
      state = state.copyWith(pressed: nextPressed);
    }
  }

  void setPedalDown(bool down) {
    if (down == state.isPedalDown) return;

    if (!down) {
      // Pedal released: clear all sustained notes.
      state = state.copyWith(isPedalDown: false, sustained: <int>{});
    } else {
      state = state.copyWith(isPedalDown: true);
    }
  }

  // Convenience for MIDI CC64 values (sustain pedal).
  // Convention: >= 64 is down, < 64 is up.
  void handlePedalValue(int value) => setPedalDown(value >= 64);
}

// Raw MIDI note numbers for keyboard highlighting.
final activeMidiNotesProvider = Provider<Set<int>>((ref) {
  final state = ref.watch(midiNoteStateProvider);
  return state.activeNotes;
});

// Sustain pedal state for display.
final isPedalDownProvider = Provider<bool>((ref) {
  return ref.watch(midiNoteStateProvider.select((s) => s.isPedalDown));
});

// Rich note objects for display, sorted by pitch.
final activeNotesProvider = Provider<List<ActiveNote>>((ref) {
  final state = ref.watch(midiNoteStateProvider);

  final notes = <ActiveNote>[];
  final activeSorted = state.activeNotes.toList()..sort();

  for (final midi in activeSorted) {
    notes.add(
      ActiveNote(
        midiNote: midi,
        label: _midiToNoteName(midi),
        isSustained: state.sustained.contains(midi),
      ),
    );
  }

  return notes;
});

String _midiToNoteName(int midiNote) {
  const noteNames = [
    'C',
    'C♯',
    'D',
    'D♯',
    'E',
    'F',
    'F♯',
    'G',
    'G♯',
    'A',
    'A♯',
    'B',
  ];
  return noteNames[midiNote % 12];
}
