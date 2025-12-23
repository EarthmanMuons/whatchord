import 'package:flutter/material.dart';
import 'src/piano_keyboard_painter.dart';

class PianoKeyboard extends StatelessWidget {
  const PianoKeyboard({
    super.key,
    required this.whiteKeyCount,
    this.startMidiNote = 48, // C3 by default (commonly convenient)
    this.activePitchClasses = const <int>{},
    this.height,
    this.borderRadius = 10.0,
    this.showNoteDebugLabels = false,
  }) : assert(whiteKeyCount > 0);

  /// Number of white keys to render (e.g., 14, 15, 21).
  final int whiteKeyCount;

  /// MIDI note number of the first *white* key at index 0.
  ///
  /// Practical guidance: keep this aligned to a white key pitch class
  /// (C, D, E, F, G, A, B) to avoid confusing ranges early.
  final int startMidiNote;

  /// Pitch classes (0..11) that should be highlighted as "active."
  /// This is intentionally stub-state for Phase 1.
  final Set<int> activePitchClasses;

  /// If provided, forces a fixed height. Otherwise it expands to constraints.
  final double? height;

  /// Rounded outer clip to make it look like a component.
  final double borderRadius;

  /// Optional: overlays small labels for white keys (debugging geometry/range).
  final bool showNoteDebugLabels;

  static const double _defaultHeight = 180.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final resolvedHeight = height ?? _defaultHeight;

    return SizedBox(
      height: resolvedHeight,
      width: double.infinity,
      child: CustomPaint(
        painter: PianoKeyboardPainter(
          whiteKeyCount: whiteKeyCount,
          startMidiNote: startMidiNote,
          activePitchClasses: activePitchClasses,
          whiteKeyColor: scheme.surface,
          whiteKeyActiveColor: scheme.primaryContainer,
          whiteKeyBorderColor: scheme.outlineVariant,
          blackKeyColor: scheme.onSurface,
          blackKeyActiveColor: scheme.primary,
          // Consider setting backgroundColor == whiteKeyColor for a seamless top edge,
          // or remove background painting entirely (see painter note below).
          backgroundColor: scheme.surface,
          showNoteDebugLabels: showNoteDebugLabels,
          debugLabelColor: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
