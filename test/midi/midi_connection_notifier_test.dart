import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:whatchord_app/core/providers/shared_preferences_provider.dart';
import 'package:whatchord_app/features/midi/models/bluetooth_state.dart';
import 'package:whatchord_app/features/midi/models/midi_connection.dart';
import 'package:whatchord_app/features/midi/models/midi_device.dart';
import 'package:whatchord_app/features/midi/providers/bluetooth_permission_service_provider.dart';
import 'package:whatchord_app/features/midi/providers/midi_ble_service_provider.dart';
import 'package:whatchord_app/features/midi/providers/midi_connection_notifier.dart';
import 'package:whatchord_app/features/midi/providers/midi_preferences_notifier.dart';

import 'fake_midi_ble_service.dart';

const _deviceA = MidiDevice(
  id: 'aaa',
  name: 'JamCorder',
  transport: MidiTransportType.ble,
  isConnected: false,
);

/// Wires a container around the fake transport inside a FakeAsync zone.
///
/// All timers (backoff sleeps, timeouts, the post-connect settle) are fake,
/// so scenarios advance with `async.elapse`. Wall-clock reads
/// (`DateTime.now`) are real, which keeps the 5s auto-reconnect rate limit
/// *engaged* for back-to-back automatic triggers inside a test; scenarios
/// that need a second trigger use manual or bt-ready paths that bypass or
/// escape it.
class _Harness {
  _Harness(FakeAsync async, SharedPreferences prefs)
    : ble = FakeMidiBleService() {
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        midiBleServiceProvider.overrideWithValue(ble),
        bluetoothPermissionServiceProvider.overrideWithValue(
          FakeBluetoothPermissionService(),
        ),
      ],
    );
    _subscription = container.listen(midiConnectionStateProvider, (_, _) {});
    async.flushMicrotasks();
  }

  final FakeMidiBleService ble;
  late final ProviderContainer container;
  late final ProviderSubscription<MidiConnectionState> _subscription;

  MidiConnectionNotifier get notifier =>
      container.read(midiConnectionStateProvider.notifier);
  MidiConnectionState get state => container.read(midiConnectionStateProvider);

  /// Persists a last-connected device so auto reconnect has a target.
  void seedLastConnected(FakeAsync async, MidiDevice device) {
    unawaited(
      container
          .read(midiPreferencesProvider.notifier)
          .setLastConnectedDevice(device),
    );
    async.flushMicrotasks();
  }

  /// Connects [device] through the notifier (a manual user action) and
  /// advances past the post-connect settle.
  void connectNow(FakeAsync async, MidiDevice device) {
    ble.discoverable = [device];
    unawaited(notifier.connect(device));
    async.flushMicrotasks();
    async.elapse(const Duration(seconds: 1));
    async.flushMicrotasks();
  }

  void dispose(FakeAsync async) {
    _subscription.close();
    container.dispose();
    ble.dispose();
    async.flushMicrotasks();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    silenceDebugPrint();
    SharedPreferences.setMockInitialValues(const {});
    prefs = await SharedPreferences.getInstance();
  });

  test('startup reconnect retries with exponential backoff until the device '
      'reappears', () {
    fakeAsync((async) {
      final h = _Harness(async, prefs);
      h.seedLastConnected(async, _deviceA);
      h.ble.discoverable = const [];

      unawaited(
        h.notifier.tryAutoReconnect(reason: MidiReconnectTrigger.startup),
      );
      async.flushMicrotasks();

      expect(h.state.phase, MidiConnectionPhase.retrying);
      expect(h.state.attempt, 1);
      expect(h.state.nextDelay, const Duration(seconds: 1));

      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(h.state.attempt, 2, reason: 'second attempt after 1s backoff');
      expect(h.state.nextDelay, const Duration(seconds: 2));

      // The device comes back; the third attempt finds and connects it.
      h.ble.discoverable = const [_deviceA];
      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();

      expect(h.state.phase, MidiConnectionPhase.connected);
      expect(h.state.device?.id, _deviceA.id);
      h.dispose(async);
    });
  });

  test('cancel during backoff stops the loop and settles on idle', () {
    fakeAsync((async) {
      final h = _Harness(async, prefs);
      h.seedLastConnected(async, _deviceA);
      h.ble.discoverable = const [];

      unawaited(
        h.notifier.tryAutoReconnect(reason: MidiReconnectTrigger.startup),
      );
      async.flushMicrotasks();
      expect(h.state.phase, MidiConnectionPhase.retrying);

      unawaited(h.notifier.cancel());
      async.flushMicrotasks();
      expect(h.state.phase, MidiConnectionPhase.idle);

      final devicesCalls = h.ble.devicesCalls;
      async.elapse(const Duration(minutes: 2));
      async.flushMicrotasks();
      expect(h.ble.devicesCalls, devicesCalls, reason: 'loop is dead');
      expect(h.state.phase, MidiConnectionPhase.idle);
      h.dispose(async);
    });
  });

  test('backgrounding stops the reconnect loop', () {
    fakeAsync((async) {
      final h = _Harness(async, prefs);
      h.seedLastConnected(async, _deviceA);
      h.ble.discoverable = const [];

      unawaited(
        h.notifier.tryAutoReconnect(reason: MidiReconnectTrigger.startup),
      );
      async.flushMicrotasks();
      expect(h.state.phase, MidiConnectionPhase.retrying);

      h.notifier.setBackgrounded(true);
      async.flushMicrotasks();

      final devicesCalls = h.ble.devicesCalls;
      async.elapse(const Duration(minutes: 2));
      async.flushMicrotasks();
      expect(
        h.ble.devicesCalls,
        devicesCalls,
        reason:
            'no attempts while '
            'backgrounded',
      );
      h.dispose(async);
    });
  });

  test('an explicit disconnect suppresses automatic reconnect until a manual '
      'trigger', () {
    fakeAsync((async) {
      final h = _Harness(async, prefs);
      h.connectNow(async, _deviceA);
      expect(h.state.phase, MidiConnectionPhase.connected);

      unawaited(h.notifier.disconnect());
      async.flushMicrotasks();
      expect(h.state.phase, MidiConnectionPhase.idle);

      final connectCalls = h.ble.connectCalls;
      unawaited(
        h.notifier.tryAutoReconnect(reason: MidiReconnectTrigger.resume),
      );
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 3));
      async.flushMicrotasks();
      expect(h.ble.connectCalls, connectCalls, reason: 'resume suppressed');
      expect(h.state.phase, MidiConnectionPhase.idle);

      unawaited(
        h.notifier.tryAutoReconnect(reason: MidiReconnectTrigger.manual),
      );
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 3));
      async.flushMicrotasks();
      expect(h.state.phase, MidiConnectionPhase.connected);
      expect(h.ble.connectCalls, connectCalls + 1);
      h.dispose(async);
    });
  });

  test('losing Bluetooth mid-reconnect surfaces unavailable; recovery '
      'reconnects', () {
    fakeAsync((async) {
      final h = _Harness(async, prefs);
      h.seedLastConnected(async, _deviceA);
      h.ble.discoverable = const [];

      unawaited(
        h.notifier.tryAutoReconnect(reason: MidiReconnectTrigger.manual),
      );
      async.flushMicrotasks();
      expect(h.state.phase, MidiConnectionPhase.retrying);

      h.ble.emitBluetoothState(BluetoothState.poweredOff);
      async.flushMicrotasks();
      expect(h.state.phase, MidiConnectionPhase.bluetoothUnavailable);

      h.ble.discoverable = const [_deviceA];
      h.ble.emitBluetoothState(BluetoothState.poweredOn);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 3));
      async.flushMicrotasks();

      expect(h.state.phase, MidiConnectionPhase.connected);
      expect(h.state.device?.id, _deviceA.id);
      h.dispose(async);
    });
  });

  test('the startup trigger runs at most once per app run', () {
    fakeAsync((async) {
      final h = _Harness(async, prefs);
      h.seedLastConnected(async, _deviceA);
      h.ble.discoverable = const [_deviceA];

      unawaited(
        h.notifier.tryAutoReconnect(reason: MidiReconnectTrigger.startup),
      );
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 3));
      async.flushMicrotasks();
      expect(h.state.phase, MidiConnectionPhase.connected);
      expect(h.ble.connectCalls, 1);

      unawaited(
        h.notifier.tryAutoReconnect(reason: MidiReconnectTrigger.startup),
      );
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 3));
      async.flushMicrotasks();
      expect(h.ble.connectCalls, 1, reason: 'second startup is a no-op');
      h.dispose(async);
    });
  });

  test('resume revalidates a stale connected snapshot and reconnects', () {
    fakeAsync((async) {
      final h = _Harness(async, prefs);
      h.connectNow(async, _deviceA);
      expect(h.state.phase, MidiConnectionPhase.connected);

      // The link died at the transport level, but app state still says
      // connected (the iOS backgrounded-drop shape).
      h.ble.connectedIds.clear();

      unawaited(
        h.notifier.tryAutoReconnect(reason: MidiReconnectTrigger.resume),
      );
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 3));
      async.flushMicrotasks();

      expect(h.state.phase, MidiConnectionPhase.connected);
      expect(h.ble.connectedIds, {_deviceA.id}, reason: 'reconnected');
      expect(h.ble.connectCalls, 2);
      h.dispose(async);
    });
  });
}
