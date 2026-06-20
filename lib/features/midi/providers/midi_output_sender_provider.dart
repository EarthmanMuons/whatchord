import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/midi_output_sender.dart';
import 'midi_ble_service_provider.dart';

/// Sends MIDI messages to the connected output device.
final midiOutputSenderProvider = Provider<MidiOutputSender>((ref) {
  return MidiOutputSender(ref.watch(midiCommandProvider));
});
