import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme.dart';
import 'features/home/home.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seedColor = ref.watch(seedColorProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'WhatChord',
      debugShowCheckedModeBanner: false,

      theme: buildAppTheme(seedColor: seedColor, brightness: Brightness.light),
      darkTheme: buildAppTheme(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      themeMode: themeMode,

      home: const HomePage(),
    );
  }
}
