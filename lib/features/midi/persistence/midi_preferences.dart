import 'package:flutter/foundation.dart';

import '../models/midi_device.dart';

@immutable
class MidiPreferences {
  final String? lastDeviceId;
  final MidiDevice? lastDevice;
  final int? lastConnectedAtMs;
  final bool autoReconnect;

  const MidiPreferences({
    required this.lastDeviceId,
    required this.lastDevice,
    required this.lastConnectedAtMs,
    required this.autoReconnect,
  });

  const MidiPreferences.defaults()
    : lastDeviceId = null,
      lastDevice = null,
      lastConnectedAtMs = null,
      autoReconnect = true;

  bool get hasLastDeviceId =>
      lastDeviceId != null && lastDeviceId!.trim().isNotEmpty;

  MidiPreferences copyWith({
    String? lastDeviceId,
    MidiDevice? lastDevice,
    int? lastConnectedAtMs,
    bool? autoReconnect,
    bool clearLastDevice = false,
  }) {
    if (clearLastDevice) {
      return MidiPreferences(
        lastDeviceId: null,
        lastDevice: null,
        lastConnectedAtMs: null,
        autoReconnect: autoReconnect ?? this.autoReconnect,
      );
    }

    return MidiPreferences(
      lastDeviceId: lastDeviceId ?? this.lastDeviceId,
      lastDevice: lastDevice ?? this.lastDevice,
      lastConnectedAtMs: lastConnectedAtMs ?? this.lastConnectedAtMs,
      autoReconnect: autoReconnect ?? this.autoReconnect,
    );
  }
}
