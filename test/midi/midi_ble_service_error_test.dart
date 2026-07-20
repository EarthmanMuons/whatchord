import 'package:flutter_midi_command/flutter_midi_command.dart' as fmc;
import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord_app/features/midi/services/midi_ble_service.dart';

void main() {
  String describe(fmc.MidiConnectionException e) =>
      MidiBleService.connectionFailureMessage(e);

  test('maps typed connection failures to user-facing guidance', () {
    expect(
      describe(
        fmc.MidiConnectionTimeoutException(
          deviceId: 'x',
          stage: fmc.MidiConnectionStage.bluetoothConnect,
          timeout: const Duration(seconds: 6),
        ),
      ),
      contains('powered on and nearby'),
    );
    expect(
      describe(fmc.MidiPairingRejectedException(deviceId: 'x')),
      contains('accept the pairing request'),
    );
    expect(
      describe(fmc.MidiPairingFailedException(deviceId: 'x')),
      contains('forget the device'),
    );
    expect(
      describe(fmc.MidiPairingInfoRemovedException(deviceId: 'x')),
      contains('no longer recognizes its pairing'),
    );
    expect(
      describe(fmc.MidiServiceDiscoveryException(deviceId: 'x')),
      contains('does not offer MIDI'),
    );
    expect(
      describe(fmc.MidiNotificationSubscriptionException(deviceId: 'x')),
      contains('could not start receiving notes'),
    );
  });

  test('unmapped subtypes fall back to the plugin message', () {
    final generic = fmc.MidiConnectionException(
      deviceId: 'x',
      stage: fmc.MidiConnectionStage.platformConnect,
      message: 'Something platform-specific.',
    );
    expect(describe(generic), 'Something platform-specific.');
  });
}
