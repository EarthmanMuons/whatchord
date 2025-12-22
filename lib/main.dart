import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final helloWorldProvider = Provider((_) => 'Hello world');

@immutable
class MusicalKey {
  final String label;

  const MusicalKey._(this.label);

  static const c = MusicalKey._('C');
  static const g = MusicalKey._('G');
  static const d = MusicalKey._('D');
  static const a = MusicalKey._('A');
  static const e = MusicalKey._('E');

  static const values = <MusicalKey>[c, g, d, a, e];

  @override
  String toString() => label;
}

final selectedKeyProvider = NotifierProvider<SelectedKeyNotifier, MusicalKey>(
  SelectedKeyNotifier.new,
);

class SelectedKeyNotifier extends Notifier<MusicalKey> {
  @override
  MusicalKey build() => MusicalKey.c;

  void setKey(MusicalKey key) => state = key;
}

void main() {
  runApp(const ProviderScope(child: MyApp()));
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
      home: const HomePage(),
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

class KeyFunctionBarPlaceholder extends ConsumerWidget {
  const KeyFunctionBarPlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final selectedKey = ref.watch(selectedKeyProvider);

    return Material(
      color: cs.surfaceContainerLow,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Left: tap to pick key
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (context) {
                      return _KeyPickerSheet(
                        selected: selectedKey,
                        onSelected: (key) {
                          ref.read(selectedKeyProvider.notifier).setKey(key);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  child: Text(
                    'Key: ${selectedKey.label}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),

              const Spacer(),

              // Right: placeholder for roman numeral/function display
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

class _KeyPickerSheet extends StatelessWidget {
  final MusicalKey selected;
  final ValueChanged<MusicalKey> onSelected;

  const _KeyPickerSheet({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final key in MusicalKey.values)
            ListTile(
              title: Text(key.label),
              trailing: key == selected ? const Icon(Icons.check) : null,
              onTap: () => onSelected(key),
            ),
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
