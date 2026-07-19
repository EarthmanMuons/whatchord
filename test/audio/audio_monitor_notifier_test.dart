import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:whatchord_app/core/providers/shared_preferences_provider.dart';
import 'package:whatchord_app/features/audio/models/audio_monitor_status.dart';
import 'package:whatchord_app/features/audio/providers/audio_monitor_notifier.dart';
import 'package:whatchord_app/features/audio/providers/audio_monitor_settings_notifier.dart';
import 'package:whatchord_app/features/audio/services/audio_monitor_engine.dart';
import 'package:whatchord_app/features/input/input.dart';
import 'package:whatchord_app/features/midi/providers/bluetooth_permission_service_provider.dart';
import 'package:whatchord_app/features/midi/providers/midi_ble_service_provider.dart';
import 'package:whatchord_app/features/midi/providers/midi_output_sender_provider.dart';
import 'package:whatchord_app/features/midi/services/midi_output_sender.dart';

import '../midi/fake_midi_ble_service.dart';

/// Records the note traffic the notifier sends to the synth.
class FakeAudioMonitorEngine implements AudioMonitorEngine {
  final List<String> log = [];
  bool running = false;
  double volume = -1;

  @override
  String get soundFontAssetPath => 'fake';

  @override
  bool get isRunning => running;

  @override
  Future<void> start() async {
    running = true;
    log.add('start');
  }

  @override
  Future<void> stop() async {
    running = false;
    log.add('stop');
  }

  @override
  Future<void> setVolume(double value) async {
    volume = value;
  }

  @override
  Future<void> noteOn(int midiNote, {int velocity = 100}) async {
    log.add('on:$midiNote');
  }

  @override
  Future<void> noteOff(int midiNote) async {
    log.add('off:$midiNote');
  }

  @override
  Future<void> allNotesOff() async {
    log.add('allOff');
  }
}

/// Inert stand-in; the internal-mode tests never send MIDI out.
class FakeMidiOutputSender implements MidiOutputSender {
  @override
  int get channel => 0;

  @override
  void noteOn(int note, {int velocity = 100}) {}

  @override
  void noteOff(int note) {}

  @override
  void panic() {}
}

class _NotesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => const {};

  void set(Set<int> notes) => state = notes;
}

