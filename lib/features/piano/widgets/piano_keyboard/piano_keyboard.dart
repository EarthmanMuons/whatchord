import 'package:flutter/material.dart';

import '../../models/piano_palette.dart';
import 'piano_keyboard_painter.dart';

class PianoKeyboard extends StatelessWidget {
  const PianoKeyboard({
    super.key,
    required this.whiteKeyCount,
    this.firstMidiNote = 48, // C3 by default
    this.activeMidiNotes = const <int>{},
    this.height,
    this.showNoteDebugLabels = false,
  }) : assert(whiteKeyCount > 0);

  /// Number of white keys to render (e.g., 14, 21).
  final int whiteKeyCount;

  /// MIDI note number of the first *white* key at index 0.
  final int firstMidiNote;

  /// Active *MIDI note numbers* (e.g., 60 for middle C).
  final Set<int> activeMidiNotes;

  /// If provided, forces a fixed height. Otherwise a default is used.
  final double? height;

  /// Optional debug labels (helpful while validating geometry).
  final bool showNoteDebugLabels;

  static const double _defaultHeight = 180.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = buildPianoPalette(scheme);
    final resolvedHeight = height ?? _defaultHeight;

    return SizedBox(
      height: resolvedHeight,
      width: double.infinity,
      child: CustomPaint(
        painter: PianoKeyboardPainter(
          whiteKeyCount: whiteKeyCount,
          firstMidiNote: firstMidiNote,
          activeMidiNotes: activeMidiNotes,

          whiteKeyColor: palette.whiteKey,
          whiteKeyActiveColor: palette.whiteKeyActive,
          whiteKeyBorderColor: palette.border,
          blackKeyColor: palette.blackKey,
          blackKeyActiveColor: palette.blackKeyActive,
          backgroundColor: palette.background,
          debugLabelColor: palette.debugLabel,

          showNoteDebugLabels: showNoteDebugLabels,

          drawBackground: true,
          drawFeltStrip: true,
        ),
      ),
    );
  }
}
