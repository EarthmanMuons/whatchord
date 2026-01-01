import 'package:flutter/foundation.dart';

@immutable
class ActiveNote {
  final int midiNote;
  final String label; // e.g., "C4", "F#5"
  final bool isSustained; // true if held by pedal, false if currently pressed

  const ActiveNote({
    required this.midiNote,
    required this.label,
    required this.isSustained,
  });

  /// Stable ID for AnimatedList diffing.
  String get id => 'note_$midiNote';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveNote &&
          runtimeType == other.runtimeType &&
          midiNote == other.midiNote &&
          label == other.label &&
          isSustained == other.isSustained;

  @override
  int get hashCode => Object.hash(midiNote, label, isSustained);
}
