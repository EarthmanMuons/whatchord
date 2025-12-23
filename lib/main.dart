import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/piano/piano.dart';

@immutable
class WhatChordLayoutSpec {
  final bool isLandscape;

  // Keyboard
  final int whiteKeyCount;
  final double whiteKeyAspectRatio;
  final int startMidiNote;

  // Analysis
  final EdgeInsets analysisPadding;
  final double chordCardMaxWidth;
  final int topSpacerFlex;
  final int bottomSpacerFlex;

  // Right-side controls (landscape)
  final EdgeInsets controlPanePadding;

  // Chips
  final EdgeInsets noteChipsPadding;

  // Function bar
  final double functionBarHeight;

  const WhatChordLayoutSpec({
    required this.isLandscape,
    required this.whiteKeyCount,
    this.whiteKeyAspectRatio = 7.0,
    required this.startMidiNote,
    required this.analysisPadding,
    required this.chordCardMaxWidth,
    required this.topSpacerFlex,
    required this.bottomSpacerFlex,
    required this.controlPanePadding,
    required this.noteChipsPadding,
    required this.functionBarHeight,
  });

  static WhatChordLayoutSpec from(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isLandscape = mq.orientation == Orientation.landscape;

    if (isLandscape) {
      return const WhatChordLayoutSpec(
        isLandscape: true,

        // Full 88-key piano view: 52 white keys from A0 (MIDI 21) to C8.
        whiteKeyCount: 52,
        whiteKeyAspectRatio: 7.0,
        startMidiNote: 21, // A0
        analysisPadding: EdgeInsets.fromLTRB(16, 16, 8, 16),
        chordCardMaxWidth: 520,
        topSpacerFlex: 1,
        bottomSpacerFlex: 1,

        controlPanePadding: EdgeInsets.fromLTRB(8, 12, 16, 12),

        // In landscape, let the outer right-pane padding do the work
        // so the chips don't get double-padded.
        noteChipsPadding: EdgeInsets.zero,

        functionBarHeight: 56,
      );
    }

    return const WhatChordLayoutSpec(
      isLandscape: false,

      whiteKeyCount: 21,
      startMidiNote: 48, // C3

      analysisPadding: EdgeInsets.fromLTRB(16, 16, 16, 16),
      chordCardMaxWidth: 520,
      topSpacerFlex: 2,
      bottomSpacerFlex: 3,

      controlPanePadding: EdgeInsets.zero,

      noteChipsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),

      functionBarHeight: 56,
    );
  }
}

@immutable
class ChordAnalysis {
  final String chordName;
  final String? inversionLabel;

  const ChordAnalysis({required this.chordName, required this.inversionLabel});

  bool get hasInversion =>
      inversionLabel != null && inversionLabel!.trim().isNotEmpty;
}

final chordAnalysisProvider = Provider<ChordAnalysis>((ref) {
  return const ChordAnalysis(
    chordName: 'Cmaj / E',
    inversionLabel: '1st inversion',
  );
});

/// Stub data for UI layout work. Replace later with real MIDI input/provider output.
final activeMidiNotesProvider = Provider<Set<int>>((ref) {
  return <int>{64, 67, 72}; // E4 G4 C5
});

/// Derived note names for chips.
/// For Phase 1, this is a simple mapping from active MIDI notes -> pitch-class names.
/// TODO: Expand this for enharmonics, octave display, ordering rules, etc.
final noteNamesProvider = Provider<List<String>>((ref) {
  final activeMidi = ref.watch(activeMidiNotesProvider);
  final sorted = activeMidi.toList()..sort();
  return [for (final midi in sorted) _midiToNoteName(midi)];
});

String _midiToNoteName(int midiNote) {
  switch (midiNote % 12) {
    case 0:
      return 'C';
    case 1:
      return 'C#';
    case 2:
      return 'D';
    case 3:
      return 'D#';
    case 4:
      return 'E';
    case 5:
      return 'F';
    case 6:
      return 'F#';
    case 7:
      return 'G';
    case 8:
      return 'G#';
    case 9:
      return 'A';
    case 10:
      return 'A#';
    case 11:
      return 'B';
    default:
      return '?';
  }
}

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

void main() async {
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
    final cs = Theme.of(context).colorScheme;
    final spec = WhatChordLayoutSpec.from(context);

    return _SystemUiModeController(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('WhatChord'),
          backgroundColor: cs.surfaceContainerLow,
          foregroundColor: cs.onSurface,
          scrolledUnderElevation: 0,
          actions: [
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: spec.isLandscape
              ? _HomeLandscape(spec: spec)
              : _HomePortrait(spec: spec),
        ),
      ),
    );
  }
}

class _HomePortrait extends StatelessWidget {
  const _HomePortrait({required this.spec});

