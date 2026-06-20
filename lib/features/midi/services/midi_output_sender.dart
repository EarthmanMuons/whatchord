import 'dart:typed_data';

import 'package:flutter_midi_command/flutter_midi_command.dart' as fmc;

import '../models/midi_constants.dart';

/// Sends MIDI note and control messages to connected output devices.
///
/// Used to play app-generated preview notes through an external keyboard's own
/// sound engine. Messages are broadcast to every connected device; the app
/// maintains a single active connection, so this targets that device.
class MidiOutputSender {
  MidiOutputSender(this._midi, {this.channel = 0});

  final fmc.MidiCommand _midi;

  /// MIDI channel (0-15) note and control messages are sent on.
  final int channel;

  void noteOn(int note, {int velocity = midiOutputDefaultVelocity}) {
    _send(0x90 | channel, note, velocity);
  }

  void noteOff(int note) {
    _send(0x80 | channel, note, 0);
  }

  /// Silences any sounding notes on the output channel.
  ///
  /// Sends both All Sound Off (CC 120) and All Notes Off (CC 123) so no preview
  /// note can be left ringing on the device. Notes are only ever sent on
  /// [channel], so clearing that channel is sufficient.
  void panic() {
    _sendControlChange(MidiConstants.ccAllSoundOff, 0);
    _sendControlChange(MidiConstants.ccAllNotesOff, 0);
  }

  void _send(int status, int data1, int data2) {
    _midi.sendData(Uint8List.fromList([status, data1 & 0x7f, data2 & 0x7f]));
  }

  void _sendControlChange(int controller, int value) {
    _midi.sendData(
      Uint8List.fromList([0xb0 | channel, controller & 0x7f, value & 0x7f]),
    );
  }
}

const int midiOutputDefaultVelocity = 100;
