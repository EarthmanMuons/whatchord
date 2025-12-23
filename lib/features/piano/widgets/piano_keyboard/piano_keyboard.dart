import 'package:flutter/material.dart';
import 'src/piano_keyboard_painter.dart';

class PianoKeyboard extends StatelessWidget {
  const PianoKeyboard({
    super.key,
    required this.whiteKeyCount,
    this.startMidiNote = 48, // C3 by default
    this.activeMidiNotes = const <int>{},
    this.height,
    this.showNoteDebugLabels = false,
  }) : assert(whiteKeyCount > 0);

  /// Number of white keys to render (e.g., 14, 21).
  final int whiteKeyCount;

  /// MIDI note number of the first *white* key at index 0.
  final int startMidiNote;

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
    final resolvedHeight = height ?? _defaultHeight;

    return SizedBox(
      height: resolvedHeight,
      width: double.infinity,
      child: CustomPaint(
        painter: PianoKeyboardPainter(
          whiteKeyCount: whiteKeyCount,
          startMidiNote: startMidiNote,
          activeMidiNotes: activeMidiNotes,
          whiteKeyColor: scheme.surface,
          whiteKeyActiveColor: scheme.primaryContainer,
          whiteKeyBorderColor: scheme.outlineVariant,
          blackKeyColor: scheme.onSurface,
          blackKeyActiveColor: scheme.primary,
          backgroundColor: scheme.surface,
          showNoteDebugLabels: showNoteDebugLabels,
          debugLabelColor: scheme.onSurfaceVariant,
          // Optional: tweak these later if you expose them at widget level.
          drawBackground: true,
          drawFeltStrip: true,
        ),
      ),
    );
  }
}
