import 'package:flutter/material.dart';

enum AppPalette { blue, green, indigo, purple }

extension AppPaletteProperties on AppPalette {
  String get label => switch (this) {
    AppPalette.blue => 'Blue',
    AppPalette.green => 'Green',
    AppPalette.indigo => 'Indigo',
    AppPalette.purple => 'Purple',
  };

  Color get seedColor => switch (this) {
    AppPalette.blue => Colors.blue,
    AppPalette.green => Colors.green,
    AppPalette.indigo => Colors.indigo,
    AppPalette.purple => Colors.purple,
  };
}
