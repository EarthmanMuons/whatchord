import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/ble_access.dart';
import '../models/bluetooth_state.dart';
import '../models/midi_device.dart';
import '../services/midi_ble_service.dart';
import 'midi_ble_service_provider.dart';

@immutable
class MidiManagerState {
  const MidiManagerState({
    required this.devices,
    required this.connectedDevice,
    required this.bluetoothState,
    required this.isScanning,
  });

  final List<MidiDevice> devices;
  final MidiDevice? connectedDevice;
  final BluetoothState bluetoothState;
  final bool isScanning;

  static const Object _unset = Object();

  MidiManagerState copyWith({
    List<MidiDevice>? devices,
    Object? connectedDevice = _unset, // MidiDevice? or null
    BluetoothState? bluetoothState,
    bool? isScanning,
  }) {
    return MidiManagerState(
      devices: devices ?? this.devices,
      connectedDevice: identical(connectedDevice, _unset)
          ? this.connectedDevice
          : connectedDevice as MidiDevice?,
      bluetoothState: bluetoothState ?? this.bluetoothState,
      isScanning: isScanning ?? this.isScanning,
    );
  }

  static const initial = MidiManagerState(
    devices: <MidiDevice>[],
    connectedDevice: null,
    bluetoothState: BluetoothState.unknown,
    isScanning: false,
  );
}

final midiManagerProvider = NotifierProvider<MidiManager, MidiManagerState>(
  MidiManager.new,
);

class MidiManager extends Notifier<MidiManagerState> {
  // ---- Tunables ----------------------------------------------------------

  static const Duration _minRefreshInterval = Duration(milliseconds: 700);
  static const Duration _watchdogInterval = Duration(seconds: 16);
  static const Duration _setupDebounceDelay = Duration(milliseconds: 250);

  static const Duration _disconnectBeforeReconnectDelay = Duration(
    milliseconds: 300,
  );
  static const Duration _postConnectSettleDelay = Duration(milliseconds: 800);

  static const Duration _waitForDeviceTimeout = Duration(seconds: 6);

  static const Duration _btPrimeTimeout = Duration(seconds: 2);

  // ---- Runtime -----------------------------------------------------------

  late final MidiBleService _ble = ref.read(midiBleServiceProvider);

  StreamSubscription<BluetoothState>? _bluetoothSub;
  StreamSubscription<void>? _setupChangeSub;

  Timer? _setupDebounce;
  Timer? _connectionWatchdog;

  Future<void>? _scanInFlight;
  Future<void>? _deviceRefreshInFlight;
  DateTime? _lastDeviceRefreshAt;

  BluetoothState? _lastPublishedBtState;
  bool _backgrounded = false;

  // Lazy Bluetooth central prime.
  bool _centralStarted = false;
  Future<void>? _centralStartInFlight;

  // Internal coordination: signals whenever we publish a new device snapshot.
  final StreamController<void> _devicesChanged =
      StreamController<void>.broadcast();

  // ---- Build / Dispose ---------------------------------------------------

  @override
  MidiManagerState build() {
    state = MidiManagerState.initial;

    // IMPORTANT: We install listeners early, but we do NOT prime Bluetooth here.
    // Bluetooth will be primed lazily when scanning/connecting/reconnecting.
    _setupListeners();

    ref.onDispose(() {
      _setupDebounce?.cancel();
      _connectionWatchdog?.cancel();

      unawaited(_bluetoothSub?.cancel() ?? Future.value());
      unawaited(_setupChangeSub?.cancel() ?? Future.value());

      // Best-effort stop scanning.
      try {
        if (state.isScanning) _ble.stopScanning();
      } catch (_) {}

      // Best-effort disconnect.
      unawaited(disconnect());

      // Close internal signal last.
      unawaited(_devicesChanged.close());
    });

    return state;
  }

  // ---- Public API --------------------------------------------------------

  void setBackgrounded(bool value) {
    _backgrounded = value;
    _updateConnectionWatchdog();
  }

