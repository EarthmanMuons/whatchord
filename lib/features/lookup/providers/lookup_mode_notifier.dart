import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/demo/demo.dart';
import 'package:whatchord/features/midi/midi_input_source.dart';

import '../lookup_voicing.dart';

/// Manual chord-lookup mode: the user taps note names to identify a chord
/// without a MIDI device. Lookup, demo, and live MIDI are mutually exclusive
/// input sources; entering lookup turns demo off, and demo or live MIDI input
/// turns lookup off.
@immutable
class LookupState {
  const LookupState({required this.active, required this.pitchClasses});

  static const empty = LookupState(active: false, pitchClasses: <int>[]);

  final bool active;

  /// Entered pitch classes in selection order; the first entry is the bass.
  final List<int> pitchClasses;

  LookupState copyWith({bool? active, List<int>? pitchClasses}) => LookupState(
    active: active ?? this.active,
    pitchClasses: pitchClasses ?? this.pitchClasses,
  );
}

final lookupModeProvider = NotifierProvider<LookupModeNotifier, LookupState>(
  LookupModeNotifier.new,
);

/// Convenience boolean for widgets that only care whether lookup is active.
final lookupActiveProvider = Provider<bool>(
  (ref) => ref.watch(lookupModeProvider.select((s) => s.active)),
);

/// Ordered MIDI voicing for the current selection (ascending; first = bass).
final lookupVoicingProvider = Provider<List<int>>((ref) {
  final state = ref.watch(lookupModeProvider);
  if (!state.active) return const <int>[];
  return LookupVoicing.midiFromPitchClasses(state.pitchClasses);
});

/// Synthesized MIDI note numbers for the current lookup selection.
final lookupNoteNumbersProvider = Provider<Set<int>>((ref) {
  return ref.watch(lookupVoicingProvider).toSet();
});

class LookupModeNotifier extends Notifier<LookupState> {
  @override
  LookupState build() {
    // Modes are mutually exclusive: demo turning on exits lookup.
    ref.listen<bool>(demoModeProvider, (prev, next) {
      if (next && state.active) exit();
    });

    // Live MIDI input always wins: any sounding note exits lookup.
    ref.listen<int>(midiSoundingNoteNumbersProvider.select((s) => s.length), (
      prev,
      next,
    ) {
      if (next > 0 && state.active) exit();
    });

    return LookupState.empty;
  }

  void enter() {
    if (state.active) return;
    ref.read(demoModeProvider.notifier).setEnabled(false);
    state = const LookupState(active: true, pitchClasses: <int>[]);
  }

  void exit() {
    if (!state.active) return;
    state = LookupState.empty;
  }

  /// Appends a note to the selection. Repeats are allowed (each tap adds and
  /// re-strikes); use [removeLast] or [clear] to remove. The first note added
  /// is the bass.
  void addNote(int pitchClass) {
    if (!state.active) return;
    state = state.copyWith(
      pitchClasses: [...state.pitchClasses, pitchClass % 12],
    );
  }

  void clear() {
    if (!state.active || state.pitchClasses.isEmpty) return;
    state = state.copyWith(pitchClasses: const <int>[]);
  }

  void removeLast() {
    if (!state.active || state.pitchClasses.isEmpty) return;
    final next = state.pitchClasses.sublist(0, state.pitchClasses.length - 1);
    state = state.copyWith(pitchClasses: next);
  }
}
