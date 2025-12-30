import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/midi_device.dart';

/// Manages persistent storage for MIDI settings.
class MidiPreferences {
  static const _keyLastDeviceId = 'midi_last_device_id';
  static const _keyLastDevice = 'midi_last_device';
  static const _keyLastConnectedAtMs = 'midi_last_connected_at_ms';
  static const _keyMidiMode = 'midi_mode';
  static const _keyAutoReconnect = 'midi_auto_reconnect';

  final SharedPreferences _prefs;

  const MidiPreferences(this._prefs);

  // ============================================================
  // Factory
  // ============================================================

  /// Create an instance by loading SharedPreferences.
  static Future<MidiPreferences> create() async {
    final prefs = await SharedPreferences.getInstance();
    return MidiPreferences(prefs);
  }

  // ============================================================
  // Last Connected Device
  // ============================================================

  /// Get the ID of the last connected device.
  String? getLastDeviceId() {
    return _prefs.getString(_keyLastDeviceId);
  }

  /// Get the full device object of the last connected device.
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

  /// Save the last connected device.
  Future<void> setLastDevice(MidiDevice device) async {
    final toStore = device.copyWith(isConnected: false);
    await _prefs.setString(_keyLastDeviceId, toStore.id);
    await _prefs.setString(_keyLastDevice, jsonEncode(toStore.toJson()));
    await _prefs.setInt(
      _keyLastConnectedAtMs,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Clear the last connected device.
  Future<void> clearLastDevice() async {
    await _prefs.remove(_keyLastDeviceId);
    await _prefs.remove(_keyLastDevice);
  }

  // ============================================================
  // MIDI Mode (Stub vs Real)
  // ============================================================

  /// Get the MIDI mode ('stub' or 'real').
  String getMidiMode() {
    return _prefs.getString(_keyMidiMode) ?? 'stub';
  }

  /// Set the MIDI mode.
  Future<void> setMidiMode(String mode) async {
    await _prefs.setString(_keyMidiMode, mode);
  }

  // ============================================================
  // Auto-Reconnect Setting
  // ============================================================

  /// Whether auto-reconnect is enabled.
  bool getAutoReconnect() {
    return _prefs.getBool(_keyAutoReconnect) ?? true;
  }

  /// Set auto-reconnect preference.
  Future<void> setAutoReconnect(bool enabled) async {
    await _prefs.setBool(_keyAutoReconnect, enabled);
  }
}