  Future<void> startScanning() => _ensureScanning();

  Future<void> stopScanning() async {
    if (!state.isScanning) return;

    try {
      _ble.stopScanning();
    } catch (e) {
      debugPrint('Warning: Error stopping MIDI scan: $e');
    } finally {
      state = state.copyWith(isScanning: false);
      _updateConnectionWatchdog();
    }
  }

  Future<void> connect(MidiDevice device) async {
    try {
      await _ensureBluetoothCentralReady();

      // Do not stop scanning until after connection is verified.
      // With the BLE service boundary, we connect by id and verify by querying state.
      await _cleanupStaleConnection(device.id);
      await _performConnection(device.id);
      await _verifyConnection(device.id);

      // Publish connected device in app state only after verification.
      _setConnectedDevice(device.copyWith(isConnected: true));

      await stopScanning();
    } catch (e) {
      throw MidiException('Failed to connect to device', e);
    }
  }

  Future<void> disconnect() async {
    final current = state.connectedDevice;
    if (current == null) return;

    try {
      // Best-effort; do not force a prime just to disconnect.
      // If central was never started, this should simply no-op.
      await _disconnectBestEffort(current.id);
    } catch (e) {
      debugPrint('Warning: Error disconnecting MIDI device: $e');
    } finally {
      _setConnectedDevice(null);
    }
  }

  Future<void> _disconnectBestEffort(String deviceId) async {
    if (!_centralStarted) return; // preserve "don’t prime to disconnect"
    await _ble.disconnect(deviceId);
  }

  Future<bool> reconnect(String deviceId) async {
    try {
      await _ensureBluetoothCentralReady();

      await _ensureScanning();
      await _refreshDeviceList(bypassThrottle: true);

      final device = await _waitForDevice(deviceId);
      if (device == null) return false;

      await connect(device);
      return true;
    } catch (e) {
      debugPrint('Auto-reconnect failed: $e');
      return false;
    }
  }

  Future<BleAccessResult> ensureBlePermissions() async {
    if (Platform.isAndroid) return _checkAndroidBlePermissions();
    if (Platform.isIOS) return _checkIosBlePermissions();
    return const BleAccessResult(BleAccessState.ready);
  }

  // ---- Lazy Bluetooth prime ---------------------------------------------

  /// Prime the BLE stack without starting a scan.
  Future<void> ensureReady() => _ensureBluetoothCentralReady();

  Future<void> _ensureBluetoothCentralReady() {
    if (_centralStarted) return Future.value();

    final inflight = _centralStartInFlight;
    if (inflight != null) return inflight;

    final fut = _ensureBluetoothCentralReadyImpl();
    _centralStartInFlight = fut;
    return fut.whenComplete(() => _centralStartInFlight = null);
  }

  Future<void> _ensureBluetoothCentralReadyImpl() async {
    try {
      await _ble.ensureCentralReady(timeout: _btPrimeTimeout);
      _centralStarted = true;

      // Publish post-prime state.
      _handleBluetoothStateChange(_ble.bluetoothState);
    } catch (e) {
      _centralStarted = false;
      throw MidiException('Failed to initialize Bluetooth MIDI', e);
    }
  }

  // ---- Listeners ---------------------------------------------------------

  void _setupListeners() {
    _bluetoothSub = _ble.onBluetoothStateChanged.listen(
      _handleBluetoothStateChange,
    );

    _setupChangeSub = _ble.onMidiSetupChanged.listen((_) {
      _setupDebounce?.cancel();
      _setupDebounce = Timer(_setupDebounceDelay, () {
        final bypass = state.isScanning;
        unawaited(_safeRefreshDevices(bypassThrottle: bypass));
      });
    });

    // Seed initial BT state.
    _handleBluetoothStateChange(_ble.bluetoothState);
  }

  // ---- Device refresh ----------------------------------------------------