  final WhatChordLayoutSpec spec;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: AnalysisSection(spec: spec)),

        SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NoteChipsArea(spec: spec),
              KeyFunctionBarPlaceholder(height: spec.functionBarHeight),
              const Divider(height: 1),
              KeyboardSection(spec: spec),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeLandscape extends StatelessWidget {
  const _HomeLandscape({required this.spec});

  final WhatChordLayoutSpec spec;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top region: split between chord card (left) and note chips (right).
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 6, child: AnalysisSection(spec: spec)),

              Expanded(
                flex: 7,
                child: Padding(
                  padding: spec.controlPanePadding,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: NoteChipsArea(spec: spec),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom region: full-width function bar + keyboard.
        SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KeyFunctionBarPlaceholder(height: spec.functionBarHeight),
              const Divider(height: 1),
              KeyboardSection(spec: spec),
            ],
          ),
        ),
      ],
    );
  }
}

class _SystemUiModeController extends StatefulWidget {
  const _SystemUiModeController({required this.child});

  final Widget child;

  @override
  State<_SystemUiModeController> createState() =>
      _SystemUiModeControllerState();
}

class _SystemUiModeControllerState extends State<_SystemUiModeController>
    with WidgetsBindingObserver {
  Orientation? _lastOrientation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSystemUi();
  }

  void _updateSystemUi() {
    final orientation = MediaQuery.of(context).orientation;

    if (orientation == _lastOrientation) return;
    _lastOrientation = orientation;

    if (orientation == Orientation.landscape) {
      // Hide status bar (and other overlays) only in landscape.
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    } else {
      // Restore in portrait.
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    // Restore system UI when leaving the page.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: cs.surfaceContainerLow,
        foregroundColor: cs.onSurface,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        children: const [
          ListTile(
            title: Text('MIDI input'),
            subtitle: Text('Not configured'),
            trailing: Icon(Icons.chevron_right),
          ),
          Divider(height: 1),
          ListTile(
            title: Text('Keyboard behavior'),
            subtitle: Text('Scale/scroll (future)'),
            trailing: Icon(Icons.chevron_right),
          ),
          Divider(height: 1),
          ListTile(
            title: Text('Note naming'),
            subtitle: Text('Sharps/flats (future)'),
            trailing: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class AnalysisSection extends ConsumerWidget {
  const AnalysisSection({super.key, required this.spec});

  final WhatChordLayoutSpec spec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(chordAnalysisProvider);

    return Padding(
      padding: spec.analysisPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Spacer(flex: spec.topSpacerFlex),

          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: spec.chordCardMaxWidth),
              child: ChordIdentityCard(
                chordName: analysis.chordName,
                inversionLabel: analysis.inversionLabel,
              ),
            ),
          ),

          Spacer(flex: spec.bottomSpacerFlex),
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

    final minCardHeight = 124.0;
    final padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 18);

    return Card(
      elevation: 0,
      color: cs.primary,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minCardHeight),
        child: Padding(
          padding: padding,
          child: hasInversion
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      chordName,
                      textAlign: TextAlign.center,
                      style: chordStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 18),
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

class NoteChipsArea extends ConsumerWidget {
  const NoteChipsArea({super.key, required this.spec});

  final WhatChordLayoutSpec spec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteNames = ref.watch(noteNamesProvider);

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    const minHeight = 44.0;

    return Padding(
      padding: spec.noteChipsPadding,
      child: ConstrainedBox(
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
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.6),
                          ),
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
      ),
    );
  }
}

class KeyFunctionBarPlaceholder extends ConsumerWidget {
  const KeyFunctionBarPlaceholder({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final selectedKey = ref.watch(selectedKeyProvider);
    final active = ref.watch(activeFunctionProvider);

    return Material(
      color: cs.surfaceContainerLow,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (context) => _KeyPickerSheet(
                      selected: selectedKey,
                      onSelected: (key) {
                        ref.read(selectedKeyProvider.notifier).setKey(key);
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
                label: Text('Key: ${selectedKey.label}'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: HarmonicFunctionStrip(active: active),
                ),
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

class HarmonicFunctionStrip extends StatelessWidget {
  final HarmonicFunction? active;
  final values = HarmonicFunction.values;

  const HarmonicFunctionStrip({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < values.length; i++) ...[
            _HarmonicFunctionIndicator(
              label: values[i].label,
              isActive: values[i] == active,
            ),
            if (i < values.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _HarmonicFunctionIndicator extends StatelessWidget {
  final String label;
  final bool isActive;

  const _HarmonicFunctionIndicator({
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final baseStyle = theme.textTheme.labelLarge;
    final textStyle = baseStyle?.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) + 2,
      color: isActive
          ? cs.primary
          : cs.onSurfaceVariant.withValues(alpha: 0.65),
      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
    );

    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(label, style: textStyle),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: 3,
                width: 18,
                decoration: BoxDecoration(
                  color: isActive ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KeyboardSection extends ConsumerWidget {
  const KeyboardSection({super.key, required this.spec});

  final WhatChordLayoutSpec spec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeMidiNotesProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final whiteKeyWidth = width / spec.whiteKeyCount;

        var height = whiteKeyWidth * spec.whiteKeyAspectRatio;

        // Guardrails to prevent extremes.
        height = height.clamp(90.0, 200.0);

        return PianoKeyboard(
          whiteKeyCount: spec.whiteKeyCount,
          startMidiNote: spec.startMidiNote,
          activeMidiNotes: active,
          height: height,
        );
      },
    );
  }
}
