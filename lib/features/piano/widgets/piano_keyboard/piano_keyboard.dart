import 'package:flutter/material.dart';

import '../../models/piano_key_decoration.dart';
import '../../models/piano_palette.dart';
import 'piano_keyboard_painter.dart';

class PianoKeyboard extends StatelessWidget {
  const PianoKeyboard({
    super.key,
    required this.whiteKeyCount,
    this.firstMidiNote = 48, // C3 by default
    this.soundingMidiNotes = const <int>{},
    this.height,
    this.decorations = const <PianoKeyDecoration>[],
  }) : assert(whiteKeyCount > 0);

  /// Number of white keys to render (e.g., 14, 21, 52).
  final int whiteKeyCount;

  /// MIDI note number of the first *white* key at index 0.
  final int firstMidiNote;

  /// Sounding *MIDI note numbers* (e.g., 60 for middle C).
  final Set<int> soundingMidiNotes;

  /// If provided, forces a fixed height. Otherwise a default is used.
  final double? height;

  /// Key decorations (e.g., middle C, scale markers).
  final List<PianoKeyDecoration> decorations;

  static const double _defaultHeight = 180.0;

  @override
  Widget build(BuildContext context) {
    final palette = buildPianoPalette(Theme.of(context).colorScheme);
    final resolvedHeight = height ?? _defaultHeight;

    final whiteLum = palette.whiteKey.computeLuminance();

    // If the key fill is light, use a dark label; otherwise use a light label.
    final landmarkColor = whiteLum > 0.55
        ? Colors.black.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.80);

    return SizedBox(
      height: resolvedHeight,
      width: double.infinity,
      child: CustomPaint(
        painter: PianoKeyboardPainter(
          whiteKeyCount: whiteKeyCount,
          firstMidiNote: firstMidiNote,
          soundingMidiNotes: soundingMidiNotes,

          whiteKeyColor: palette.whiteKey,
          whiteKeyActiveColor: palette.whiteKeyActive,
          whiteKeyBorderColor: palette.border,
          blackKeyColor: palette.blackKey,
          blackKeyActiveColor: palette.blackKeyActive,
          backgroundColor: palette.background,

          decorations: decorations,
          decorationTextColor: landmarkColor,

          drawBackground: true,
          drawFeltStrip: true,
        ),
      ),
    );
  }
}
