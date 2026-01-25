import 'package:flutter/material.dart';

@immutable
class PianoPalette {
  final Color background;
  final Color whiteKey;
  final Color whiteKeyActive;
  final Color blackKey;
  final Color blackKeyActive;
  final Color border;

  const PianoPalette({
    required this.background,
    required this.whiteKey,
    required this.whiteKeyActive,
    required this.blackKey,
    required this.blackKeyActive,
    required this.border,
  });
}

PianoPalette buildPianoPalette(ColorScheme cs) {
  final isDark = cs.brightness == Brightness.dark;

  final background = cs.surfaceContainerLow;

  Color overlayOn(Color base, Color overlay, double opacity) =>
      Color.alphaBlend(overlay.withValues(alpha: opacity), base);

  final whiteKey = isDark
      ? Color.alphaBlend(cs.surface.withValues(alpha: 0.18), Colors.white)
      : Colors.white;

  final primaryTooClose =
      (whiteKey.computeLuminance() - cs.primary.computeLuminance()).abs() <
      0.10;

  final pressedOverlay = (isDark && primaryTooClose)
      ? cs.primaryContainer
      : cs.primary;

  final whiteKeyActive = isDark
      ? overlayOn(whiteKey, pressedOverlay, 0.18)
      : cs.primaryContainer;

  final blackKey = const Color(0xFF111111);

  final blackKeyActive = isDark
      ? Color.alphaBlend(whiteKey.withValues(alpha: 0.18), cs.primaryContainer)
      : Color.alphaBlend(whiteKey.withValues(alpha: 0.18), cs.primary);

  final border = Color.alphaBlend(
    Colors.black.withValues(alpha: isDark ? 0.30 : 0.22),
    whiteKey,
  );

  return PianoPalette(
    background: background,
    whiteKey: whiteKey,
    whiteKeyActive: whiteKeyActive,
    blackKey: blackKey,
    blackKeyActive: blackKeyActive,
    border: border,
  );
}
