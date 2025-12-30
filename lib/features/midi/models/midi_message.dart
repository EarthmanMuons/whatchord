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
  final int? controller;
  final int? value;
  final int? program;
  final int? pitchBend;

  const MidiMessage({
    required this.type,
    this.note,
    this.velocity,
    this.controller,
    this.value,
    this.program,
    this.pitchBend,
  });

  @override
  String toString() {
    return switch (type) {
      MidiMessageType.noteOn => 'NoteOn(note: $note, vel: $velocity)',
      MidiMessageType.noteOff => 'NoteOff(note: $note, vel: $velocity)',
      MidiMessageType.controlChange =>
        'CC(controller: $controller, value: $value)',
      MidiMessageType.programChange => 'ProgramChange(program: $program)',
      MidiMessageType.pitchBend => 'PitchBend(value: $pitchBend)',
      MidiMessageType.unknown => 'UnknownMessage',
    };
  }
}

/// Parser for raw MIDI bytes.
class MidiParser {
  /// Parse raw MIDI bytes into a structured message.
  static MidiMessage? parse(Uint8List bytes) {
    if (bytes.isEmpty) return null;

    final status = bytes[0] & 0xF0;

    switch (status) {
      case 0x90: // Note On
        if (bytes.length < 3) return null;
        final velocity = bytes[2];
        // Note: velocity 0 is typically interpreted as Note Off
        return MidiMessage(
          type: velocity > 0 ? MidiMessageType.noteOn : MidiMessageType.noteOff,
          note: bytes[1],
          velocity: velocity,
        );

      case 0x80: // Note Off
        if (bytes.length < 3) return null;
        return MidiMessage(
          type: MidiMessageType.noteOff,
          note: bytes[1],
          velocity: bytes[2],
        );

      case 0xB0: // Control Change
        if (bytes.length < 3) return null;
        return MidiMessage(
          type: MidiMessageType.controlChange,
          controller: bytes[1],
          value: bytes[2],
        );

      case 0xC0: // Program Change
        if (bytes.length < 2) return null;
        return MidiMessage(
          type: MidiMessageType.programChange,
          program: bytes[1],
        );

      case 0xE0: // Pitch Bend
        if (bytes.length < 3) return null;
        final lsb = bytes[1];
        final msb = bytes[2];
        final bend = (msb << 7) | lsb;
        return MidiMessage(type: MidiMessageType.pitchBend, pitchBend: bend);

      default:
        return const MidiMessage(type: MidiMessageType.unknown);
    }
  }
}
