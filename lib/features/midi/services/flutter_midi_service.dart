import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

import 'package:flutter_midi_command/flutter_midi_command.dart' as fmc;
import 'package:permission_handler/permission_handler.dart';

import '../models/ble_access.dart';
import '../models/bluetooth_state.dart';
import '../models/midi_device.dart';
import 'midi_service.dart';

/// Real MIDI service implementation using flutter_midi_command.
class FlutterMidiService implements MidiService {
  final fmc.MidiCommand _midi = fmc.MidiCommand();

  final _devicesController = StreamController<List<MidiDevice>>.broadcast();
  final _connectedDeviceController = StreamController<MidiDevice?>.broadcast();

  final _bluetoothController = StreamController<BluetoothState>.broadcast();

  List<MidiDevice>? _lastDevices;
  Timer? _setupDebounce;
  DateTime? _lastDeviceRefreshAt;
  Future<void>? _deviceRefreshInFlight;
  static const _minRefreshInterval = Duration(milliseconds: 700);

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
      // Listen to Bluetooth state changes (this updates your providers/UI).
      _bluetoothSub = _midi.onBluetoothStateChanged.listen((state) {
        _handleBluetoothStateChange(state);
      });

      _setupChangeSub = _midi.onMidiSetupChanged?.listen((String _) {
        debugPrint('onMidiSetupChanged');
        _setupDebounce?.cancel();
        _setupDebounce = Timer(const Duration(milliseconds: 250), () async {
          final bypass = _isScanning; // only bypass when scan is active
          await _updateDeviceList(bypassThrottle: bypass);
        });
      });

      // PRIME the plugin BLE stack so bluetoothState is meaningful and
      // reconnect can work without requiring a manual scan.
      try {
        await _midi.startBluetoothCentral();

        await _midi.waitUntilBluetoothIsInitialized().timeout(
          const Duration(seconds: 2),
        );
      } catch (e) {
        // Do not fail initialization; we can still operate in "unavailable" state.
        debugPrint('Bluetooth init/prime failed (non-fatal): $e');
      }

      // Pull an initial device snapshot.
      await _updateDeviceList(bypassThrottle: true);

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

