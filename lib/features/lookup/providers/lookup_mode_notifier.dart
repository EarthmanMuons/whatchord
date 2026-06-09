import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/demo/demo.dart';
import 'package:whatchord/features/midi/midi_input_source.dart';

import '../lookup_voicing.dart';

/// Manual chord-lookup mode: the user taps note names to identify a chord
/// without a MIDI device. Opening the pad leaves a running tour (demo) in place
/// so it keeps driving the card; tapping the first note is real input and ends
/// the tour. Live MIDI input also turns lookup off.
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
    // Tapping a note is real input: it ends a running tour (demo), which would
    // otherwise keep driving the card while the empty pad sits open.
    if (ref.read(demoModeProvider)) {
      ref.read(demoModeProvider.notifier).setEnabled(false);
    }
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
