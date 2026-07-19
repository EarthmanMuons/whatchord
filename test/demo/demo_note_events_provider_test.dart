import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord_app/features/demo/demo.dart';
import 'package:whatchord_app/features/demo/providers/demo_note_events_provider.dart';
import 'package:whatchord_app/features/input/input.dart';

class _StubDemoModeNotifier extends DemoModeNotifier {
  @override
  bool build() => false;

  void set(bool value) => state = value;
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

  late ProviderContainer container;
  late List<InputNoteEvent> events;

  setUp(() async {
    container = ProviderContainer(
      overrides: [
        demoModeProvider.overrideWith(_StubDemoModeNotifier.new),
        demoSoundingNoteNumbersProvider.overrideWith(
          (ref) => ref.watch(_notesProvider),
        ),
      ],
    );
    addTearDown(container.dispose);

    events = [];
    final subscription = container.listen(demoNoteEventsProvider, (_, _) {});
    addTearDown(subscription.close);
    final streamSubscription = container
        .read(demoNoteEventsProvider)
        .listen(events.add);
    addTearDown(streamSubscription.cancel);
    await pumpEventQueue();
  });

  void setDemo(bool enabled) {
    final demo =
        container.read(demoModeProvider.notifier) as _StubDemoModeNotifier;
    demo.set(enabled);
  }

  void setNotes(Set<int> notes) {
    container.read(_notesProvider.notifier).set(notes);
  }

  String label(InputNoteEvent e) =>
      '${e.type == InputNoteEventType.noteOn ? 'on' : 'off'}:${e.noteNumber}';

  test('diffs sounding notes into ordered on and off events', () async {
    setDemo(true);
    setNotes({64, 60});
    await pumpEventQueue();
    expect(events.map(label), ['on:60', 'on:64'], reason: 'ons sorted');

    events.clear();
    setNotes({64, 67});
    await pumpEventQueue();
    expect(events.map(label), ['off:60', 'on:67'], reason: 'offs precede ons');
  });

  test('disabling demo mode flushes note-offs for lingering notes', () async {
    setDemo(true);
    setNotes({60, 64});
    await pumpEventQueue();
    events.clear();

    setDemo(false);
    await pumpEventQueue();
    expect(events.map(label), ['off:60', 'off:64']);
  });

  test('note changes while demo mode is off are ignored', () async {
    setNotes({60});
    await pumpEventQueue();
    expect(events, isEmpty);

    // Notes present before enabling become the baseline, not events.
    setDemo(true);
    await pumpEventQueue();
    expect(events, isEmpty);

    setNotes({60, 64});
    await pumpEventQueue();
    expect(events.map(label), ['on:64'], reason: 'only the delta');
  });
}
