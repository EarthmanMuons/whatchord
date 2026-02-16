import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:whatchord/core/core.dart';
import 'package:whatchord/features/audio/audio.dart';
import 'package:whatchord/features/home/home.dart';
import 'package:whatchord/features/midi/midi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Core app lifecycle hooks.
    ref.watch(appResumeWakeupProvider);
    ref.watch(appMidiLifecycleProvider);
    ref.watch(appAudioMonitorLifecycleProvider);

    final themeMode = ref.watch(appThemeModeProvider);
    final palette = ref.watch(appPaletteProvider);

    return MaterialApp(
      title: 'WhatChord',
      debugShowCheckedModeBanner: false,

      themeMode: themeMode,
      theme: buildAppTheme(palette: palette, brightness: Brightness.light),
      darkTheme: buildAppTheme(palette: palette, brightness: Brightness.dark),

      builder: (context, child) {
        return IdleBlackoutOverlay(child: child ?? const SizedBox.shrink());
      },
      home: const HomePage(),
    );
  }
}
