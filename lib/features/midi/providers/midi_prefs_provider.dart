import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/core/persistence/shared_preferences_provider.dart';

import '../models/midi_device.dart';
import '../persistence/midi_prefs_keys.dart';
import '../persistence/midi_prefs_state.dart';

final midiPrefsProvider = NotifierProvider<MidiPrefsNotifier, MidiPrefsState>(
  MidiPrefsNotifier.new,
);

class MidiPrefsNotifier extends Notifier<MidiPrefsState> {
  @override
  MidiPrefsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);

    final lastDeviceId = prefs.getString(MidiPrefsKeys.lastDeviceId);
    final lastDevice = _readLastDevice(
      prefs.getString(MidiPrefsKeys.lastDeviceJson),
    );
    final lastConnectedAtMs = prefs.getInt(MidiPrefsKeys.lastConnectedAtMs);
    final autoReconnect = prefs.getBool(MidiPrefsKeys.autoReconnect) ?? true;

    return MidiPrefsState(
      lastDeviceId: lastDeviceId,
      lastDevice: lastDevice,
      lastConnectedAtMs: lastConnectedAtMs,
      autoReconnect: autoReconnect,
    );
  }

  Future<void> setLastDevice(MidiDevice device) async {
    final prefs = ref.read(sharedPreferencesProvider);

    // Persist a stable representation (don’t persist a stale isConnected flag).
    final toStore = device.copyWith(isConnected: false);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Update in-memory FIRST (reactive UI), then write-through.
    state = state.copyWith(
      lastDeviceId: toStore.id,
      lastDevice: toStore,
      lastConnectedAtMs: nowMs,
    );

    await prefs.setString(MidiPrefsKeys.lastDeviceId, toStore.id);
    await prefs.setString(
      MidiPrefsKeys.lastDeviceJson,
      jsonEncode(toStore.toJson()),
    );
    await prefs.setInt(MidiPrefsKeys.lastConnectedAtMs, nowMs);
  }

  Future<void> clearLastDevice() async {
    final prefs = ref.read(sharedPreferencesProvider);

    state = state.copyWith(clearLastDevice: true);

    await prefs.remove(MidiPrefsKeys.lastDeviceId);
    await prefs.remove(MidiPrefsKeys.lastDeviceJson);
    await prefs.remove(MidiPrefsKeys.lastConnectedAtMs);
  }

  Future<void> setAutoReconnect(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);

    state = state.copyWith(autoReconnect: enabled);
    await prefs.setBool(MidiPrefsKeys.autoReconnect, enabled);
  }

  Future<void> clearAllMidiData() async {
    final prefs = ref.read(sharedPreferencesProvider);

    // Preserve defaults for autoReconnect (true) after reset.
    state = const MidiPrefsState.defaults();

    await prefs.remove(MidiPrefsKeys.lastDeviceId);
    await prefs.remove(MidiPrefsKeys.lastDeviceJson);
    await prefs.remove(MidiPrefsKeys.lastConnectedAtMs);
    await prefs.remove(MidiPrefsKeys.autoReconnect);
  }

  MidiDevice? _readLastDevice(String? json) {
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return MidiDevice.fromJson(map);
    } catch (e) {
      debugPrint('Error decoding last MIDI device: $e');
      return null;
    }
  }
}
