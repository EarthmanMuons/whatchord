import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord_app/features/input/input.dart';
import 'package:whatchord_app/features/midi/models/midi_message.dart';
import 'package:whatchord_app/features/midi/providers/midi_ble_service_provider.dart';
import 'package:whatchord_app/features/midi/providers/midi_note_events_provider.dart';

import 'fake_midi_ble_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeMidiBleService ble;
  late ProviderContainer container;
  late List<InputNoteEvent> events;

  setUp(() async {
    ble = FakeMidiBleService();
    container = ProviderContainer(
      overrides: [midiBleServiceProvider.overrideWithValue(ble)],
    );
    addTearDown(container.dispose);
    addTearDown(ble.dispose);

    events = [];
    final subscription = container.listen(midiNoteEventsProvider, (_, _) {});
    addTearDown(subscription.close);
    final streamSubscription = container
        .read(midiNoteEventsProvider)
        .listen(events.add);
    addTearDown(streamSubscription.cancel);
    await pumpEventQueue();
  });

  test('maps note messages to input events and ignores the rest', () async {
    ble.emitMessage(
      const MidiMessage(type: MidiMessageType.noteOn, note: 60, velocity: 100),
    );
    ble.emitMessage(
      const MidiMessage(
        type: MidiMessageType.controlChange,
        ccNumber: 64,
        ccValue: 127,
      ),
    );
    ble.emitMessage(
      const MidiMessage(type: MidiMessageType.noteOff, note: 60, velocity: 0),
    );
    await pumpEventQueue();

    expect(events, hasLength(2), reason: 'control change filtered out');
    expect(events[0].type, InputNoteEventType.noteOn);
    expect(events[0].noteNumber, 60);
    expect(events[0].velocity, 100);
    expect(events[1].type, InputNoteEventType.noteOff);
    expect(events[1].noteNumber, 60);
  });

  test('clamps out-of-range note numbers and velocities', () async {
    ble.emitMessage(
      const MidiMessage(type: MidiMessageType.noteOn, note: 200, velocity: 300),
    );
    await pumpEventQueue();

    expect(events.single.noteNumber, 127);
    expect(events.single.velocity, 127);
  });
}
