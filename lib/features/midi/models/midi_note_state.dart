import 'package:flutter/foundation.dart';

import 'package:collection/collection.dart';

@immutable
class MidiNoteState {
  final Set<int> pressed; // keys physically down
  final Set<int> sustained; // keys released while pedal down
  final bool isPedalDown;

  const MidiNoteState({
    required this.pressed,
    required this.sustained,
    required this.isPedalDown,
  });

  Set<int> get soundingNotes => {...pressed, ...sustained};

  MidiNoteState copyWith({
    Set<int>? pressed,
    Set<int>? sustained,
    bool? isPedalDown,
  }) {
    return MidiNoteState(
      pressed: pressed ?? this.pressed,
      sustained: sustained ?? this.sustained,
      isPedalDown: isPedalDown ?? this.isPedalDown,
    );
  }

  static const _noteSetEquality = SetEquality<int>();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MidiNoteState &&
          runtimeType == other.runtimeType &&
          isPedalDown == other.isPedalDown &&
          _noteSetEquality.equals(pressed, other.pressed) &&
          _noteSetEquality.equals(sustained, other.sustained);

  @override
  int get hashCode => Object.hash(
    isPedalDown,
    _noteSetEquality.hash(pressed),
    _noteSetEquality.hash(sustained),
  );
}
