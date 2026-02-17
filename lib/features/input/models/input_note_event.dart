import 'package:meta/meta.dart';

enum InputNoteEventType { noteOn, noteOff }

@immutable
class InputNoteEvent {
  const InputNoteEvent({
    required this.type,
    required this.noteNumber,
    required this.velocity,
  });

  final InputNoteEventType type;
  final int noteNumber;
  final int velocity;
}
