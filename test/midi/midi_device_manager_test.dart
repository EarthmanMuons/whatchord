import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:whatchord_app/core/providers/shared_preferences_provider.dart';
import 'package:whatchord_app/features/midi/models/midi_device.dart';
import 'package:whatchord_app/features/midi/providers/bluetooth_permission_service_provider.dart';
import 'package:whatchord_app/features/midi/providers/midi_ble_service_provider.dart';
import 'package:whatchord_app/features/midi/providers/midi_device_manager.dart';

import 'fake_midi_ble_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const deviceA = MidiDevice(
    id: 'aaa',
    name: 'JamCorder',
    transport: MidiTransportType.ble,
    isConnected: false,
  );
  const deviceB = MidiDevice(
    id: 'bbb',
    name: 'Stage Piano',
    transport: MidiTransportType.ble,
    isConnected: false,
  );

  late FakeMidiBleService ble;
  late ProviderContainer container;

  Future<void> setUpContainer() async {
    ble = FakeMidiBleService();
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        midiBleServiceProvider.overrideWithValue(ble),
        bluetoothPermissionServiceProvider.overrideWithValue(
          FakeBluetoothPermissionService(),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(ble.dispose);
    // Keep the manager alive for the test's duration.
    final subscription = container.listen(midiDeviceManagerProvider, (_, _) {});
    addTearDown(subscription.close);
  }

  MidiDeviceManager manager() =>
      container.read(midiDeviceManagerProvider.notifier);
  MidiDeviceManagerState managerState() =>
      container.read(midiDeviceManagerProvider);

  setUp(() async {
    silenceDebugPrint();
    await setUpContainer();
  });

  test('connect publishes the device once the transport confirms it, and '
      'stops scanning', () async {
    ble.discoverable = const [deviceA];

    await manager().connect(deviceA);

    final connected = managerState().connectedDevice;
    expect(connected?.id, deviceA.id);
    expect(connected?.isConnected, isTrue);
    expect(ble.connectedIds, {deviceA.id});
    expect(ble.stopScanningCalls, greaterThanOrEqualTo(0));
  });

  test('a disconnect during an in-flight connect wins the race', () async {
    ble.discoverable = const [deviceA];
    ble.connectGate = Completer<void>();

    final inFlight = manager().connect(deviceA);
    await pumpEventQueue();

    await manager().disconnect();
    ble.connectGate!.complete();
    await inFlight;
    await pumpEventQueue();

    expect(managerState().connectedDevice, isNull, reason: 'not re-published');
    expect(ble.connectedIds, isEmpty, reason: 'superseded link torn down');
  });

  test('switching devices tears down the previous connection first', () async {
    ble.discoverable = const [deviceA, deviceB];

    await manager().connect(deviceA);
    await manager().connect(deviceB);

    expect(managerState().connectedDevice?.id, deviceB.id);
    expect(ble.connectedIds, {deviceB.id}, reason: 'A dropped before B');
  });

  test('one empty device snapshot keeps the connection; a second verifies '
      'and drops a dead link', () async {
    ble.discoverable = const [deviceA];
    await manager().connect(deviceA);

    // The plugin transiently reports nothing, but the link is still live.
    ble.discoverable = const [];
    await manager().refreshDevices(ensureScanning: false);
    await pumpEventQueue();
    expect(managerState().connectedDevice, isNotNull, reason: 'debounced');

    // Second empty snapshot verifies against the transport: still live.
    await manager().refreshDevices(ensureScanning: false);
    await pumpEventQueue();
    expect(managerState().connectedDevice, isNotNull, reason: 'verified live');

    // Link actually died: the next pair of empty snapshots clears it.
    ble.connectedIds.clear();
    await manager().refreshDevices(ensureScanning: false);
    await pumpEventQueue();
    await manager().refreshDevices(ensureScanning: false);
    await pumpEventQueue();
    expect(managerState().connectedDevice, isNull);
  });

  test('reconcileConnectedDevice clears a stale connection and keeps a live '
      'one', () async {
    ble.discoverable = const [deviceA];
    await manager().connect(deviceA);

    await manager().reconcileConnectedDevice(reason: 'test');
    expect(managerState().connectedDevice, isNotNull, reason: 'still live');

    ble.connectedIds.clear();
    await manager().reconcileConnectedDevice(reason: 'test');
    expect(managerState().connectedDevice, isNull, reason: 'stale cleared');
  });

  group('findReconnectTarget', () {
    test('finds the device by id when rediscovered', () async {
      ble.discoverable = const [deviceA];
      final target = await manager().findReconnectTarget(deviceId: deviceA.id);
      expect(target?.id, deviceA.id);
    });

    test(
      'falls back to a name and transport match when the id changed',
      () async {
        const reincarnated = MidiDevice(
          id: 'new-id',
          name: 'JamCorder',
          transport: MidiTransportType.ble,
          isConnected: false,
        );
        ble.discoverable = const [reincarnated];

        final target = await manager().findReconnectTarget(
          deviceId: deviceA.id,
          hint: deviceA,
        );
        expect(target?.id, 'new-id');
      },
    );

    test(
      'matches by name alone across local transports but never network',
      () async {
        const asUsb = MidiDevice(
          id: 'usb-id',
          name: 'JamCorder',
          transport: MidiTransportType.usb,
          isConnected: false,
        );
        ble.discoverable = const [asUsb];
        final target = await manager().findReconnectTarget(
          deviceId: deviceA.id,
          hint: deviceA,
        );
        expect(target?.id, 'usb-id');

        const asNetwork = MidiDevice(
          id: 'net-id',
          name: 'JamCorder',
          transport: MidiTransportType.network,
          isConnected: false,
        );
        ble.discoverable = const [asNetwork];
        final none = await manager().findReconnectTarget(
          deviceId: deviceA.id,
          hint: deviceA,
        );
        expect(none, isNull);
      },
    );

    test('returns null without a hint when the id is gone', () async {
      ble.discoverable = const [deviceB];
      final target = await manager().findReconnectTarget(deviceId: deviceA.id);
      expect(target, isNull);
    });
  });
}
