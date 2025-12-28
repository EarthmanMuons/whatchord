import 'package:flutter/material.dart';
import 'src/piano_keyboard_painter.dart';

@immutable
class PianoPalette {
  final Color background;
  final Color whiteKey;
  final Color whiteKeyActive;
  final Color blackKey;
  final Color blackKeyActive;
  final Color border;
  final Color debugLabel;

  const PianoPalette({
    required this.background,
    required this.whiteKey,
    required this.whiteKeyActive,
    required this.blackKey,
    required this.blackKeyActive,
    required this.border,
    required this.debugLabel,
  });
}

Color darken(Color color, double amount) {
  assert(amount >= 0 && amount <= 1);
  final hsl = HSLColor.fromColor(color);
  final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
  return darkened.toColor();
}

PianoPalette pianoPaletteFor(ColorScheme cs) {
  final isDark = cs.brightness == Brightness.dark;

  final background = cs.surfaceContainerLow;

  final whiteKey = isDark
      ? Color.alphaBlend(cs.surface.withValues(alpha: 0.18), Colors.white)
      : Colors.white;

  final blackKey = const Color(0xFF111111);

  // Material-consistent active colors
  final whiteKeyActive = isDark
      ? Color.alphaBlend(whiteKey.withValues(alpha: 0.18), cs.primary)
      : cs.primaryContainer;

  final blackKeyActive = isDark
      ? Color.alphaBlend(whiteKey.withValues(alpha: 0.18), cs.primaryContainer)
      : Color.alphaBlend(whiteKey.withValues(alpha: 0.18), cs.primary);

  final border = Color.alphaBlend(
    Colors.black.withValues(alpha: isDark ? 0.30 : 0.22),
    whiteKey,
  );

  final debugLabel = cs.onSurface.withValues(alpha: isDark ? 0.55 : 0.45);

  return PianoPalette(
    background: background,
    whiteKey: whiteKey,
    whiteKeyActive: whiteKeyActive,
    blackKey: blackKey,
    blackKeyActive: blackKeyActive,
    border: border,
    debugLabel: debugLabel,
  );
}

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
    final palette = pianoPaletteFor(scheme);
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
