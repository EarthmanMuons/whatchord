import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/midi_connection.dart';
import '../models/midi_constants.dart';
import '../models/midi_message.dart';
import '../models/midi_note_state.dart';
import 'midi_connection_notifier.dart';
import 'midi_message_providers.dart';

final midiNoteStateProvider =
    NotifierProvider<MidiNoteStateNotifier, MidiNoteState>(
      MidiNoteStateNotifier.new,
    );

class MidiNoteStateNotifier extends Notifier<MidiNoteState> {
  @override
  MidiNoteState build() {
    const initialState = MidiNoteState(
      pressed: {},
      sustained: {},
      isPedalDown: false,
      pedalSource: PedalInputSource.midi,
    );

    ref.listen<MidiConnectionPhase>(
      midiConnectionProvider.select((s) => s.phase),
      (prev, next) {
        if (prev == MidiConnectionPhase.connected &&
            next != MidiConnectionPhase.connected) {
          state = initialState;
        }
      },
    );

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
        break;
    }
  }

  void noteOn(int midiNote) {
    final nextPressed = {...state.pressed, midiNote};
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

  void togglePedalManual() => setPedalDownManual(!state.isPedalDown);

  void setPedalDownManual(bool down) =>
      _setPedalDown(down, PedalInputSource.manual);

  void setPedalDownFromMidi(bool down) =>
      _setPedalDown(down, PedalInputSource.midi);

  void _setPedalDown(bool down, PedalInputSource source) {
    final sameDown = down == state.isPedalDown;
    final sameSource = source == state.pedalSource;

    // If down state unchanged but the source changes (e.g., manual -> midi),
    // still update to reflect "MIDI is authoritative now."
    if (sameDown && sameSource) return;

    if (!down) {
      // Pedal released: clear all sustained notes.
      state = state.copyWith(
        isPedalDown: false,
        sustained: <int>{},
        pedalSource: source,
      );
    } else {
      state = state.copyWith(isPedalDown: true, pedalSource: source);
    }
  }

  void handlePedalValue(int value) =>
      setPedalDownFromMidi(value >= MidiConstants.sustainPedalThreshold);
}

// Raw MIDI note numbers for keyboard highlighting.
final midiSoundingNotesProvider = Provider<Set<int>>((ref) {
  return ref.watch(midiNoteStateProvider.select((s) => s.soundingNotes));
});

// Sustain pedal state.
final isPedalDownProvider = Provider<bool>((ref) {
  return ref.watch(midiNoteStateProvider.select((s) => s.isPedalDown));
});

// Sustain pedal source (manual vs MIDI).
final pedalSourceProvider = Provider<PedalInputSource>((ref) {
  return ref.watch(midiNoteStateProvider.select((s) => s.pedalSource));
});
