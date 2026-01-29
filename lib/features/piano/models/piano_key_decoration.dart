import 'package:flutter/foundation.dart';

@immutable
class PianoKeyDecoration {
  /// MIDI note number of the key to decorate (typically a white key).
  final int midiNote;

  /// Short label, e.g. "C", "R", "3", etc.
  final String label;

  /// Extra distance to lift the decoration up from the bottom of the key.
  /// Useful to avoid bottom overlays (gesture nav indicator).
  final double bottomLift;

  const PianoKeyDecoration({
    required this.midiNote,
    required this.label,
    this.bottomLift = 0.0,
  });
}
