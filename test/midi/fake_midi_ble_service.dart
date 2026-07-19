import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord_app/features/midi/models/bluetooth_access.dart';
import 'package:whatchord_app/features/midi/models/bluetooth_state.dart';
import 'package:whatchord_app/features/midi/models/midi_device.dart';
import 'package:whatchord_app/features/midi/models/midi_message.dart';
import 'package:whatchord_app/features/midi/services/bluetooth_permission_service.dart';
import 'package:whatchord_app/features/midi/services/midi_ble_service.dart';

/// Silences [debugPrint] for the current test, restoring it on tear-down.
///
/// The connection stack's non-release logging is deliberate in the app, but
/// these tests exercise dozens of connect/disconnect transitions and would
/// drown the runner output.
void silenceDebugPrint() {
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {};
  addTearDown(() => debugPrint = original);
}

/// Deterministic in-memory stand-in for the BLE transport seam.
///
/// Tests mutate [discoverable] and [connectedIds] to model the plugin's
/// device world, use [connectGate]/[connectError] to shape in-flight
/// connects, and emit Bluetooth states through [emitBluetoothState]. Call
/// counters expose what the stack actually asked the transport to do.
class FakeMidiBleService implements MidiBleService {
  final _bluetoothStates = StreamController<BluetoothState>.broadcast();
  final _setupChanges = StreamController<void>.broadcast();
  final _messages = StreamController<MidiMessage>.broadcast();

  BluetoothState currentBluetoothState = BluetoothState.poweredOn;

  /// Devices a scan can currently see (the plugin's device list).
  List<MidiDevice> discoverable = const [];

  /// Device ids with a live link at the transport level.
  final Set<String> connectedIds = {};

  int connectCalls = 0;
  int disconnectCalls = 0;
  int startScanningCalls = 0;
  int stopScanningCalls = 0;
  int devicesCalls = 0;

  /// When set, [connect] parks on this gate before completing, letting tests
  /// interleave a disconnect with an in-flight connect.
  Completer<void>? connectGate;

  /// When set, [connect] throws this instead of connecting.
  Object? connectError;

  void emitBluetoothState(BluetoothState state) {
    currentBluetoothState = state;
    _bluetoothStates.add(state);
  }

  void emitSetupChanged() => _setupChanges.add(null);

  void emitMessage(MidiMessage message) => _messages.add(message);

  void dispose() {
    unawaited(_bluetoothStates.close());
    unawaited(_setupChanges.close());
    unawaited(_messages.close());
  }

  @override
  Stream<BluetoothState> get onBluetoothStateChanged => _bluetoothStates.stream;

  @override
  Stream<void> get onMidiSetupChanged => _setupChanges.stream;

  @override
  Stream<MidiMessage> get onMidiMessages => _messages.stream;

  @override
  BluetoothState get bluetoothState => currentBluetoothState;

  @override
  Future<void> startCentral({
    Duration timeout = const Duration(seconds: 2),
  }) async {}

  @override
  Future<void> waitUntilInitialized({
    Duration timeout = const Duration(seconds: 2),
  }) async {}

  @override
  Future<void> ensureCentralReady({
    Duration timeout = const Duration(seconds: 2),
  }) async {}

  @override
  Future<void> startScanning({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    startScanningCalls += 1;
  }

  @override
  Future<void> stopScanning() async {
    stopScanningCalls += 1;
  }

  @override
  Future<List<MidiDevice>> devices() async {
    devicesCalls += 1;
    return [
      for (final device in discoverable)
        device.copyWith(isConnected: connectedIds.contains(device.id)),
    ];
  }

  @override
  Future<void> connect(
    String deviceId, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    connectCalls += 1;
    final gate = connectGate;
    if (gate != null) await gate.future;
    final error = connectError;
    if (error != null) throw error;
    connectedIds.add(deviceId);
  }

  @override
  Future<void> disconnect(String deviceId) async {
    disconnectCalls += 1;
    connectedIds.remove(deviceId);
  }

  @override
  Future<bool> isConnected(String deviceId) async =>
      connectedIds.contains(deviceId);
}

/// Permission service that always answers with [result].
class FakeBluetoothPermissionService implements BluetoothPermissionService {
  const FakeBluetoothPermissionService([
    this.result = const BluetoothAccessResult(BluetoothAccessState.ready),
  ]);

  final BluetoothAccessResult result;

  @override
  Future<BluetoothAccessResult> ensureBluetoothAccess() async => result;
}
