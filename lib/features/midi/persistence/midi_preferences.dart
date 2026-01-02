import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/midi_device.dart';

/// Manages persistent storage for MIDI settings.
class MidiPreferences {
  static const _keyLastDeviceId = 'midi_last_device_id';
  static const _keyLastDevice = 'midi_last_device';
  static const _keyLastConnectedAtMs = 'midi_last_connected_at_ms';
  static const _keyAutoReconnect = 'midi_auto_reconnect';

  final SharedPreferences _prefs;

  const MidiPreferences(this._prefs);

  String? getLastDeviceId() => _prefs.getString(_keyLastDeviceId);

  MidiDevice? getLastDevice() {
    final json = _prefs.getString(_keyLastDevice);
    if (json == null) return null;

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return MidiDevice.fromJson(map);
    } catch (e) {
      debugPrint('Error decoding last device: $e');
      return null;
    }
  }

  int? getLastConnectedAtMs() => _prefs.getInt(_keyLastConnectedAtMs);

  Future<void> setLastDevice(MidiDevice device) async {
    final toStore = device.copyWith(isConnected: false);
    await _prefs.setString(_keyLastDeviceId, toStore.id);
    await _prefs.setString(_keyLastDevice, jsonEncode(toStore.toJson()));
    await _prefs.setInt(
      _keyLastConnectedAtMs,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> clearLastDevice() async {
    await _prefs.remove(_keyLastDeviceId);
    await _prefs.remove(_keyLastDevice);
    await _prefs.remove(_keyLastConnectedAtMs);
  }

  Future<void> clearAllMidiData() async {
    await _prefs.remove(_keyLastDeviceId);
    await _prefs.remove(_keyLastDevice);
    await _prefs.remove(_keyLastConnectedAtMs);
    await _prefs.remove(_keyAutoReconnect);
  }

  bool getAutoReconnect() => _prefs.getBool(_keyAutoReconnect) ?? true;

  Future<void> setAutoReconnect(bool enabled) async {
    await _prefs.setBool(_keyAutoReconnect, enabled);
  }
}
