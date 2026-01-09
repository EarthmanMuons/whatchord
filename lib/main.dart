import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/activity/app_resume_wakeup_provider.dart';
import 'core/activity/idle_blackout_overlay.dart';
import 'core/persistence/shared_preferences_provider.dart';
import 'core/theme/theme.dart';
import 'features/home/home.dart';

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
    ref.watch(appResumeWakeupProvider);

    final themeMode = ref.watch(themeModeProvider);
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
