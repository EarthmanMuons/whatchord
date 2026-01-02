import 'package:flutter/material.dart';

ThemeData buildAppTheme({
  required Color seedColor,
  required Brightness brightness,
}) {
  final cs = ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);

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
