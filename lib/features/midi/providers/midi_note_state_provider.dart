import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/piano/models/active_note.dart';

import '../models/midi_constants.dart';
import '../models/midi_message.dart';
import '../models/midi_note_state.dart';
import 'midi_connection_manager.dart';
import 'midi_message_providers.dart';

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

    // Panic clear on disconnect: clears any stuck UI state if transport drops.
    ref.listen<MidiConnectionPhase>(
      midiConnectionManagerProvider.select((s) => s.phase),
      (prev, next) {
        if (prev == MidiConnectionPhase.connected &&
            next != MidiConnectionPhase.connected) {
          state = initialState;
        }
      },
    );

    // Listen to MIDI messages and update state
    ref.listen(midiMessageProvider, (previous, next) {
      next.when(
        data: _handleMidiMessage,
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
        final note = message.note;
        final velocity = message.velocity ?? 0;

        if (note == null) break;

        // MIDI spec: NoteOn with velocity 0 == NoteOff
        if (velocity == 0) {
          noteOff(note);
        } else {
          noteOn(note);
        }
        break;

      case MidiMessageType.noteOff:
        if (message.note != null) {
          noteOff(message.note!);
        }
        break;

      case MidiMessageType.controlChange:
        if (message.controller == MidiConstants.sustainPedalController &&
            message.value != null) {
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
    final nextPressed = {...state.pressed}..remove(midiNote);

    if (state.isPedalDown) {
      final nextSustained = {...state.sustained, midiNote};
      state = state.copyWith(pressed: nextPressed, sustained: nextSustained);
    } else {
      final nextSustained = {...state.sustained}..remove(midiNote);
      state = state.copyWith(pressed: nextPressed, sustained: nextSustained);
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

  // Convenience for MIDI sustain pedal values.
  void handlePedalValue(int value) =>
      setPedalDown(value >= MidiConstants.sustainPedalThreshold);
}

// Raw MIDI note numbers for keyboard highlighting.
final soundingMidiNotesProvider = Provider<Set<int>>((ref) {
  final state = ref.watch(midiNoteStateProvider);
  return state.soundingNotes;
});

// Sustain pedal state for display.
final isPedalDownProvider = Provider<bool>((ref) {
  return ref.watch(midiNoteStateProvider.select((s) => s.isPedalDown));
});

// Rich note objects for display, sorted by pitch.
final activeNotesProvider = Provider<List<ActiveNote>>((ref) {
  final state = ref.watch(midiNoteStateProvider);

  final notes = <ActiveNote>[];
  final activeSorted = state.soundingNotes.toList()..sort();

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
