import 'package:flutter/foundation.dart';

enum InputPedalSource { midi, touch, demo }

/// Represents the current state of the sustain pedal from any input source.
///
/// Priority order: demo > touch > midi
/// When demo mode is active, demo source takes precedence.
/// When user taps the pedal indicator, touch source latches the state.
@immutable
class InputPedalState {
  final bool isDown;
  final InputPedalSource source;

  const InputPedalState({required this.isDown, required this.source});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InputPedalState &&
          runtimeType == other.runtimeType &&
          isDown == other.isDown &&
          source == other.source;

  @override
  int get hashCode => Object.hash(isDown, source);
}
