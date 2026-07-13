import 'package:flutter/foundation.dart';

import 'package:flutter_midi_command/flutter_midi_command.dart' as fmc;
import 'package:flutter_midi_command_ble/flutter_midi_command_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/midi_ble_service.dart';

final midiBleServiceProvider = Provider<MidiBleService>((ref) {
  final cmd = ref.watch(midiCommandProvider);
  return MidiBleService(cmd);
});

final midiCommandProvider = Provider<fmc.MidiCommand>((ref) {
  // As of flutter_midi_command 1.0, BLE is an injectable transport rather than
  // built in; without one, all Bluetooth operations throw StateError.
  final cmd = fmc.MidiCommand(bleTransport: UniversalBleMidiTransport());
  if (!kReleaseMode) {
    // Surfaces the plugin's device merge, route, and BLE-to-CoreMIDI handoff
    // diagnostics for connection debugging (debug and profile builds).
    cmd.logHandler = debugPrint;
    // Timestamped setup events (deviceConnected, deviceDisconnected, ...) to
    // pin down when a mid-session drop happens relative to launch.
    final setupSub = cmd.onMidiSetupChanged?.listen((change) {
      final ts = DateTime.now().toIso8601String().substring(11, 23);
      debugPrint('[MIDI] $ts setup change: ${change.name}');
    });
    ref.onDispose(() => setupSub?.cancel());
  }
  return cmd;
});