final _notesProvider = NotifierProvider<_NotesNotifier, Set<int>>(
  _NotesNotifier.new,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeMidiBleService ble;
  late FakeAudioMonitorEngine engine;
  late ProviderContainer container;

  Future<void> setUpContainer({Set<int> initialNotes = const {}}) async {
    silenceDebugPrint();
    ble = FakeMidiBleService();
    engine = FakeAudioMonitorEngine();
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        midiBleServiceProvider.overrideWithValue(ble),
        bluetoothPermissionServiceProvider.overrideWithValue(
          const FakeBluetoothPermissionService(),
        ),
        midiOutputSenderProvider.overrideWithValue(FakeMidiOutputSender()),
        audioMonitorEngineFactoryProvider.overrideWithValue(() => engine),
        soundingNoteNumbersProvider.overrideWith(
          (ref) => ref.watch(_notesProvider),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(ble.dispose);
    if (initialNotes.isNotEmpty) {
      container.read(_notesProvider.notifier).set(initialNotes);
    }
    final subscription = container.listen(audioMonitorNotifier, (_, _) {});
    addTearDown(subscription.close);
    await pumpEventQueue();
  }

  AudioMonitorNotifier notifier() =>
      container.read(audioMonitorNotifier.notifier);

  Future<void> setNotes(Set<int> notes) async {
    container.read(_notesProvider.notifier).set(notes);
    await pumpEventQueue();
  }

  Future<void> noteOnEvent(int note) async {
    notifier().onInputNoteEvent(
      InputNoteEvent(
        type: InputNoteEventType.noteOn,
        noteNumber: note,
        velocity: 100,
      ),
    );
    await pumpEventQueue();
  }

  Future<void> noteOffEvent(int note) async {
    notifier().onInputNoteEvent(
      InputNoteEvent(
        type: InputNoteEventType.noteOff,
        noteNumber: note,
        velocity: 0,
      ),
    );
    await pumpEventQueue();
  }

  test('starts the engine with the configured volume', () async {
    await setUpContainer();

    expect(engine.running, isTrue);
    expect(engine.volume, closeTo(0.7, 0.001), reason: 'internal default');
    expect(
      container.read(audioMonitorNotifier).status,
      AudioMonitorStatus.running,
    );
  });

  test(
    'a cold start with held notes bootstraps them into the engine',
    () async {
      await setUpContainer(initialNotes: {60, 64});
      expect(engine.log.where((e) => e == 'on:60'), hasLength(1));
      expect(engine.log.where((e) => e == 'on:64'), hasLength(1));
    },
  );

  test(
    'enabling the monitor mid-hold stays silent until fresh input',
    () async {
      await setUpContainer(initialNotes: {60});
      await container
          .read(audioMonitorSettingsNotifier.notifier)
          .setMuted(true);
      await pumpEventQueue();
      engine.log.clear();

      await container
          .read(audioMonitorSettingsNotifier.notifier)
          .setMuted(false);
      await pumpEventQueue();

      expect(engine.running, isTrue);
      expect(
        engine.log.where((e) => e.startsWith('on:')),
        isEmpty,
        reason: 'held notes are not re-attacked on enable',
      );
    },
  );

  test('note events attack once; the sounding-note sync does not double '
      'attack', () async {
    await setUpContainer();
    engine.log.clear();

    await noteOnEvent(60);
    await setNotes({60});

    expect(engine.log, ['on:60'], reason: 'single attack for one keypress');
  });

  test('re-striking a sounding note retriggers it', () async {
    await setUpContainer();
    await noteOnEvent(60);
    await setNotes({60});
    engine.log.clear();

    await noteOnEvent(60);
    expect(engine.log, ['off:60', 'on:60']);
  });

  test('a note held by sustain survives its note-off event and ends with '
      'the sustain', () async {
    await setUpContainer();
    await noteOnEvent(60);
    await setNotes({60});
    engine.log.clear();

    // Key released but sustain holds it: sounding notes still contain 60.
    await noteOffEvent(60);
    expect(engine.log, isEmpty, reason: 'sync keeps the note alive');

    // Pedal lifts: nothing sounds anymore.
    await setNotes({});
    expect(engine.log, ['allOff']);
  });

  test('sync releases stop each note once; a full release clears the rest '
      'wholesale', () async {
    await setUpContainer();
    await noteOnEvent(60);
    await noteOnEvent(64);
    await setNotes({60, 64});
    engine.log.clear();

    // A partial release stops exactly the note that left the sounding set.
    await setNotes({64});
    expect(engine.log, ['off:60']);

    // Releasing everything takes the all-notes-off safety net, not per-note
    // offs, recovering from any missed events along the way.
    await setNotes({});
    expect(engine.log, ['off:60', 'allOff']);
  });

  test('backgrounding silences the engine and resume does not re-attack '
      'held notes', () async {
    await setUpContainer(initialNotes: {60});
    engine.log.clear();

    notifier().setBackgrounded(true);
    await pumpEventQueue();
    expect(engine.running, isFalse);

    notifier().setBackgrounded(false);
    await pumpEventQueue();
    await setNotes({60});

    expect(engine.running, isTrue);
    expect(
      engine.log.where((e) => e.startsWith('on:')),
      isEmpty,
      reason: 'held notes wait for fresh events after resume',
    );
  });

  test('muting stops the engine', () async {
    await setUpContainer();
    expect(engine.running, isTrue);

    await container.read(audioMonitorSettingsNotifier.notifier).setMuted(true);
    await pumpEventQueue();

    expect(engine.running, isFalse);
    expect(
      container.read(audioMonitorNotifier).status,
      AudioMonitorStatus.disabled,
    );
  });
}
