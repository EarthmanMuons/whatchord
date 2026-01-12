import 'package:flutter/foundation.dart';

@immutable
class PianoKeyDecoration {
  /// MIDI note number of the key to decorate (typically a white key).
  final int midiNote;

  /// Short label, e.g. "C", "R", "3", etc.
  final String label;

  const PianoKeyDecoration({required this.midiNote, required this.label});
}
