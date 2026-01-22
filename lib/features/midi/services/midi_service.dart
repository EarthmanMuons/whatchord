import 'dart:async';
import 'dart:typed_data';

import '../models/ble_access.dart';
import '../models/bluetooth_state.dart';
import '../models/midi_device.dart';

/// Abstract interface for MIDI functionality.
///
/// This allows easy swapping between real MIDI hardware and stub
/// implementations for testing/development.
abstract class MidiService {
  // ============================================================
  // Streams
  // ============================================================

  /// Stream of available MIDI devices.
  ///
  /// Updates when devices are discovered or removed during scanning.
  Stream<List<MidiDevice>> get availableDevices;

  /// Stream of the currently connected device.
  ///
  /// Emits the connected [MidiDevice] when a connection is established and
  /// `null` when disconnected.
  Stream<MidiDevice?> get connectedDeviceStream;

  /// Stream of raw MIDI data packets.
  ///
  /// Each emission is a complete MIDI message as [Uint8List].
  Stream<Uint8List> get midiDataStream;

  /// Stream of Bluetooth adapter state changes.
  Stream<BluetoothState> get bluetoothState;

  // ============================================================
  // State Getters
  // ============================================================

  /// The currently connected device, or null if disconnected.
  MidiDevice? get connectedDevice;

  /// Whether the service is currently scanning for devices.
  bool get isScanning;

  // ============================================================
  // Lifecycle
  // ============================================================

  /// Initialize the MIDI service.
  ///
  /// Must be called before any other methods.
  /// Returns true if initialization succeeded.
  Future<bool> initialize();

  /// Clean up resources.
  ///
  /// Should be called when the service is no longer needed.
  Future<void> dispose();

  /// Inform the MIDI service whether the app is backgrounded.
  ///
  /// Used to suspend polling/watchdogs to avoid unnecessary work.
  void setBackgrounded(bool value);

  // ============================================================
  // Device Discovery
  // ============================================================

  /// Start scanning for available MIDI devices.
  ///
  /// Updates will be emitted via [availableDevices] stream.
  Future<void> startScanning();

  /// Stop scanning for MIDI devices.
  Future<void> stopScanning();

  // ============================================================
  // Connection Management
  // ============================================================

  /// Connect to a specific MIDI device.
  ///
  /// Throws [MidiException] if connection fails.
  Future<void> connect(MidiDevice device);

  /// Disconnect from the currently connected device.
  Future<void> disconnect();

  /// Attempt to reconnect to a previously connected device by ID.
  ///
  /// Returns true if reconnection succeeded, false otherwise.
  /// This is used for auto-reconnect on app launch.
  Future<bool> reconnect(String deviceId);

  /// Ensure runtime permissions required for BLE scanning/connecting are granted.
  ///
  /// On iOS this reflects current authorization state; the system prompt is
  /// still triggered by actual Bluetooth usage.
  Future<BleAccessResult> ensureBlePermissions();
}

/// Exception thrown by MIDI operations.
class MidiException implements Exception {
  final String message;
  final Object? cause;

  const MidiException(this.message, [this.cause]);

  @override
  String toString() =>
      'MidiException: $message${cause != null ? ' ($cause)' : ''}';
}
