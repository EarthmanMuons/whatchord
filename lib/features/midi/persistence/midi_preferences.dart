import 'package:flutter/foundation.dart';

import '../models/midi_device.dart';

@immutable
class MidiPreferences {
  final String? savedDeviceId;
  final MidiDevice? savedDevice;
  final int? savedConnectedAtMs;
  final bool autoReconnect;

  const MidiPreferences({
    required this.savedDeviceId,
    required this.savedDevice,
    required this.savedConnectedAtMs,
    required this.autoReconnect,
  });

  const MidiPreferences.defaults()
    : savedDeviceId = null,
      savedDevice = null,
      savedConnectedAtMs = null,
      autoReconnect = true;

  bool get hasLastDeviceId =>
      savedDeviceId != null && savedDeviceId!.trim().isNotEmpty;

  MidiPreferences copyWith({
    String? savedDeviceId,
    MidiDevice? savedDevice,
    int? savedConnectedAtMs,
    bool? autoReconnect,
    bool clearSavedDevice = false,
  }) {
    if (clearSavedDevice) {
      return MidiPreferences(
        savedDeviceId: null,
        savedDevice: null,
        savedConnectedAtMs: null,
        autoReconnect: autoReconnect ?? this.autoReconnect,
      );
    }

    return MidiPreferences(
      savedDeviceId: savedDeviceId ?? this.savedDeviceId,
      savedDevice: savedDevice ?? this.savedDevice,
      savedConnectedAtMs: savedConnectedAtMs ?? this.savedConnectedAtMs,
      autoReconnect: autoReconnect ?? this.autoReconnect,
    );
  }
}
