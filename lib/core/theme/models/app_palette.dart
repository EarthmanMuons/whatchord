import 'package:flutter/material.dart';

enum AppPalette { blue, green, indigo, purple }

extension AppPaletteMeta on AppPalette {
  ({String label, Color seedColor}) get meta => switch (this) {
    AppPalette.blue => (label: 'Blue', seedColor: Colors.blue),
    AppPalette.green => (label: 'Green', seedColor: Colors.green),
    AppPalette.indigo => (label: 'Indigo', seedColor: Colors.indigo),
    AppPalette.purple => (label: 'Purple', seedColor: Colors.purple),
  };

  String get label => meta.label;
  Color get seedColor => meta.seedColor;
}
