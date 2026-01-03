import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/core/persistence/shared_preferences_provider.dart';

import '../models/midi_device.dart';
import '../persistence/midi_preferences_keys.dart';
import '../persistence/midi_preferences.dart';

final midiPreferencesProvider =
    NotifierProvider<MidiPreferencesNotifier, MidiPreferences>(
      MidiPreferencesNotifier.new,
    );

/// Last saved device (may be null).
final lastSavedMidiDeviceProvider = Provider<MidiDevice?>((ref) {
  return ref.watch(midiPreferencesProvider.select((p) => p.lastDevice));
});

/// Last saved device id (may be null/empty).
final lastSavedMidiDeviceIdProvider = Provider<String?>((ref) {
  return ref.watch(midiPreferencesProvider.select((p) => p.lastDeviceId));
});

/// Whether we have a non-empty last saved device id.
final hasLastSavedMidiDeviceProvider = Provider<bool>((ref) {
  final id = ref.watch(lastSavedMidiDeviceIdProvider);
  return id != null && id.trim().isNotEmpty;
});

class MidiPreferencesNotifier extends Notifier<MidiPreferences> {
  @override
  MidiPreferences build() {
    final prefs = ref.watch(sharedPreferencesProvider);

    final lastDeviceId = prefs.getString(MidiPreferencesKeys.lastDeviceId);
    final lastDevice = _readLastDevice(
      prefs.getString(MidiPreferencesKeys.lastDeviceJson),
    );
    final lastConnectedAtMs = prefs.getInt(
      MidiPreferencesKeys.lastConnectedAtMs,
    );
    final autoReconnect =
        prefs.getBool(MidiPreferencesKeys.autoReconnect) ?? true;

    return MidiPreferences(
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

    await prefs.setString(MidiPreferencesKeys.lastDeviceId, toStore.id);
    await prefs.setString(
      MidiPreferencesKeys.lastDeviceJson,
      jsonEncode(toStore.toJson()),
    );
    await prefs.setInt(MidiPreferencesKeys.lastConnectedAtMs, nowMs);
  }

  Future<void> clearLastDevice() async {
    final prefs = ref.read(sharedPreferencesProvider);

    state = state.copyWith(clearLastDevice: true);

    await prefs.remove(MidiPreferencesKeys.lastDeviceId);
    await prefs.remove(MidiPreferencesKeys.lastDeviceJson);
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

    await prefs.remove(MidiPreferencesKeys.lastDeviceId);
    await prefs.remove(MidiPreferencesKeys.lastDeviceJson);
    await prefs.remove(MidiPreferencesKeys.lastConnectedAtMs);
    await prefs.remove(MidiPreferencesKeys.autoReconnect);
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
