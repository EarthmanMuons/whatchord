import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/demo/demo.dart' show demoModeProvider;
import 'package:whatchord/features/midi/midi_input_source.dart';

import '../models/input_note_event.dart';

const bool _audioDebug = bool.fromEnvironment('AUDIO_DEBUG');

final inputNoteEventsProvider = Provider<InputNoteEvent?>((ref) {
  final demoEnabled = ref.watch(demoModeProvider);
  if (demoEnabled) return null;

  final message = ref.watch(midiMessageProvider).asData?.value;
  if (message == null) return null;

  if (message.type != MidiMessageType.noteOn &&
      message.type != MidiMessageType.noteOff) {
    return null;
  }

  if (_audioDebug) {
    debugPrint(
      '[AUDIO_IN] ${message.type.name} note=${message.note} '
      'vel=${message.velocity}',
    );
  }

  return InputNoteEvent(
    type: message.type == MidiMessageType.noteOn
        ? InputNoteEventType.noteOn
        : InputNoteEventType.noteOff,
    noteNumber: (message.note ?? 0).clamp(0, 127),
    velocity: (message.velocity ?? 0).clamp(0, 127),
  );
});
