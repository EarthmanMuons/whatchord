import 'package:flutter/material.dart';

import 'app_color_schemes.dart';
import 'models/app_palette.dart';

ColorScheme colorSchemeFor(AppPalette palette, Brightness brightness) {
  return switch (palette) {
    AppPalette.neutral =>
      brightness == Brightness.dark
          ? NeutralSchemes.dark
          : NeutralSchemes.light,
    _ => ColorScheme.fromSeed(
      seedColor: palette.seedColor,
      brightness: brightness,
    ),
  };
}

ThemeData buildAppTheme({
  required AppPalette palette,
  required Brightness brightness,
}) {
  final cs = colorSchemeFor(palette, brightness);

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 2,
      showCloseIcon: true,
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: cs.inverseSurface,
      contentTextStyle: TextStyle(color: cs.onInverseSurface),
      actionTextColor: cs.inversePrimary,
      disabledActionTextColor: cs.onInverseSurface.withValues(alpha: 0.38),
      closeIconColor: cs.onInverseSurface,
    ),
  );
}
