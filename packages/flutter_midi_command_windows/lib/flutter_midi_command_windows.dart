import 'package:flutter_midi_command_platform_interface/flutter_midi_command_platform_interface.dart';

class FlutterMidiCommandWindows extends MidiCommandPlatform {
  static void registerWith() {
    MidiCommandPlatform.instance = FlutterMidiCommandWindows();
  }
}
