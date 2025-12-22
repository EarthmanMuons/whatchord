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
            const KeyFunctionBarPlaceholder(),
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

class KeyFunctionBarPlaceholder extends StatelessWidget {
  const KeyFunctionBarPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerLow,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (context) {
                      return const _KeyPickerSheetPlaceholder();
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  child: Text(
                    'Key: C',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),

              const Spacer(),

              Text(
                'I  ii  iii  IV  V  vi  vii°',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyPickerSheetPlaceholder extends StatelessWidget {
  const _KeyPickerSheetPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: const [
          ListTile(title: Text('C')),
          ListTile(title: Text('G')),
          ListTile(title: Text('D')),
          ListTile(title: Text('A')),
          ListTile(title: Text('E')),
        ],
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
