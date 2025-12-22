import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class ChordAnalysis {
  final String chordName;
  final String? inversionLabel;
  final List<String> noteNames;

  const ChordAnalysis({
    required this.chordName,
    required this.inversionLabel,
    required this.noteNames,
  });

  bool get hasNotes => noteNames.isNotEmpty;

  bool get hasInversion =>
      inversionLabel != null && inversionLabel!.trim().isNotEmpty;
}

final chordAnalysisProvider = Provider<ChordAnalysis>((ref) {
  // Stub data for UI layout work. Replace later with real analysis.
  // "Idle" state example:
  // return const ChordAnalysis(
  //   chordName: '— — —',
  //   inversionLabel: null,
  //   noteNames: [],
  // );

  // "Active" state example:
  return const ChordAnalysis(
    chordName: 'C maj7 / E',
    inversionLabel: '1st inversion',
    noteNames: ['E', 'G', 'B', 'C'],
  );
});

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

enum HarmonicFunction {
  one('I'),
  two('ii'),
  three('iii'),
  four('IV'),
  five('V'),
  six('vi'),
  seven('vii°');

  final String label;
  const HarmonicFunction(this.label);
}

final activeFunctionProvider = Provider<HarmonicFunction?>((ref) {
  final key = ref.watch(selectedKeyProvider);
  final analysis = ref.watch(chordAnalysisProvider);

  // Stub logic
  if (analysis.chordName.startsWith(key.label)) {
    return HarmonicFunction.one;
  }
  return null;
});

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
    return Scaffold(
      appBar: AppBar(title: const Text('Example')),
      body: SafeArea(
        child: Column(
          children: [
            const AnalysisSection(),
            const KeyFunctionBarPlaceholder(),
            const Divider(height: 1),
            const Expanded(child: KeyboardPlaceholder()),
          ],
        ),
      ),
    );
  }
}

class AnalysisSection extends ConsumerWidget {
  const AnalysisSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(chordAnalysisProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ChordIdentityCard(
                  chordName: analysis.chordName,
                  inversionLabel: analysis.inversionLabel,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NoteChipsArea(noteNames: analysis.noteNames),
          ),
        ],
      ),
    );
  }
}

class ChordIdentityCard extends StatelessWidget {
  final String chordName;
  final String? inversionLabel;

  const ChordIdentityCard({
    super.key,
    required this.chordName,
    required this.inversionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final hasInversion =
        inversionLabel != null && inversionLabel!.trim().isNotEmpty;

    final chordStyle = theme.textTheme.displayMedium!.copyWith(
      color: cs.onPrimary,
      fontWeight: FontWeight.w600,
      height: 1.0,
    );

    final inversionStyle = theme.textTheme.titleMedium!.copyWith(
      color: cs.onPrimary.withValues(alpha: 0.85),
      height: 1.1,
    );

    const minCardHeight = 124.0;

    return Card(
      elevation: 0,
      color: cs.primary,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minCardHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          child: hasInversion
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      chordName,
                      textAlign: TextAlign.center,
                      style: chordStyle,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      inversionLabel!,
                      textAlign: TextAlign.center,
                      style: inversionStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
              : Center(
                  child: Text(
                    chordName,
                    textAlign: TextAlign.center,
                    style: chordStyle,
                  ),
                ),
        ),
      ),
    );
  }
}

class NoteChipsArea extends StatelessWidget {
  final List<String> noteNames;

  const NoteChipsArea({super.key, required this.noteNames});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Reserve roughly one row worth of vertical space (prevents the keyboard from jumping).
    const minHeight = 44.0;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: minHeight),
      child: noteNames.isEmpty
          ? Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Play notes…',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            )
          : Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final note in noteNames)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(note, style: theme.textTheme.titleMedium),
                      ),
                    ),
                ],
              ),
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
    final active = ref.watch(activeFunctionProvider);

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
              RomanNumeralsDisplay(active: active),
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

class RomanNumeralsDisplay extends StatelessWidget {
  final HarmonicFunction? active;

  const RomanNumeralsDisplay({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Wrap(
      spacing: 10,
      children: [
        for (final fn in HarmonicFunction.values)
          _HarmonicFunctionPill(
            label: fn.label,
            isActive: fn == active,
            theme: theme,
            cs: cs,
          ),
      ],
    );
  }
}

class _HarmonicFunctionPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final ThemeData theme;
  final ColorScheme cs;

  const _HarmonicFunctionPill({
    required this.label,
    required this.isActive,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      color: isActive ? cs.onPrimaryContainer : cs.onSurfaceVariant,
      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? cs.primaryContainer : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isActive ? cs.primary : cs.outlineVariant),
      ),
      child: Text(label, style: textStyle),
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
