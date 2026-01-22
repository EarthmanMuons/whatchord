import 'package:flutter_midi_command/flutter_midi_command.dart' as fmc;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/midi_ble_service.dart';

final midiBleServiceProvider = Provider<MidiBleService>((ref) {
  final cmd = ref.watch(midiCommandProvider);
  return MidiBleService(cmd);
});

final midiCommandProvider = Provider<fmc.MidiCommand>((ref) {
  return fmc.MidiCommand();
});
