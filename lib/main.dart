import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final helloWorldProvider = Provider((_) => 'Hello world');

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'WhatChord',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(helloWorldProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Example')),
      body: SafeArea(
        child: Column(
          children: [
            AnalysisPlaceholder(text: value),
            const Divider(height: 1),
            const Expanded(child: KeyboardPlaceholder()),
          ],
        ),
      ),
    );
  }
}

class AnalysisPlaceholder extends StatelessWidget {
  final String text;

  const AnalysisPlaceholder({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}

class KeyboardPlaceholder extends StatelessWidget {
  const KeyboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Keyboard placeholder',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
