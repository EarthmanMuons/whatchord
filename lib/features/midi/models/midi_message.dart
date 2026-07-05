import 'package:flutter/foundation.dart';

/// Type of MIDI message received.
enum MidiMessageType {
  noteOn,
  noteOff,
  controlChange,
  programChange,
  pitchBend,
  unknown,
}

/// Parsed representation of a MIDI message.
@immutable
class MidiMessage {
  final MidiMessageType type;
  final int? note;
  final int? velocity;
  final int? ccNumber;
  final int? ccValue;
  final int? program;

  /// Normalized pitch bend in the range -1.0..1.0, as delivered by the plugin.
  final double? bend;

  const MidiMessage({
    required this.type,
    this.note,
    this.velocity,
    this.ccNumber,
    this.ccValue,
    this.program,
    this.bend,
  });

  @override
  String toString() {
    return switch (type) {
      MidiMessageType.noteOn => 'NoteOn(note: $note, vel: $velocity)',
      MidiMessageType.noteOff => 'NoteOff(note: $note, vel: $velocity)',
      MidiMessageType.controlChange => 'CC(number: $ccNumber, value: $ccValue)',
      MidiMessageType.programChange => 'ProgramChange(program: $program)',
      MidiMessageType.pitchBend => 'PitchBend(bend: $bend)',
      MidiMessageType.unknown => 'UnknownMessage',
    };
  }
}
