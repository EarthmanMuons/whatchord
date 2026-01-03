import 'package:flutter/foundation.dart';

import '../models/midi_device.dart';

@immutable
class MidiPreferencesState {
  final String? lastDeviceId;
  final MidiDevice? lastDevice;
  final int? lastConnectedAtMs;
  final bool autoReconnect;

  const MidiPreferencesState({
    required this.lastDeviceId,
    required this.lastDevice,
    required this.lastConnectedAtMs,
    required this.autoReconnect,
  });

  const MidiPreferencesState.defaults()
    : lastDeviceId = null,
      lastDevice = null,
      lastConnectedAtMs = null,
      autoReconnect = true;

  bool get hasLastDeviceId =>
      lastDeviceId != null && lastDeviceId!.trim().isNotEmpty;

  MidiPreferencesState copyWith({
    String? lastDeviceId,
    MidiDevice? lastDevice,
    int? lastConnectedAtMs,
    bool? autoReconnect,
    bool clearLastDevice = false,
  }) {
    if (clearLastDevice) {
      return MidiPreferencesState(
        lastDeviceId: null,
        lastDevice: null,
        lastConnectedAtMs: null,
        autoReconnect: autoReconnect ?? this.autoReconnect,
      );
    }

    return MidiPreferencesState(
      lastDeviceId: lastDeviceId ?? this.lastDeviceId,
      lastDevice: lastDevice ?? this.lastDevice,
      lastConnectedAtMs: lastConnectedAtMs ?? this.lastConnectedAtMs,
      autoReconnect: autoReconnect ?? this.autoReconnect,
    );
  }
}
