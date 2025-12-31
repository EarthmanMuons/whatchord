import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_palette.dart';

class AppPaletteNotifier extends Notifier<AppPalette> {
  @override
  AppPalette build() => AppPalette.indigo;
  void setPalette(AppPalette v) => state = v;
}

final appPaletteProvider = NotifierProvider<AppPaletteNotifier, AppPalette>(
  AppPaletteNotifier.new,
);

final seedColorProvider = Provider<Color>((ref) {
  return ref.watch(appPaletteProvider).seedColor;
});