  Future<void> _safeRefreshDevices({required bool bypassThrottle}) async {
    try {
      // Only refresh if we have already primed, or if scanning is active.
      // This prevents "hidden" startup priming via refresh paths.
      if (!_centralStarted && !state.isScanning) return;

      await _refreshDeviceList(bypassThrottle: bypassThrottle);
    } catch (e) {
      debugPrint('Device refresh failed: $e');
    }
  }

  Future<void> _refreshDeviceList({required bool bypassThrottle}) {
    final inflight = _deviceRefreshInFlight;
    if (inflight != null) return inflight;

    if (!bypassThrottle && !_shouldRefreshDevices()) {
      return Future.value();
    }

    _lastDeviceRefreshAt = DateTime.now();

    final fut = _updateDeviceListImpl();
    _deviceRefreshInFlight = fut;
    return fut.whenComplete(() => _deviceRefreshInFlight = null);
  }

  bool _shouldRefreshDevices() {
    final last = _lastDeviceRefreshAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >= _minRefreshInterval;
  }

  Future<void> _updateDeviceListImpl() async {
    if (!_centralStarted) return;

    final devices = await _ble.devices();

    state = state.copyWith(devices: devices);
    _signalDevicesChanged();

    unawaited(_syncConnectedDeviceState(devices));
  }

  void _signalDevicesChanged() {
    if (_devicesChanged.isClosed) return;
    _devicesChanged.add(null);
  }

  Future<void> _syncConnectedDeviceState(List<MidiDevice> devices) async {
    final current = state.connectedDevice;
    if (current == null) return;

    // If the snapshot is empty, treat as inconclusive; do not clear connection.
    // This prevents transient empty device lists from dropping UI state.
    if (devices.isEmpty) return;

    final match = _firstWhereOrNull(devices, (d) => d.id == current.id);

    debugPrint(
      'syncConnected: devices=${devices.length} match=${match?.id} matchConnected=${match?.isConnected}',
    );

    // If we can't find the device or it reports not connected, confirm with the plugin.
    if (match == null || !match.isConnected) {
      final actuallyConnected = await _ble.isConnected(current.id);
      if (!actuallyConnected) {
        _setConnectedDevice(null);
      }
      return;
    }

    // Still connected: keep state fresh.
    _setConnectedDevice(current.copyWith(isConnected: true));
  }

  // ---- Scanning ----------------------------------------------------------

  Future<void> _ensureScanning() {
    if (state.isScanning) return Future.value();

    final inflight = _scanInFlight;
    if (inflight != null) return inflight;

    final fut = _startScanImpl();
    _scanInFlight = fut;
    return fut.whenComplete(() => _scanInFlight = null);
  }

  Future<void> _startScanImpl() async {
    await _ensureBluetoothCentralReady();

    await _ble.startScanning();
    state = state.copyWith(isScanning: true);

    await _refreshDeviceList(bypassThrottle: true);
    _updateConnectionWatchdog();
  }

  Future<MidiDevice?> _waitForDevice(
    String deviceId, {
    Duration timeout = _waitForDeviceTimeout,
  }) async {
    // Fast path: already present.
    final existing = _findDeviceInList(state.devices, deviceId);
    if (existing != null) return existing;

    // Refresh once immediately.
    await _refreshDeviceList(bypassThrottle: true);

    // Check again.
    final afterRefresh = _findDeviceInList(state.devices, deviceId);
    if (afterRefresh != null) return afterRefresh;

    // While scanning/connecting, keep refreshing so the device list can actually
    // converge on the target device (iOS can be slow to surface it).
    Timer? pump;
    pump = Timer.periodic(const Duration(milliseconds: 250), (_) {
      // Fire-and-forget; refresh is already coalesced by _deviceRefreshInFlight.
      unawaited(_safeRefreshDevices(bypassThrottle: true));
    });

    // Await device list changes.
    try {
      await for (final _ in _devicesChanged.stream.timeout(timeout)) {
        final found = _findDeviceInList(state.devices, deviceId);
        if (found != null) return found;
      }
    } on TimeoutException {
      return null;
    } finally {
      pump.cancel();
    }

    return null;
  }

