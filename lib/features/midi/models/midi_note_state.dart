import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';

enum PedalInputSource { midi, manual }

/// Tracks MIDI note on/off state and sustain pedal.
///
/// **Terminology**: "MIDI note" refers to note numbers (0-127), not musical
/// note names (C, F#, etc.). Musical spelling is handled by the theory domain.
@immutable
class MidiNoteState {
  final Set<int> pressed; // keys physically down
  final Set<int> sustained; // keys released while pedal down
  final bool isPedalDown;

  /// Where the current pedal state originated.
  final PedalInputSource pedalSource;

  const MidiNoteState({
    required this.pressed,
    required this.sustained,
    required this.isPedalDown,
    this.pedalSource = PedalInputSource.midi,
  });

  Set<int> get soundingNoteNumbers => {...pressed, ...sustained};

  MidiNoteState copyWith({
    Set<int>? pressed,
    Set<int>? sustained,
    bool? isPedalDown,
    PedalInputSource? pedalSource,
  }) {
    return MidiNoteState(
      pressed: pressed ?? this.pressed,
      sustained: sustained ?? this.sustained,
      isPedalDown: isPedalDown ?? this.isPedalDown,
      pedalSource: pedalSource ?? this.pedalSource,
    );
  }

  static const _noteSetEquality = SetEquality<int>();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MidiNoteState &&
          runtimeType == other.runtimeType &&
          isPedalDown == other.isPedalDown &&
          pedalSource == other.pedalSource &&
          _noteSetEquality.equals(pressed, other.pressed) &&
          _noteSetEquality.equals(sustained, other.sustained);

  @override
  int get hashCode => Object.hash(
    isPedalDown,
    pedalSource,
    _noteSetEquality.hash(pressed),
    _noteSetEquality.hash(sustained),
  );
}
