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
  /// Parse a single MIDI message (expects the bytes to start at a status byte).
  static MidiMessage? parse(Uint8List bytes) {
    if (bytes.isEmpty) return null;

    final statusByte = bytes[0];
    // Mask off the low nibble (channel). We currently treat input as channel-agnostic.
    final status = statusByte & 0xF0;

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

  /// Parse a raw packet that may contain multiple channel voice messages.
  static Iterable<MidiMessage> parseMany(Uint8List bytes) sync* {
    var i = 0;

    while (i < bytes.length) {
      final b = bytes[i];

      // 1) Skip stray data bytes (we're not implementing running status here).
      if (b < 0x80) {
        i++;
        continue;
      }

      // 2) MIDI Realtime messages (0xF8..0xFF) are 1 byte and can occur anywhere.
      if (b >= 0xF8) {
        i++;
        continue;
      }

      // 3) SysEx: skip from 0xF0 to 0xF7 (end) within this packet.
      if (b == 0xF0) {
        i++; // consume 0xF0
        while (i < bytes.length && bytes[i] != 0xF7) {
          i++;
        }
        if (i < bytes.length && bytes[i] == 0xF7) {
          i++; // consume 0xF7
        }
        continue;
      }

      // 4) Other system common messages (0xF1..0xF7) have defined lengths.
      if (b >= 0xF1 && b <= 0xF7) {
        int sysLen;
        switch (b) {
          case 0xF1: // MTC Quarter Frame
            sysLen = 2;
            break;
          case 0xF2: // Song Position Pointer
            sysLen = 3;
            break;
          case 0xF3: // Song Select
            sysLen = 2;
            break;
          case 0xF6: // Tune Request
            sysLen = 1;
            break;
          case 0xF7: // End of SysEx (can appear alone)
            sysLen = 1;
            break;
          default:
            sysLen = 1;
            break;
        }

        // Consume and ignore (don't try to parse into MidiMessage for now).
        i = (i + sysLen <= bytes.length) ? i + sysLen : bytes.length;
        continue;
      }

      // 5) Channel voice messages.
      final type = b & 0xF0;

      int msgLen;
      switch (type) {
        case 0xC0: // Program Change
        case 0xD0: // Channel Pressure
          msgLen = 2;
          break;

        case 0x80: // Note Off
        case 0x90: // Note On
        case 0xA0: // Poly Aftertouch
        case 0xB0: // CC
        case 0xE0: // Pitch Bend
          msgLen = 3;
          break;

        default:
          // Unknown status; consume 1 byte to avoid infinite loop.
          i++;
          continue;
      }

      if (i + msgLen > bytes.length) {
        // Truncated message at end of packet; stop parsing.
        break;
      }

      final slice = Uint8List.sublistView(bytes, i, i + msgLen);
      final parsed = parse(slice);
      if (parsed != null) yield parsed;

      i += msgLen;
    }
  }
}
