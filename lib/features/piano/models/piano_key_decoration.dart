import 'package:flutter/foundation.dart';

enum PianoKeyDecorationStyle { label, topCap }

@immutable
class PianoKeyDecoration {
  /// MIDI note number of the key to decorate.
  final int midiNote;

  /// Decoration style rendered on the key surface.
  final PianoKeyDecorationStyle style;

  /// Short label, e.g. "C", "R", "3", etc. Only used for [style] = label.
  final String? label;

  /// Extra distance to lift the decoration up from the bottom of the key.
  /// Useful to avoid bottom overlays (gesture nav indicator).
  final double bottomLift;

  const PianoKeyDecoration({
    required this.midiNote,
    this.style = PianoKeyDecorationStyle.label,
    this.label,
    this.bottomLift = 0.0,
  }) : assert(
         style != PianoKeyDecorationStyle.label ||
             (label != null && label != ''),
         'label decorations require a non-empty label',
       );

  const PianoKeyDecoration.topCap({required int midiNote})
    : this(midiNote: midiNote, style: PianoKeyDecorationStyle.topCap);
}