  // ---- Connection helpers ------------------------------------------------

  Future<void> _cleanupStaleConnection(String deviceId) async {
    // If it's already connected at plugin level, disconnect first.
    // This is best-effort; failure should not prevent a fresh attempt.
    try {
      final connected = await _ble.isConnected(deviceId);
      if (!connected) return;

      await _ble.disconnect(deviceId);
      await Future<void>.delayed(_disconnectBeforeReconnectDelay);
    } catch (_) {}
  }

  Future<void> _performConnection(String deviceId) async {
    await _ble.connect(deviceId);
    await Future<void>.delayed(_postConnectSettleDelay);
  }

  Future<void> _verifyConnection(String deviceId) async {
    final connected = await _ble.isConnected(deviceId);
    if (!connected) {
      throw const MidiException('Connection failed - device not responding');
    }
  }

  void _setConnectedDevice(MidiDevice? device) {
    state = state.copyWith(connectedDevice: device);
    _updateConnectionWatchdog();
  }

  // ---- Watchdog ----------------------------------------------------------

  void _updateConnectionWatchdog() {
    final shouldRun =
        state.connectedDevice != null && !_backgrounded && !state.isScanning;

    if (shouldRun) {
      _startConnectionWatchdog();
    } else {
      _stopConnectionWatchdog();
    }
  }

  void _startConnectionWatchdog() {
    _connectionWatchdog?.cancel();
    _connectionWatchdog = Timer.periodic(_watchdogInterval, (_) {
      if (_backgrounded) return;
      if (state.connectedDevice == null) return;
      if (state.isScanning) return;

      unawaited(_safeRefreshDevices(bypassThrottle: true));
    });
  }

  void _stopConnectionWatchdog() {
    _connectionWatchdog?.cancel();
    _connectionWatchdog = null;
  }

  // ---- Bluetooth state ---------------------------------------------------

  void _handleBluetoothStateChange(BluetoothState mapped) {
    if (mapped == BluetoothState.unknown &&
        _lastPublishedBtState != null &&
        _lastPublishedBtState != BluetoothState.unknown) {
      return;
    }

    if (mapped == _lastPublishedBtState) return;

    debugPrint('BT mapped=$mapped last=$_lastPublishedBtState');

    if (mapped == BluetoothState.off || mapped == BluetoothState.unauthorized) {
      // If BT is off/unauthorized, any prior central prime is not trustworthy.
      _centralStarted = false;

      _setConnectedDevice(null);
      unawaited(stopScanning());
    }

    _lastPublishedBtState = mapped;
    state = state.copyWith(bluetoothState: mapped);
  }

  // ---- Permissions -------------------------------------------------------

  Future<BleAccessResult> _checkAndroidBlePermissions() async {
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
            'Nearby devices permission is blocked. Enable it in system settings '
            'to connect to Bluetooth MIDI devices.',
      );
    }

    return const BleAccessResult(
      BleAccessState.denied,
      message:
          'Nearby devices permission is required to discover and connect '
          'to Bluetooth MIDI devices.',
    );
  }

  Future<BleAccessResult> _checkIosBlePermissions() async {
    final status = await Permission.bluetooth.status;

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
            'Bluetooth access for this app is disabled in system settings. '
            'Enable it to connect to Bluetooth MIDI devices.',
      );
    }

    return const BleAccessResult(BleAccessState.ready);
  }

  // ---- Utilities ---------------------------------------------------------

  MidiDevice? _findDeviceInList(List<MidiDevice> devices, String id) {
    for (final d in devices) {
      if (d.id == id) return d;
    }
    return null;
  }

  T? _firstWhereOrNull<T>(List<T>? items, bool Function(T) test) {
    if (items == null) return null;
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }
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
