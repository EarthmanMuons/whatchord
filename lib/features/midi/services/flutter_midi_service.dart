import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter_midi_command/flutter_midi_command.dart' as fmc;

import '../models/bluetooth_state.dart';
import '../models/midi_device.dart';
import 'midi_service.dart';

/// Real MIDI service implementation using flutter_midi_command.
class FlutterMidiService implements MidiService {
  final fmc.MidiCommand _midi = fmc.MidiCommand();

  final _devicesController = StreamController<List<MidiDevice>>.broadcast();
  final _connectedDeviceController = StreamController<MidiDevice?>.broadcast();

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
  Stream<MidiDevice?> get connectedDeviceStream =>
      _connectedDeviceController.stream;

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

      _setupChangeSub = _midi.onMidiSetupChanged?.listen((String _) async {
        // When setup changes (device discovered, connected, or disconnected),
        // update the device list AND refresh our connected-device signal.
        await _updateDeviceList();
        await _refreshConnectedDeviceFromNative();
      });

      await _updateDeviceList();
      await _refreshConnectedDeviceFromNative();

      _connectedDeviceController.add(_connectedDevice);

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
    await _connectedDeviceController.close();
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
      debugPrint('Warning: Error stopping MIDI scan: $e');
    }
  }

  Future<void> _updateDeviceList() async {
    try {
      final devices = await _midi.devices;

      final midiDevices =
          devices
              ?.where((d) => _isBleType(d.type))
              .map(_convertDevice)
              .toList() ??
          [];
      _devicesController.add(midiDevices);
    } catch (e) {
      debugPrint('Error updating device list: $e');
    }
  }

  Future<void> _refreshConnectedDeviceFromNative() async {
    try {
      final devices = await _midi.devices; // may be null
      final native = devices;

      if (native == null || native.isEmpty) {
        _setConnectedDevice(null);
        return;
      }

      // If we already believe we're connected, confirm it still is.
      if (_connectedDevice != null) {
        final match = native
            .where((d) => d.id == _connectedDevice!.id)
            .toList();
        if (match.isNotEmpty && match.first.connected) {
          // Ensure our model reflects connected=true (and emit a fresh value).
          _setConnectedDevice(_connectedDevice!.copyWith(isConnected: true));
          return;
        }
      }

      // Otherwise, select any currently-connected BLE device (if any).
      final connectedBle = native
          .where((d) => d.type == 'BLE' && d.connected)
          .toList();
      if (connectedBle.isEmpty) {
        _setConnectedDevice(null);
        return;
      }

      _setConnectedDevice(
        _convertDevice(connectedBle.first).copyWith(isConnected: true),
      );
    } catch (e) {
      // If querying native devices fails, keep things conservative.
      _setConnectedDevice(null);
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
      // DON'T stop scanning yet - we need the device list!

      final devices = await _midi.devices;
      final nativeDevice = devices?.firstWhere(
        (d) => d.id == device.id,
        orElse: () => throw const MidiException('Device not found'),
      );

      if (nativeDevice == null) {
        throw const MidiException('Device not found');
      }

      // Connect to the device
      await _midi.connectToDevice(nativeDevice);

      // Wait for connection to establish
      await Future.delayed(const Duration(milliseconds: 800));

      // Verify connection
      final updatedDevices = await _midi.devices;
      final connectedDevice = updatedDevices?.firstWhere(
        (d) => d.id == device.id,
      );

      if (connectedDevice?.connected ?? false) {
        _setConnectedDevice(device.copyWith(isConnected: true));

        if (_isScanning) {
          await stopScanning();
        }
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

      _setConnectedDevice(null);
    } catch (e) {
      debugPrint('Warning: Error disconnecting MIDI device: $e');
      _setConnectedDevice(null);
    }
  }

  @override
  Future<bool> reconnect(String deviceId) async {
    if (!_isInitialized) {
      await initialize();
    }

    fmc.MidiDevice? findTarget(List<fmc.MidiDevice>? devices) {
      if (devices == null) return null;
      for (final d in devices) {
        if (d.id == deviceId && _isBleType(d.type)) return d;
      }
      return null;
    }

    Future<fmc.MidiDevice?> pollForTarget({
      Duration timeout = const Duration(seconds: 4),
      Duration interval = const Duration(milliseconds: 250),
    }) async {
      final deadline = DateTime.now().add(timeout);
      while (DateTime.now().isBefore(deadline)) {
        final devices = await _midi.devices;
        final t = findTarget(devices);
        if (t != null) return t;
        await Future.delayed(interval);
      }
      return null;
    }

    try {
      // Cheap check first (may work if scan is already running elsewhere).
      var target = findTarget(await _midi.devices);

      if (target == null) {
        // Start scanning and KEEP it running until connect() finishes.
        _isScanning = true;
        await _midi.startScanningForBluetoothDevices();

        // Update device stream while scanning.
        await _updateDeviceList();

        target = await pollForTarget();

        // Do NOT stop scanning here.
        // connect() will stop scanning after it connects (or after failure handling).
      }

      if (target == null) return false;

      await connect(_convertDevice(target));
      return true;
    } catch (e) {
      debugPrint('Auto-reconnect failed: $e');
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

  bool _isBleType(String type) {
    final t = type.trim().toLowerCase();
    return t == 'ble' || t == 'bluetooth' || t.contains('ble');
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

  void _setConnectedDevice(MidiDevice? device) {
    _connectedDevice = device;
    _connectedDeviceController.add(_connectedDevice);
  }
}
