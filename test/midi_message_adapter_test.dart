import 'package:flutter_midi_command/flutter_midi_command_messages.dart' as msg;
import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/midi/models/midi_message.dart';
import 'package:whatchord/features/midi/services/midi_ble_service.dart';

void main() {
  group('MidiBleService.mapMessage', () {
    test('maps note on', () {
      final result = MidiBleService.mapMessage(
        msg.NoteOnMessage(note: 60, velocity: 100),
      );
      expect(result?.type, MidiMessageType.noteOn);
      expect(result?.note, 60);
      expect(result?.velocity, 100);
    });

    test('maps note off', () {
      final result = MidiBleService.mapMessage(
        msg.NoteOffMessage(note: 64, velocity: 0),
      );
      expect(result?.type, MidiMessageType.noteOff);
      expect(result?.note, 64);
    });

    test('maps control change to number and value', () {
      final result = MidiBleService.mapMessage(
        msg.CCMessage(controller: 64, value: 127),
      );
      expect(result?.type, MidiMessageType.controlChange);
      expect(result?.ccNumber, 64);
      expect(result?.ccValue, 127);
    });

    test('maps program change', () {
      final result = MidiBleService.mapMessage(msg.PCMessage(program: 5));
      expect(result?.type, MidiMessageType.programChange);
      expect(result?.program, 5);
    });

    test('passes through the normalized pitch bend value', () {
      expect(
        MidiBleService.mapMessage(msg.PitchBendMessage(bend: -1.0))?.bend,
        -1.0,
      );
      expect(
        MidiBleService.mapMessage(msg.PitchBendMessage(bend: 0.5))?.bend,
        0.5,
      );
    });

    test('drops message kinds the app does not consume', () {
      expect(MidiBleService.mapMessage(msg.ATMessage(pressure: 10)), isNull);
      expect(MidiBleService.mapMessage(msg.ClockMessage()), isNull);
    });
  });
}
