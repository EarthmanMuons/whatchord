import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/midi_connection.dart';
import 'midi_connection_notifier.dart';

final midiWakelockEnabledProvider = Provider<bool>((ref) {
  final phase = ref.watch(midiConnectionStateProvider.select((s) => s.phase));
  return switch (phase) {
    MidiConnectionPhase.connected ||
    MidiConnectionPhase.connecting ||
    MidiConnectionPhase.retrying => true,
    _ => false,
  };
});
