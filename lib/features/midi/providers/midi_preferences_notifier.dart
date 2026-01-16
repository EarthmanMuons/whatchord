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

/// Saved device (may be null).
final savedMidiDeviceProvider = Provider<MidiDevice?>((ref) {
  return ref.watch(midiPreferencesProvider.select((p) => p.savedDevice));
});

/// Saved device id (may be null/empty).
final savedMidiDeviceIdProvider = Provider<String?>((ref) {
  return ref.watch(midiPreferencesProvider.select((p) => p.savedDeviceId));
});

/// Whether we have a non-empty saved device id.
final hasSavedMidiDeviceProvider = Provider<bool>((ref) {
  final id = ref.watch(savedMidiDeviceIdProvider);
  return id != null && id.trim().isNotEmpty;
});

class MidiPreferencesNotifier extends Notifier<MidiPreferences> {
  @override
  MidiPreferences build() {
    final prefs = ref.watch(sharedPreferencesProvider);

    final savedDeviceId = prefs.getString(MidiPreferencesKeys.savedDeviceId);
    final savedDevice = _readSavedDevice(
      prefs.getString(MidiPreferencesKeys.savedDeviceJson),
    );
    final savedConnectedAtMs = prefs.getInt(
      MidiPreferencesKeys.savedConnectedAtMs,
    );
    final autoReconnect =
        prefs.getBool(MidiPreferencesKeys.autoReconnect) ?? true;

    return MidiPreferences(
      savedDeviceId: savedDeviceId,
      savedDevice: savedDevice,
      savedConnectedAtMs: savedConnectedAtMs,
      autoReconnect: autoReconnect,
    );
  }

  Future<void> setSavedDevice(MidiDevice device) async {
    final prefs = ref.read(sharedPreferencesProvider);

    // Persist a stable representation (don’t persist a stale isConnected flag).
    final toStore = device.copyWith(isConnected: false);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Update in-memory FIRST (reactive UI), then write-through.
    state = state.copyWith(
      savedDeviceId: toStore.id,
      savedDevice: toStore,
      savedConnectedAtMs: nowMs,
    );

    await prefs.setString(MidiPreferencesKeys.savedDeviceId, toStore.id);
    await prefs.setString(
      MidiPreferencesKeys.savedDeviceJson,
      jsonEncode(toStore.toJson()),
    );
    await prefs.setInt(MidiPreferencesKeys.savedConnectedAtMs, nowMs);
  }

  Future<void> clearSavedDevice() async {
    final prefs = ref.read(sharedPreferencesProvider);

    state = state.copyWith(clearSavedDevice: true);

    await prefs.remove(MidiPreferencesKeys.savedDeviceId);
    await prefs.remove(MidiPreferencesKeys.savedDeviceJson);
    await prefs.remove(MidiPreferencesKeys.savedConnectedAtMs);
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

    await prefs.remove(MidiPreferencesKeys.savedDeviceId);
    await prefs.remove(MidiPreferencesKeys.savedDeviceJson);
    await prefs.remove(MidiPreferencesKeys.savedConnectedAtMs);
    await prefs.remove(MidiPreferencesKeys.autoReconnect);
  }

  MidiDevice? _readSavedDevice(String? json) {
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return MidiDevice.fromJson(map);
    } catch (e) {
      debugPrint('Error decoding saved MIDI device: $e');
      return null;
    }
  }
}
