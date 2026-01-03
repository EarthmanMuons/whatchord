import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/flutter_midi_service.dart';
import '../services/midi_service.dart';

/// Provider for the MIDI service instance.
final midiServiceProvider = Provider<MidiService>((ref) {
  final service = FlutterMidiService();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider that manages MIDI service initialization.
final midiServiceInitProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(midiServiceProvider);
  try {
    return await service.initialize();
  } catch (e) {
    debugPrint('MIDI initialization failed: $e');
    return false;
  }
});
