import 'package:flutter/material.dart';

@immutable
class PianoPalette {
  final Color background;
  final Color whiteKey;
  final Color pressedWhiteKey;
  final Color pressedBlackKey;
  final Color blackKey;
  final Color border;
  final Color pressedWhiteKeyBorder;
  final Color pressedWhiteKeySeparator;

  const PianoPalette({
    required this.background,
    required this.whiteKey,
    required this.pressedWhiteKey,
    required this.pressedBlackKey,
    required this.blackKey,
    required this.border,
    required this.pressedWhiteKeyBorder,
    required this.pressedWhiteKeySeparator,
  });
}

PianoPalette buildPianoPalette(ColorScheme cs) {
  final isDark = cs.brightness == Brightness.dark;

  final background = cs.surfaceContainerLow;

  final whiteKey = isDark
      ? Color.alphaBlend(cs.surface.withValues(alpha: 0.18), Colors.white)
      : Colors.white;

  final blackKey = const Color(0xFF111111);

  final border = Color.alphaBlend(
    Colors.black.withValues(alpha: isDark ? 0.30 : 0.22),
    whiteKey,
  );

  final pressedKeyAccent = isDark ? cs.primary : cs.inversePrimary;

  final pressedWhiteKey = Color.alphaBlend(
    pressedKeyAccent.withValues(alpha: isDark ? 0.42 : 0.54),
    whiteKey,
  );

  final pressedBlackKey = Color.alphaBlend(
    Colors.black.withValues(alpha: isDark ? 0.22 : 0.20),
    pressedKeyAccent,
  );

  final pressedWhiteKeyBorder = Color.alphaBlend(
    pressedKeyAccent.withValues(alpha: isDark ? 0.78 : 0.82),
    border,
  );

  final pressedWhiteKeySeparator = isDark
      ? border
      : Color.alphaBlend(Colors.black.withValues(alpha: 0.24), pressedWhiteKey);

  return PianoPalette(
    background: background,
    whiteKey: whiteKey,
    pressedWhiteKey: pressedWhiteKey,
    pressedBlackKey: pressedBlackKey,
    blackKey: blackKey,
    border: border,
    pressedWhiteKeyBorder: pressedWhiteKeyBorder,
    pressedWhiteKeySeparator: pressedWhiteKeySeparator,
  );
}
