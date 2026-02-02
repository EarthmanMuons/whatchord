import 'package:flutter/foundation.dart';

import '../models/midi_device.dart';

@immutable
class MidiPreferences {
  final String? lastConnectedDeviceId;
  final MidiDevice? lastConnectedDevice;
  final int? lastConnectedAtMs;
  final bool autoReconnect;

  const MidiPreferences({
    required this.lastConnectedDeviceId,
    required this.lastConnectedDevice,
    required this.lastConnectedAtMs,
    required this.autoReconnect,
  });

  const MidiPreferences.defaults()
    : lastConnectedDeviceId = null,
      lastConnectedDevice = null,
      lastConnectedAtMs = null,
      autoReconnect = true;

  MidiPreferences copyWith({
    String? lastConnectedDeviceId,
    MidiDevice? lastConnectedDevice,
    int? lastConnectedAtMs,
    bool? autoReconnect,
    bool clearLastConnectedDevice = false,
  }) {
    if (clearLastConnectedDevice) {
      return MidiPreferences(
        lastConnectedDeviceId: null,
        lastConnectedDevice: null,
        lastConnectedAtMs: null,
        autoReconnect: autoReconnect ?? this.autoReconnect,
      );
    }

    return MidiPreferences(
      lastConnectedDeviceId:
          lastConnectedDeviceId ?? this.lastConnectedDeviceId,
      lastConnectedDevice: lastConnectedDevice ?? this.lastConnectedDevice,
      lastConnectedAtMs: lastConnectedAtMs ?? this.lastConnectedAtMs,
      autoReconnect: autoReconnect ?? this.autoReconnect,
    );
  }
}
