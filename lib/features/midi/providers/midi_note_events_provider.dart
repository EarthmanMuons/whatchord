import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/input/models/input_note_event.dart';

import '../models/midi_message.dart';
import 'midi_message_providers.dart';

const bool _audioDebug = bool.fromEnvironment('AUDIO_DEBUG');

final midiNoteEventsProvider = Provider.autoDispose<Stream<InputNoteEvent>>((
  ref,
) {
  final controller = StreamController<InputNoteEvent>.broadcast(sync: true);

  ref.listen(midiMessageProvider, (previous, next) {
    final message = next.asData?.value;
    if (message == null) return;

    if (message.type != MidiMessageType.noteOn &&
        message.type != MidiMessageType.noteOff) {
      return;
    }

    if (_audioDebug) {
      debugPrint(
        '[AUDIO_IN] ${message.type.name} note=${message.note} '
        'vel=${message.velocity}',
      );
    }

    controller.add(
      InputNoteEvent(
        type: message.type == MidiMessageType.noteOn
            ? InputNoteEventType.noteOn
            : InputNoteEventType.noteOff,
        noteNumber: (message.note ?? 0).clamp(0, 127),
        velocity: (message.velocity ?? 0).clamp(0, 127),
      ),
    );
  });

  ref.onDispose(() async {
    await controller.close();
  });

  return controller.stream;
});