    _setupDebounce?.cancel();
    _setupDebounce = null;
    _isInitialized = false;
  }

  // ============================================================
  // Device Discovery
  // ============================================================

  @override
  Future<void> startScanning() async {
    if (!_isInitialized) throw const MidiException('Service not initialized');
    await ensureScanning();
  }

  Completer<void>? _scanInFlight;

  Future<void> ensureScanning() async {
    if (_isScanning) return;

    final inFlight = _scanInFlight;
    if (inFlight != null) return inFlight.future;

    final c = Completer<void>();
    _scanInFlight = c;

    try {
      await _midi.startScanningForBluetoothDevices();
      _isScanning = true;

      // Do one immediate list refresh after scan start.
      await _updateDeviceList(bypassThrottle: true);

      c.complete();
    } catch (e, st) {
      _isScanning = false;
      c.completeError(e, st);
      rethrow;
    } finally {
      _scanInFlight = null;
    }
  }

  @override
  Future<void> stopScanning() => stopScanningSafe();

  Future<void> stopScanningSafe() async {
    if (!_isScanning) return;

    try {
      _midi.stopScanningForBluetoothDevices();
    } catch (e) {
      debugPrint('Warning: Error stopping MIDI scan: $e');
    } finally {
      _isScanning = false;
    }
  }

  Future<void> _updateDeviceList({bool bypassThrottle = false}) {
    debugPrint('_updateDeviceList()');

    // If a refresh is already running, reuse it.
    final inflight = _deviceRefreshInFlight;
    if (inflight != null) return inflight;

    final last = _lastDeviceRefreshAt;
    final now = DateTime.now();

    if (!bypassThrottle &&
        last != null &&
        now.difference(last) < _minRefreshInterval) {
      return Future.value();
    }

    // Throttle refresh rate.
    _lastDeviceRefreshAt = now;
    final fut = _updateDeviceListImpl();
    _deviceRefreshInFlight = fut;
    return fut.whenComplete(() => _deviceRefreshInFlight = null);
  }

  Future<void> _updateDeviceListImpl() async {
    try {
      final devices = await _midi.devices;

      final midiDevices =
          devices
              ?.where((d) => _isBleType(d.type))
              .map(_convertDevice)
              .toList() ??
          [];

      _lastDevices = midiDevices;
      _devicesController.add(midiDevices);

      // Keep connectedDevice in sync with native state, using the same snapshot.
      final native = devices;
      if (_connectedDevice == null) {
        // Important: don't auto-adopt arbitrary "connected" BLE devices reported by the OS/plugin.
        return;
      }
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
    } catch (e) {
      debugPrint('Error updating device list: $e');
      // If we can't query native devices, clear connection state.
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
        await stopScanningSafe();
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

    try {
      // Ensure scanning is running (idempotent if you gate it).
      await ensureScanning();

      // Force at least one device list push immediately.
      await _updateDeviceList(bypassThrottle: true);

      // Wait for the target to appear via the devices stream.
      final device = await _waitForDevice(deviceId);

      if (device == null) return false;

      await connect(device);
      return true;
    } catch (e) {
      debugPrint('Auto-reconnect failed: $e');
      return false;
    }
  }

  @override
  Future<BleAccessResult> ensureBlePermissions() async {
    if (Platform.isAndroid) {
      final scan = await Permission.bluetoothScan.request();
      final connect = await Permission.bluetoothConnect.request();

      if (scan.isGranted && connect.isGranted) {
        return const BleAccessResult(BleAccessState.ready);
      }

      if (scan.isPermanentlyDenied ||
          connect.isPermanentlyDenied ||
          scan.isRestricted ||
          connect.isRestricted) {
        return const BleAccessResult(
          BleAccessState.permanentlyDenied,
          message:
              'Nearby devices permission is blocked. Enable it in system settings to connect to Bluetooth MIDI devices.',
        );
      }

      return const BleAccessResult(
        BleAccessState.denied,
        message:
            'Nearby devices permission is required to discover and connect to Bluetooth MIDI devices.',
      );
    }

    // iOS: Permission state can be queried, but the system prompt is triggered by
    // actual Bluetooth usage (CoreBluetooth). Still return a stable status here.
    if (Platform.isIOS) {
      final status = await Permission.bluetooth.status;

      if (status.isGranted) {
        return const BleAccessResult(BleAccessState.ready);
      }
      if (status.isRestricted) {
        return const BleAccessResult(
          BleAccessState.restricted,
          message: 'Bluetooth access is restricted on this device.',
        );
      }
      if (status.isPermanentlyDenied) {
        return const BleAccessResult(
          BleAccessState.permanentlyDenied,
          message:
              'Bluetooth permission is disabled. Please enable Bluetooth access for this app in Settings.',
        );
      }
      return const BleAccessResult(
        BleAccessState.denied,
        message:
            'Bluetooth permission is required to discover and connect to BLE MIDI devices.',
      );
    }

    // Other platforms: treat as ready unless we add explicit support later.
    return const BleAccessResult(BleAccessState.ready);
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

  MidiDevice? _findDeviceInList(List<MidiDevice> devices, String id) {
    for (final d in devices) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<MidiDevice?> _waitForDevice(
    String deviceId, {
    Duration timeout = const Duration(seconds: 6),
    Duration refreshInterval = const Duration(milliseconds: 250),
  }) async {
    // Fast path.
    final current = _lastDevices;
    if (current != null) {
      final hit = _findDeviceInList(current, deviceId);
      if (hit != null) return hit;
    }

    Timer? pump;
    try {
      // Pump device snapshots while waiting so the stream actually has
      // opportunities to emit a list containing the device.
      pump = Timer.periodic(refreshInterval, (_) {
        // fire-and-forget: _updateDeviceList already coalesces inflight calls
        // and should bypass/minimize throttling during reconnect.
        _updateDeviceList(bypassThrottle: true);
      });

      // Also do one immediate refresh.
      await _updateDeviceList(bypassThrottle: true);

      return await availableDevices
          .map((devices) => _findDeviceInList(devices, deviceId))
          .where((d) => d != null)
          .cast<MidiDevice>()
          .first
          .timeout(timeout);
    } on TimeoutException {
      return null;
    } finally {
      pump?.cancel();
    }
  }
}
