import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bluetooth_access.dart';
import '../models/bluetooth_state.dart';
import '../models/midi_device.dart';
import '../services/bluetooth_permission_service.dart';
import '../services/midi_ble_service.dart';
import 'bluetooth_permission_service_provider.dart';
import 'midi_ble_service_provider.dart';

@immutable
class MidiDeviceManagerState {
  const MidiDeviceManagerState({
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

  MidiDeviceManagerState copyWith({
    List<MidiDevice>? devices,
    Object? connectedDevice = _unset, // MidiDevice? or null
    BluetoothState? bluetoothState,
    bool? isScanning,
  }) {
    return MidiDeviceManagerState(
      devices: devices ?? this.devices,
      connectedDevice: identical(connectedDevice, _unset)
          ? this.connectedDevice
          : connectedDevice as MidiDevice?,
      bluetoothState: bluetoothState ?? this.bluetoothState,
      isScanning: isScanning ?? this.isScanning,
    );
  }

  static const initial = MidiDeviceManagerState(
    devices: <MidiDevice>[],
    connectedDevice: null,
    bluetoothState: BluetoothState.unknown,
    isScanning: false,
  );
}

/// Manages Bluetooth MIDI transport: scanning, device discovery, connections.
///
/// **Responsibilities:**
/// - Bluetooth central lifecycle
/// - Device scanning and enumeration
/// - Low-level connect/disconnect operations
/// - Connection health monitoring (watchdog)
///
/// **Not Responsible For:**
/// - Retry logic (see [MidiConnectionNotifier])
/// - Auto-reconnect workflows (see [MidiConnectionNotifier])
/// - UI state presentation (see [MidiConnectionStatus])
///
/// This is the "dumb" transport layer. Higher-level orchestration lives
/// in [MidiConnectionNotifier].
final midiDeviceManagerProvider =
    NotifierProvider<MidiDeviceManager, MidiDeviceManagerState>(
      MidiDeviceManager.new,
    );

class MidiDeviceManager extends Notifier<MidiDeviceManagerState> {
  // ---- Tunables ----------------------------------------------------------

  static const Duration _minRefreshInterval = Duration(milliseconds: 700);
  static const Duration _watchdogInterval = Duration(seconds: 16);
  static const Duration _setupDebounceDelay = Duration(milliseconds: 250);

  static const Duration _disconnectBeforeReconnectDelay = Duration(
    milliseconds: 300,
  );
  static const Duration _postConnectSettleDelay = Duration(milliseconds: 800);
  static const Duration _connectTimeout = Duration(seconds: 6);

  static const Duration _waitForDeviceTimeout = Duration(seconds: 6);

  static const Duration _btPrimeTimeout = Duration(seconds: 2);
  static const Duration _btPrimeHardTimeout = Duration(seconds: 3);
  static const bool _debugLog = false;

  // ---- Runtime -----------------------------------------------------------

  late final MidiBleService _ble = ref.read(midiBleServiceProvider);
  late final BluetoothPermissionService _bluetoothPerms = ref.read(
    bluetoothPermissionServiceProvider,
  );

  StreamSubscription<BluetoothState>? _bluetoothSub;
  StreamSubscription<void>? _setupChangeSub;

  Timer? _setupDebounce;
  Timer? _connectionWatchdog;
  Future<void>? _reconcileInFlight;

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
  MidiDeviceManagerState build() {
    state = MidiDeviceManagerState.initial;

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
    if (_debugLog) debugPrint('[MGR] backgrounded=$_backgrounded');
    _updateConnectionWatchdog();
  }

  Future<void> startScanning() => _ensureScanning();

  // Force refresh the device list, optionally ensuring scanning is active.
  // - ensureScanning=true: explicit user intent to discover devices, so priming is OK.
  // - ensureScanning=false: will NOT prime; refresh only if central already started or scanning.
  Future<void> refreshDevices({bool ensureScanning = true}) async {
    if (ensureScanning) {
      await _ensureScanning(); // primes + starts scan if needed
    } else {
      // Avoid "hidden" priming
      if (!_centralStarted && !state.isScanning) return;
    }

    if (_debugLog) {
      debugPrint(
        '[MGR] refreshDevices ensureScanning=$ensureScanning '
        'central=$_centralStarted scanning=${state.isScanning}',
      );
    }
    await _refreshDeviceList(bypassThrottle: true);
  }

  // Forcefully restart scanning (stop then start) as a recovery action.
  // Intended for "Refresh" / "Try again" UI when scanning stalls on some platforms.
  Future<void> restartScanning() async {
    // If scan isn't running, just start.
    if (!state.isScanning) {
      await startScanning();
      return;
    }

    // Best-effort stop.
    await stopScanning();

    // Small delay can help some stacks settle.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    await startScanning();
  }

  Future<void> stopScanning() async {
    if (!state.isScanning) return;

    try {
      _ble.stopScanning();
    } catch (e) {
      debugPrint('Warning: Error stopping MIDI scan: $e');
    } finally {
      if (_debugLog) debugPrint('[MGR] stopScanning');
      state = state.copyWith(isScanning: false);
      _updateConnectionWatchdog();
    }
  }

  Future<void> connect(MidiDevice device) async {
    try {
      if (_debugLog) debugPrint('[MGR] connect id=${device.id}');
      await _ensureBluetoothCentralReady();

      // Do not stop scanning until after connection is verified.
      // With the Bluetooth service boundary, we connect by id and verify by querying state.
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
      if (_debugLog) debugPrint('[MGR] disconnect id=${current.id}');
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

  /// Resolve a reconnect target by id, or by name/transport if the id changed.
  Future<MidiDevice?> findReconnectTarget({
    required String deviceId,
    MidiDevice? hint,
  }) async {
    try {
      await _ensureBluetoothCentralReady();

      await _ensureScanning();
      await _refreshDeviceList(bypassThrottle: true);

      final byId = _findDeviceInList(state.devices, deviceId);
      if (byId != null) {
        if (_debugLog) debugPrint('[MGR] findReconnectTarget byId=$deviceId');
        return byId;
      }

      if (hint == null) {
        if (_debugLog) {
          debugPrint('[MGR] findReconnectTarget no hint for id=$deviceId');
        }
        return null;
      }

      final byHint = _findDeviceByHint(hint);
      if (byHint != null) {
        if (_debugLog) {
          debugPrint(
            '[MGR] findReconnectTarget byHint id=${byHint.id} name=${byHint.name}',
          );
        }
      } else if (_debugLog) {
        debugPrint(
          '[MGR] findReconnectTarget no match for hint name=${hint.name} '
          'transport=${hint.transport}',
        );
      }
      return byHint;
    } catch (e) {
      debugPrint('findReconnectTarget failed: $e');
      return null;
    }
  }

  Future<BluetoothAccessResult> ensureBluetoothAccess() =>
      _bluetoothPerms.ensureBluetoothAccess();

  /// Foreground reconciliation: confirms whether our last-known connected device
  /// is still actually connected at the plugin level.
  ///
  /// This is particularly important on iOS where the OS may drop Bluetooth connections
  /// while the app is backgrounded without producing a timely setup-change event.
  Future<void> reconcileConnectedDevice({
    String reason = 'foreground',
    bool scanIfNeeded = false,
  }) {
    final inflight = _reconcileInFlight;
    if (inflight != null) return inflight;

    if (_debugLog) {
      debugPrint(
        '[MGR] reconcile start reason=$reason scanIfNeeded=$scanIfNeeded '
        'connected=${state.connectedDevice?.id}/${state.connectedDevice?.isConnected} '
        'central=$_centralStarted scanning=${state.isScanning}',
      );
    }
    final fut = _reconcileConnectedDeviceImpl(
      reason: reason,
      scanIfNeeded: scanIfNeeded,
    );
    _reconcileInFlight = fut;
    return fut.whenComplete(() => _reconcileInFlight = null);
  }

  Future<void> _reconcileConnectedDeviceImpl({
    required String reason,
    required bool scanIfNeeded,
  }) async {
    final current = state.connectedDevice;
    if (current == null) return;

    try {
      // If we believe we are connected, it is reasonable to prime the central
      // on foreground so we can validate the connection.
      await _ensureBluetoothCentralReady();
    } catch (e) {
      // If Bluetooth is off/unauthorized, our BT state listener should clear the
      // connection anyway. If we cannot prime, don't blindly clear here.
      debugPrint('reconcileConnectedDevice($reason): prime failed: $e');
      return;
    }

    if (scanIfNeeded && !state.isScanning) {
      await _pulseScan(reason: reason);
    }

    try {
      final actuallyConnected = await _ble.isConnected(current.id);
      if (_debugLog) {
        debugPrint(
          '[MGR] reconcile result reason=$reason id=${current.id} '
          'actuallyConnected=$actuallyConnected',
        );
      }
      if (!actuallyConnected) {
        debugPrint(
          'reconcileConnectedDevice($reason): stale connection cleared id=${current.id}',
        );
        _setConnectedDevice(null);
      } else {
        // Keep the flag fresh in case our stored snapshot drifted.
        _setConnectedDevice(current.copyWith(isConnected: true));
      }
    } catch (e) {
      // If the plugin can't answer reliably, do not oscillate UI.
      debugPrint('reconcileConnectedDevice($reason): isConnected failed: $e');
    }
  }

  Future<T> _withTimeout<T>(Future<T> future, {required Duration timeout}) =>
      future.timeout(timeout);

  /// Best-effort "is still connected" check used by higher-level workflows.
  Future<bool> isStillConnected(String deviceId) async {
    try {
      await _ensureBluetoothCentralReady();
      return await _withTimeout(
        _ble.isConnected(deviceId),
        timeout: const Duration(seconds: 2),
      );
    } catch (_) {
      return false;
    }
  }

  // ---- Lazy Bluetooth prime ---------------------------------------------

  /// Prime the Bluetooth stack without starting a scan.
  Future<void> ensureReady() => _ensureBluetoothCentralReady();

  Future<void> _ensureBluetoothCentralReady() {
    if (_centralStarted) return Future.value();

    final inflight = _centralStartInFlight;
    if (inflight != null) return inflight;

    final fut = _ensureBluetoothCentralReadyImpl()
        // IMPORTANT: guard against native/plugin hangs.
        .timeout(
          _btPrimeHardTimeout,
          onTimeout: () {
            throw const MidiException('Bluetooth prime timed out');
          },
        );
    _centralStartInFlight = fut;
    return fut.whenComplete(() => _centralStartInFlight = null);
  }

  Future<void> _ensureBluetoothCentralReadyImpl() async {
    try {
      if (_debugLog) debugPrint('[MGR] ensureCentralReady start');
      await _ble.ensureCentralReady(timeout: _btPrimeTimeout);
      _centralStarted = true;

      // Publish post-prime state.
      _handleBluetoothStateChange(_ble.bluetoothState);
      if (_debugLog) {
        debugPrint(
          '[MGR] ensureCentralReady ok state=${_ble.bluetoothState}',
        );
      }
    } catch (e) {
      _centralStarted = false;
      if (_debugLog) debugPrint('[MGR] ensureCentralReady failed: $e');
      throw MidiException('Failed to initialize Bluetooth MIDI', e);
    }
  }

  // ---- Listeners ---------------------------------------------------------

  void _setupListeners() {
    _bluetoothSub = _ble.onBluetoothStateChanged.listen(
      _handleBluetoothStateChange,
    );

    _setupChangeSub = _ble.onMidiSetupChanged.listen((_) {
      if (_debugLog) debugPrint('[MGR] onMidiSetupChanged');
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

      if (_debugLog) {
        debugPrint(
          '[MGR] refreshDevices safe bypass=$bypassThrottle '
          'central=$_centralStarted scanning=${state.isScanning}',
        );
      }
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
    if (_debugLog) {
      debugPrint(
        '[MGR] devices count=${devices.length} '
        'connected=${state.connectedDevice?.id}/${state.connectedDevice?.isConnected}',
      );
    }

    state = state.copyWith(devices: devices);
    _signalDevicesChanged();

    unawaited(_syncConnectedDeviceState(devices));
  }

  void _signalDevicesChanged() {
    if (_devicesChanged.isClosed) return;
    _devicesChanged.add(null);
  }

  int _emptySnapshotsWhileConnected = 0;

  Future<void> _syncConnectedDeviceState(List<MidiDevice> devices) async {
    final current = state.connectedDevice;
    if (current == null) return;

    // The plugin can transiently report an empty device list; debounce to avoid
    // dropping a valid connection on a single bad snapshot.
    if (devices.isEmpty) {
      _emptySnapshotsWhileConnected++;
      if (_debugLog) {
        debugPrint(
          '[MGR] sync empty snapshots=$_emptySnapshotsWhileConnected '
          'id=${current.id}',
        );
      }

      // Require 2 consecutive empty snapshots to avoid flapping.
      if (_emptySnapshotsWhileConnected < 2) return;

      final actuallyConnected = await _withTimeout(
        _ble.isConnected(current.id),
        timeout: const Duration(seconds: 2),
      );
      if (_debugLog) {
        debugPrint(
          '[MGR] sync empty verify id=${current.id} '
          'actuallyConnected=$actuallyConnected',
        );
      }
      if (!actuallyConnected) {
        _setConnectedDevice(null);
      }
      return;
    }

    _emptySnapshotsWhileConnected = 0;

    final match = _firstWhereOrNull(devices, (d) => d.id == current.id);

    if (match == null || !match.isConnected) {
      final actuallyConnected = await _ble.isConnected(current.id);
      if (_debugLog) {
        debugPrint(
          '[MGR] sync mismatch id=${current.id} match=${match?.id}/${match?.isConnected} '
          'actuallyConnected=$actuallyConnected',
        );
      }
      if (!actuallyConnected) {
        _setConnectedDevice(null);
      }
      return;
    }

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
    if (_debugLog) debugPrint('[MGR] startScanning');
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
    if (_debugLog) {
      debugPrint('[MGR] waitForDevice start id=$deviceId timeout=${timeout.inSeconds}s');
    }

    Timer? pump;
    Timer? deadline;
    StreamSubscription<void>? sub;
    final completer = Completer<MidiDevice?>();

    pump = Timer.periodic(const Duration(milliseconds: 250), (_) {
      // Fire-and-forget; refresh is already coalesced by _deviceRefreshInFlight.
      unawaited(_safeRefreshDevices(bypassThrottle: true));
    });

    // Absolute timeout: do not reset just because device snapshots keep arriving.
    deadline = Timer(timeout, () {
      if (completer.isCompleted) return;
      if (_debugLog) {
        debugPrint('[MGR] waitForDevice timeout id=$deviceId');
      }
      completer.complete(null);
    });

    sub = _devicesChanged.stream.listen((_) {
      if (completer.isCompleted) return;
      final found = _findDeviceInList(state.devices, deviceId);
      if (found == null) return;
      if (_debugLog) {
        debugPrint('[MGR] waitForDevice found id=$deviceId');
      }
      completer.complete(found);
    });

    try {
      return await completer.future;
    } finally {
      pump.cancel();
      deadline.cancel();
      unawaited(sub.cancel());
    }
  }

  // ---- Connection helpers ------------------------------------------------

  Future<void> _cleanupStaleConnection(String deviceId) async {
    // If it's already connected at plugin level, disconnect first.
    // This is best-effort; failure should not prevent a fresh attempt.
    try {
      final connected = await _withTimeout(
        _ble.isConnected(deviceId),
        timeout: const Duration(seconds: 2),
      );
      if (_debugLog) {
        debugPrint(
          '[MGR] cleanupStale id=$deviceId connected=$connected',
        );
      }
      if (!connected) return;

      await _ble.disconnect(deviceId);
      await Future<void>.delayed(_disconnectBeforeReconnectDelay);
    } catch (_) {}
  }

  Future<void> _performConnection(String deviceId) async {
    if (_debugLog) debugPrint('[MGR] performConnection id=$deviceId');
    await _ble.connect(deviceId).timeout(
      _connectTimeout,
      onTimeout: () {
        throw const MidiException('Connection timed out');
      },
    );
    await Future<void>.delayed(_postConnectSettleDelay);
  }

  Future<void> _verifyConnection(String deviceId) async {
    final connected = await _withTimeout(
      _ble.isConnected(deviceId),
      timeout: const Duration(seconds: 2),
    );
    if (_debugLog) debugPrint('[MGR] verifyConnection id=$deviceId ok=$connected');
    if (!connected) {
      throw const MidiException('Connection failed - device not responding');
    }
  }

  void _setConnectedDevice(MidiDevice? device) {
    final prev = state.connectedDevice;
    if (prev?.id != device?.id || prev?.isConnected != device?.isConnected) {
      debugPrint(
        '[MGR] connected ${prev?.id}/${prev?.isConnected} -> ${device?.id}/${device?.isConnected}',
      );
    }
    if (device == null) _emptySnapshotsWhileConnected = 0;
    state = state.copyWith(connectedDevice: device);
    _updateConnectionWatchdog();
  }

  // ---- Watchdog ----------------------------------------------------------

  void _updateConnectionWatchdog() {
    final shouldRun =
        state.connectedDevice != null && !_backgrounded && !state.isScanning;

    if (shouldRun) {
      if (_debugLog) {
        debugPrint(
          '[MGR] watchdog start id=${state.connectedDevice?.id} '
          'scanning=${state.isScanning} bg=$_backgrounded',
        );
      }
      _startConnectionWatchdog();
    } else {
      if (_debugLog) debugPrint('[MGR] watchdog stop');
      _stopConnectionWatchdog();
    }
  }

  void _startConnectionWatchdog() {
    _connectionWatchdog?.cancel();
    _connectionWatchdog = Timer.periodic(_watchdogInterval, (_) {
      if (_backgrounded) return;
      if (state.connectedDevice == null) return;
      if (state.isScanning) return;

      unawaited(
        reconcileConnectedDevice(reason: 'watchdog', scanIfNeeded: true),
      );
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

    if (_debugLog) {
      debugPrint('BT mapped=$mapped last=$_lastPublishedBtState');
    }

    if (mapped == BluetoothState.poweredOff ||
        mapped == BluetoothState.unauthorized) {
      // If BT is off/unauthorized, any prior central prime is not trustworthy.
      _centralStarted = false;

      _setConnectedDevice(null);
      unawaited(stopScanning());
    }

    _lastPublishedBtState = mapped;
    state = state.copyWith(bluetoothState: mapped);
  }

  Future<void> _pulseScan({
    required String reason,
    Duration dwell = const Duration(milliseconds: 350),
  }) async {
    if (state.isScanning) return;
    if (_scanInFlight != null) return;

    try {
      if (_debugLog) debugPrint('[MGR] pulseScan start reason=$reason');
      await _ble.startScanning();
      state = state.copyWith(isScanning: true);
      await Future<void>.delayed(dwell);
      await _refreshDeviceList(bypassThrottle: true);
    } catch (e) {
      debugPrint('pulseScan($reason) failed: $e');
    } finally {
      try {
        _ble.stopScanning();
      } catch (e) {
        debugPrint('pulseScan($reason) stop failed: $e');
      } finally {
        if (_debugLog) debugPrint('[MGR] pulseScan end reason=$reason');
        state = state.copyWith(isScanning: false);
        _updateConnectionWatchdog();
      }
    }
  }

  // ---- Utilities ---------------------------------------------------------

  MidiDevice? _findDeviceInList(List<MidiDevice> devices, String id) {
    for (final d in devices) {
      if (d.id == id) return d;
    }
    return null;
  }

  MidiDevice? _findDeviceByHint(MidiDevice hint) {
    final hintName = hint.name.trim().toLowerCase();
    if (hintName.isEmpty) return null;

    final matches =
        state.devices
            .where(
              (d) =>
                  d.transport == hint.transport &&
                  d.name.trim().toLowerCase() == hintName,
            )
            .toList();

    if (matches.length == 1) return matches.first;
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
