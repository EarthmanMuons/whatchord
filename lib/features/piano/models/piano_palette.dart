import 'package:flutter/material.dart';

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
