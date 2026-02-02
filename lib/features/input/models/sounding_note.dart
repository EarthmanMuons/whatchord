import 'package:flutter/foundation.dart';

@immutable
class SoundingNote {
  final int noteNumber;
  final String label; // Display label (e.g., "C", "F#", "Bb").
  final bool isSustained; // true if held by pedal, false if currently pressed

  const SoundingNote({
    required this.noteNumber,
    required this.label,
    required this.isSustained,
  });

  /// Stable ID for AnimatedList diffing.
  String get id => 'note_$noteNumber';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SoundingNote &&
          runtimeType == other.runtimeType &&
          noteNumber == other.noteNumber &&
          label == other.label &&
          isSustained == other.isSustained;

  @override
  int get hashCode => Object.hash(noteNumber, label, isSustained);
}
