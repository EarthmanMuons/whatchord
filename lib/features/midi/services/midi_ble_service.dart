import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'package:flutter_midi_command/flutter_midi_command.dart' as fmc;

import '../models/bluetooth_state.dart';
import '../models/midi_device.dart';

/// Low-level MIDI-over-BLE (Bluetooth Low Energy) transport service.
///
/// Wraps flutter_midi_command plugin interactions. Higher-level orchestration
/// (scanning workflow, retries, state management) lives in [MidiDeviceManager]
/// and [MidiConnectionNotifier].
class MidiBleService {
  MidiBleService(this._midi);

  final fmc.MidiCommand _midi;

  // ---- Streams -----------------------------------------------------------

  Stream<BluetoothState> get onBluetoothStateChanged =>
      _midi.onBluetoothStateChanged.map(_mapBluetoothState);

  /// Emits an event whenever the underlying MIDI setup changes.
  ///
  /// Some platforms/versions may not expose this stream; in that case it is empty.
  Stream<void> get onMidiSetupChanged =>
      (_midi.onMidiSetupChanged ?? const Stream.empty()).map((_) {});

  /// Stream of raw MIDI data packets as bytes.
  ///
  /// If the plugin does not expose a MIDI data stream on this platform/version,
  /// this stream is empty.
  Stream<Uint8List> get onMidiData =>
      _midi.onMidiDataReceived?.map(
        (packet) => Uint8List.fromList(packet.data),
      ) ??
      const Stream<Uint8List>.empty();

  // ---- Bluetooth Central -------------------------------------------------

  BluetoothState get bluetoothState => _mapBluetoothState(_midi.bluetoothState);

  Future<void> startCentral({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    // IMPORTANT: startBluetoothCentral can hang; guard it.
    await _midi.startBluetoothCentral().timeout(timeout);
  }

  Future<void> waitUntilInitialized({
    Duration timeout = const Duration(seconds: 2),
  }) => _midi.waitUntilBluetoothIsInitialized().timeout(timeout);

  /// Convenience: start + wait, since callers almost always want both.
  Future<void> ensureCentralReady({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    await startCentral(timeout: timeout);
    await waitUntilInitialized(timeout: timeout);
  }

  // ---- Scanning ----------------------------------------------------------

  Future<void> startScanning() => _midi.startScanningForBluetoothDevices();

  Future<void> stopScanning() async {
    // Plugin API is void; keep this Future-returning for call-site symmetry.
    _midi.stopScanningForBluetoothDevices();
  }

  // ---- Devices -----------------------------------------------------------

  Future<List<MidiDevice>> devices() async {
    final nativeDevices = await _midi.devices.timeout(
      const Duration(seconds: 2),
      onTimeout: () => null,
    );
    return nativeDevices?.map(_convertToMidiDevice).toList() ??
        const <MidiDevice>[];
  }

  // ---- Connection --------------------------------------------------------

  Future<void> connect(String deviceId) async {
    final native = await _findNativeDevice(deviceId);
    await _midi.connectToDevice(native);
  }

  Future<void> disconnect(String deviceId) async {
    final native = await _findNativeDeviceOrNull(deviceId);
    if (native == null) return;
    _midi.disconnectDevice(native);
  }

  Future<bool> isConnected(String deviceId) async {
    final native = await _findNativeDeviceOrNull(deviceId);
    return native?.connected ?? false;
  }

  // ---- Native helpers ----------------------------------------------------

  Future<fmc.MidiDevice> _findNativeDevice(String deviceId) async {
    final native = await _findNativeDeviceOrNull(deviceId);
    if (native == null) {
      throw BleServiceException('Device not found: $deviceId');
    }
    return native;
  }

  Future<fmc.MidiDevice?> _findNativeDeviceOrNull(String deviceId) async {
    final devices = await _midi.devices.timeout(
      const Duration(seconds: 2),
      onTimeout: () => null,
    );
    if (devices == null || devices.isEmpty) return null;

    for (final d in devices) {
      if (d.id == deviceId) return d;
    }
    return null;
  }

  // ---- Type Conversions --------------------------------------------------

  BluetoothState _mapBluetoothState(fmc.BluetoothState state) {
    return switch (state) {
      fmc.BluetoothState.poweredOn => BluetoothState.poweredOn,
      fmc.BluetoothState.poweredOff => BluetoothState.poweredOff,
      fmc.BluetoothState.unauthorized => BluetoothState.unauthorized,
      _ => BluetoothState.unknown,
    };
  }

  MidiDevice _convertToMidiDevice(fmc.MidiDevice device) => MidiDevice(
    id: device.id,
    name: device.name,
    transport: MidiTransportType.fromString(device.type),
    isConnected: device.connected,
  );
}

class BleServiceException implements Exception {
  final String message;
  final Object? cause;

  const BleServiceException(this.message, [this.cause]);

  @override
  String toString() =>
      'BleServiceException: $message${cause != null ? ' ($cause)' : ''}';
}
