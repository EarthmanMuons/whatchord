import 'package:flutter/material.dart';

@immutable
class PianoPalette {
  final Color background;
  final Color whiteKey;
  final Color pressedKeyHighlight;
  final Color blackKey;
  final Color border;

  const PianoPalette({
    required this.background,
    required this.whiteKey,
    required this.pressedKeyHighlight,
    required this.blackKey,
    required this.border,
  });
}

PianoPalette buildPianoPalette(ColorScheme cs) {
  final isDark = cs.brightness == Brightness.dark;

  final background = cs.surfaceContainerLow;

  final whiteKey = isDark
      ? Color.alphaBlend(cs.surface.withValues(alpha: 0.18), Colors.white)
      : Colors.white;

  final blackKey = const Color(0xFF111111);

  final pressedKeyHighlight = isDark
      ? Color.alphaBlend(whiteKey.withValues(alpha: 0.18), cs.primaryContainer)
      : Color.alphaBlend(whiteKey.withValues(alpha: 0.18), cs.primary);

  final border = Color.alphaBlend(
    Colors.black.withValues(alpha: isDark ? 0.30 : 0.22),
    whiteKey,
  );

  return PianoPalette(
    background: background,
    whiteKey: whiteKey,
    pressedKeyHighlight: pressedKeyHighlight,
    blackKey: blackKey,
    border: border,
  );
}
