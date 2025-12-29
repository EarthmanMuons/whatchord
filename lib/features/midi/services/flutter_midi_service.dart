import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_midi_command/flutter_midi_command.dart' as fmc;

import '../models/bluetooth_state.dart';
import '../models/midi_device.dart';
import 'midi_service.dart';

/// Real MIDI service implementation using flutter_midi_command.
class FlutterMidiService implements MidiService {
  final fmc.MidiCommand _midi = fmc.MidiCommand();

  final _devicesController = StreamController<List<MidiDevice>>.broadcast();
  final _bluetoothController = StreamController<BluetoothState>.broadcast();

  MidiDevice? _connectedDevice;
  bool _isScanning = false;
  bool _isInitialized = false;

  StreamSubscription<fmc.BluetoothState>? _bluetoothSub;
  StreamSubscription<String>? _setupChangeSub;

  // ============================================================
  // Stream Getters
  // ============================================================

  @override
  Stream<List<MidiDevice>> get availableDevices => _devicesController.stream;

  @override
  Stream<Uint8List> get midiDataStream {
    return _midi.onMidiDataReceived?.map((packet) {
          return Uint8List.fromList(packet.data);
        }) ??
        const Stream.empty();
  }

  @override
  Stream<BluetoothState> get bluetoothState => _bluetoothController.stream;

  // ============================================================
  // State Getters
  // ============================================================

  @override
  MidiDevice? get connectedDevice => _connectedDevice;

  @override
  bool get isScanning => _isScanning;

  // ============================================================
  // Lifecycle
  // ============================================================

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Listen to Bluetooth state changes
      _bluetoothSub = _midi.onBluetoothStateChanged.listen((state) {
        _handleBluetoothStateChange(state);
      });

      _setupChangeSub = _midi.onMidiSetupChanged?.listen((_) {
        // When setup changes (device discovered, connected, or disconnected),
        // update the device list
        _updateDeviceList();
      });

      _isInitialized = true;
      return true;
    } catch (e) {
      throw MidiException('Failed to initialize MIDI service', e);
    }
  }

  @override
  Future<void> dispose() async {
    await stopScanning();
    await disconnect();

    await _bluetoothSub?.cancel();
    await _setupChangeSub?.cancel();

    await _devicesController.close();
    await _bluetoothController.close();

    _isInitialized = false;
  }

  // ============================================================
  // Device Discovery
  // ============================================================

  @override
  Future<void> startScanning() async {
    if (!_isInitialized) {
      throw const MidiException('Service not initialized');
    }

    if (_isScanning) return;

    _isScanning = true;

    try {
      // Start BLE scanning
      await _midi.startScanningForBluetoothDevices();

      // Get initial device list immediately
      // (further updates come from onMidiSetupChanged stream)
      _updateDeviceList();
    } catch (e) {
      _isScanning = false;
      throw MidiException('Failed to start scanning', e);
    }
  }

  @override
  Future<void> stopScanning() async {
    if (!_isScanning) return;

    _isScanning = false;

    try {
      _midi.stopScanningForBluetoothDevices();
    } catch (e) {
      print('Warning: Error stopping MIDI scan: $e');
    }
  }

  Future<void> _updateDeviceList() async {
    try {
      final devices = await _midi.devices;

      final midiDevices =
          devices?.where((d) => d.type == 'BLE').map(_convertDevice).toList() ??
          [];

      _devicesController.add(midiDevices);
    } catch (e) {
      print('Error updating device list: $e');
    }
  }

  // ============================================================
  // Connection Management
  // ============================================================

  @override
  Future<void> connect(MidiDevice device) async {
    if (!_isInitialized) {
      throw const MidiException('Service not initialized');
    }

    try {
      await stopScanning();

      final devices = await _midi.devices;
      final nativeDevice = devices?.firstWhere(
        (d) => d.id == device.id,
        orElse: () => throw const MidiException('Device not found'),
      );

      if (nativeDevice == null) {
        throw const MidiException('Device not found');
      }

      await _midi.connectToDevice(nativeDevice);

      // Wait a moment for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify connection
      final updatedDevices = await _midi.devices;
      final connectedDevice = updatedDevices?.firstWhere(
        (d) => d.id == device.id,
      );

      if (connectedDevice?.connected ?? false) {
        _connectedDevice = device.copyWith(isConnected: true);
      } else {
        throw const MidiException('Connection failed - device not responding');
      }
    } catch (e) {
      throw MidiException('Failed to connect to device', e);
    }
  }

  @override
  Future<void> disconnect() async {
    if (_connectedDevice == null) return;

    try {
      final devices = await _midi.devices;
      final nativeDevice = devices?.firstWhere(
        (d) => d.id == _connectedDevice!.id,
      );

      if (nativeDevice != null) {
        // Note: disconnectDevice returns void
        _midi.disconnectDevice(nativeDevice);
      }

      _connectedDevice = null;
    } catch (e) {
      print('Warning: Error disconnecting MIDI device: $e');
      _connectedDevice = null;
    }
  }

  @override
  Future<bool> reconnect(String deviceId) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final devices = await _midi.devices;
      final targetDevice = devices?.firstWhere(
        (d) => d.id == deviceId && d.type == 'BLE',
        orElse: () => throw const MidiException('Device not found'),
      );

      if (targetDevice == null) {
        return false;
      }

      await connect(_convertDevice(targetDevice));
      return true;
    } catch (e) {
      print('Auto-reconnect failed: $e');
      return false;
    }
  }

  // ============================================================
  // Helper Methods
  // ============================================================

  MidiDevice _convertDevice(fmc.MidiDevice nativeDevice) {
    return MidiDevice(
      id: nativeDevice.id,
      name: nativeDevice.name,
      type: nativeDevice.type,
      isConnected: nativeDevice.connected,
    );
  }

  void _handleBluetoothStateChange(fmc.BluetoothState state) {
    final btState = switch (state) {
      fmc.BluetoothState.poweredOn => BluetoothState.on,
      fmc.BluetoothState.poweredOff => BluetoothState.off,
      fmc.BluetoothState.unauthorized => BluetoothState.unauthorized,
      _ => BluetoothState.unknown,
    };

    _bluetoothController.add(btState);
  }
}
