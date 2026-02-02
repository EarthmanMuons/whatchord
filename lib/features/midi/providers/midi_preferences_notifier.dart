import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/providers/shared_preferences_provider.dart';

import '../models/midi_device.dart';
import '../models/midi_preferences.dart';
import '../persistence/midi_preferences_keys.dart';

final midiPreferencesProvider =
    NotifierProvider<MidiPreferencesNotifier, MidiPreferences>(
      MidiPreferencesNotifier.new,
    );

/// Last connected device (may be null).
final lastConnectedMidiDeviceProvider = Provider<MidiDevice?>((ref) {
  return ref.watch(
    midiPreferencesProvider.select((p) => p.lastConnectedDevice),
  );
});

/// Last connected device id (may be null/empty).
final lastConnectedMidiDeviceIdProvider = Provider<String?>((ref) {
  return ref.watch(
    midiPreferencesProvider.select((p) => p.lastConnectedDeviceId),
  );
});

/// Whether we have a non-empty last-connected device id.
final hasLastConnectedMidiDeviceProvider = Provider<bool>((ref) {
  final id = ref.watch(lastConnectedMidiDeviceIdProvider);
  return id != null && id.trim().isNotEmpty;
});

class MidiPreferencesNotifier extends Notifier<MidiPreferences> {
  @override
  MidiPreferences build() {
    final prefs = ref.watch(sharedPreferencesProvider);

    final lastConnectedDeviceId = prefs.getString(
      MidiPreferencesKeys.lastConnectedDeviceId,
    );
    final lastConnectedDevice = _readLastConnectedDevice(
      prefs.getString(MidiPreferencesKeys.lastConnectedDeviceJson),
    );
    final lastConnectedAtMs = prefs.getInt(
      MidiPreferencesKeys.lastConnectedAtMs,
    );
    final autoReconnect =
        prefs.getBool(MidiPreferencesKeys.autoReconnect) ?? true;

    return MidiPreferences(
      lastConnectedDeviceId: lastConnectedDeviceId,
      lastConnectedDevice: lastConnectedDevice,
      lastConnectedAtMs: lastConnectedAtMs,
      autoReconnect: autoReconnect,
    );
  }

  Future<void> setLastConnectedDevice(MidiDevice device) async {
    final prefs = ref.read(sharedPreferencesProvider);

    // Persist a stable representation (don’t persist a stale isConnected flag).
    final toStore = device.copyWith(isConnected: false);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Update in-memory FIRST (reactive UI), then write-through.
    state = state.copyWith(
      lastConnectedDeviceId: toStore.id,
      lastConnectedDevice: toStore,
      lastConnectedAtMs: nowMs,
    );

    await prefs.setString(
      MidiPreferencesKeys.lastConnectedDeviceId,
      toStore.id,
    );
    await prefs.setString(
      MidiPreferencesKeys.lastConnectedDeviceJson,
      jsonEncode(toStore.toJson()),
    );
    await prefs.setInt(MidiPreferencesKeys.lastConnectedAtMs, nowMs);
  }

  Future<void> clearLastConnectedDevice() async {
    final prefs = ref.read(sharedPreferencesProvider);

    state = state.copyWith(clearLastConnectedDevice: true);

    await prefs.remove(MidiPreferencesKeys.lastConnectedDeviceId);
    await prefs.remove(MidiPreferencesKeys.lastConnectedDeviceJson);
    await prefs.remove(MidiPreferencesKeys.lastConnectedAtMs);
  }

  Future<void> setAutoReconnect(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);

    state = state.copyWith(autoReconnect: enabled);
    await prefs.setBool(MidiPreferencesKeys.autoReconnect, enabled);
  }

  Future<void> clearAllMidiData() async {
    final prefs = ref.read(sharedPreferencesProvider);

    // Preserve defaults for autoReconnect (true) after reset.
    state = const MidiPreferences.defaults();

    await prefs.remove(MidiPreferencesKeys.lastConnectedDeviceId);
    await prefs.remove(MidiPreferencesKeys.lastConnectedDeviceJson);
    await prefs.remove(MidiPreferencesKeys.lastConnectedAtMs);
    await prefs.remove(MidiPreferencesKeys.autoReconnect);
  }

  MidiDevice? _readLastConnectedDevice(String? json) {
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return MidiDevice.fromJson(map);
    } catch (e) {
      debugPrint('Error decoding last connected MIDI device: $e');
      return null;
    }
  }
}
