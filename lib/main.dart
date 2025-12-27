import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'features/piano/piano.dart';

enum MidiConnectionStatus { disconnected, connecting, connected, error }

@immutable
class MidiConnectionState {
  final MidiConnectionStatus status;

  /// Optional details (e.g., last error, device name, etc.)
  final String? message;

  const MidiConnectionState({required this.status, this.message});

  bool get isConnected => status == MidiConnectionStatus.connected;

  MidiConnectionState copyWith({
    MidiConnectionStatus? status,
    String? message,
  }) {
    return MidiConnectionState(
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}

@immutable
class MidiHoldState {
  final Set<int> pressed; // keys physically down
  final Set<int> sustained; // released while pedal is down
  final bool sustainDown;

  const MidiHoldState({
    required this.pressed,
    required this.sustained,
    required this.sustainDown,
  });

  Set<int> get activeNotes => {...pressed, ...sustained};

  MidiHoldState copyWith({
    Set<int>? pressed,
    Set<int>? sustained,
    bool? sustainDown,
  }) {
    return MidiHoldState(
      pressed: pressed ?? this.pressed,
      sustained: sustained ?? this.sustained,
      sustainDown: sustainDown ?? this.sustainDown,
    );
  }
}

enum AppPalette { blue, green, indigo, purple }

extension AppPaletteLabel on AppPalette {
  String get label => switch (this) {
    AppPalette.blue => 'Blue',
    AppPalette.green => 'Green',
    AppPalette.indigo => 'Indigo',
    AppPalette.purple => 'Purple',
  };
}

extension AppPaletteSeed on AppPalette {
  Color get seedColor => switch (this) {
    AppPalette.blue => Colors.blue,
    AppPalette.green => Colors.green,
    AppPalette.indigo => Colors.indigo,
    AppPalette.purple => Colors.purple,
  };
}

enum ChordNotation { standard, jazz }

@immutable
class ChordNameParts {
  final String root; // e.g., "C", "F#", "Bb"
  final String remainder; // e.g., "maj", "m7(b5)", "sus4", "" (optional)
  final String? slashBass; // e.g., "E" in "Cmaj / E" (no leading " / ")

  const ChordNameParts({
    required this.root,
    this.remainder = '',
    this.slashBass,
  });

  bool get hasSlash => slashBass != null && slashBass!.trim().isNotEmpty;

  String toDisplayString() {
    final base = '$root$remainder';
    return hasSlash ? '$base / ${slashBass!}' : base;
  }
}

@immutable
class ChordAnalysis {
  final ChordNameParts chordName;
  final String? inversionLabel;

  const ChordAnalysis({required this.chordName, required this.inversionLabel});

  bool get hasInversion =>
      inversionLabel != null && inversionLabel!.trim().isNotEmpty;
}

enum NoteChipKind { sustainIndicator, note }

enum NoteChipHold { pressed, sustained }

@immutable
class NoteChipModel {
  final String id; // stable identity for diff/animations
  final NoteChipKind kind;
  final String label; // note name or empty for sustain
  final NoteChipHold? hold; // null for sustain indicator

  const NoteChipModel._({
    required this.id,
    required this.kind,
    required this.label,
    required this.hold,
  });

  const NoteChipModel.sustain()
    : this._(
        id: 'sustain',
        kind: NoteChipKind.sustainIndicator,
        label: '',
        hold: null,
      );

  factory NoteChipModel.note({
    required int midiNote,
    required String label,
    required NoteChipHold hold,
  }) {
    return NoteChipModel._(
      id: 'note_$midiNote',
      kind: NoteChipKind.note,
      label: label,
      hold: hold,
    );
  }
}

enum KeyMode { major, minor }

@immutable
class MusicalKey {
  final String tonic; // e.g. "C", "F#", "Bb"
  final KeyMode mode;

  const MusicalKey(this.tonic, this.mode);

  bool get isMajor => mode == KeyMode.major;
  bool get isMinor => mode == KeyMode.minor;

  String get label => isMajor ? tonic : tonic.toLowerCase();

  String get longLabel => isMajor ? '$tonic major' : '$tonic minor';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MusicalKey &&
          runtimeType == other.runtimeType &&
          tonic == other.tonic &&
          mode == other.mode;

  @override
  int get hashCode => Object.hash(tonic, mode);

  @override
  String toString() => longLabel;
}

final selectedKeyProvider = NotifierProvider<SelectedKeyNotifier, MusicalKey>(
  SelectedKeyNotifier.new,
);

class SelectedKeyNotifier extends Notifier<MusicalKey> {
  @override
  MusicalKey build() => const MusicalKey('C', KeyMode.major);

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

@immutable
class KeySignatureRow {
  /// Negative = flats, positive = sharps. e.g. -2 means 2 flats, +3 means 3 sharps.
  final int accidentals;

  final MusicalKey relativeMajor;
  final MusicalKey relativeMinor;

  const KeySignatureRow({
    required this.accidentals,
    required this.relativeMajor,
    required this.relativeMinor,
  });

  String get signatureLabel {
    if (accidentals == 0) return 'no sharps/flats';
    final n = accidentals.abs();
    final word = n == 1 ? '1' : '$n';
    return accidentals > 0
        ? '$word sharp${n == 1 ? '' : 's'}'
        : '$word flat${n == 1 ? '' : 's'}';
  }
}

/// Circle-of-fifths-ish ordering that also includes the “full” 15 signatures:
/// 7 flats ... 0 ... 7 sharps
const keySignatureRows = <KeySignatureRow>[
  KeySignatureRow(
    accidentals: -7,
    relativeMajor: MusicalKey('C♭', KeyMode.major),
    relativeMinor: MusicalKey('A♭', KeyMode.minor),
  ),
  KeySignatureRow(
    accidentals: -6,
    relativeMajor: MusicalKey('G♭', KeyMode.major),
    relativeMinor: MusicalKey('E♭', KeyMode.minor),
  ),
  KeySignatureRow(
    accidentals: -5,
    relativeMajor: MusicalKey('D♭', KeyMode.major),
    relativeMinor: MusicalKey('B♭', KeyMode.minor),
  ),
  KeySignatureRow(
    accidentals: -4,
    relativeMajor: MusicalKey('A♭', KeyMode.major),
    relativeMinor: MusicalKey('F', KeyMode.minor),
  ),
  KeySignatureRow(
    accidentals: -3,
    relativeMajor: MusicalKey('E♭', KeyMode.major),
    relativeMinor: MusicalKey('C', KeyMode.minor),
  ),
  KeySignatureRow(
    accidentals: -2,
    relativeMajor: MusicalKey('B♭', KeyMode.major),
    relativeMinor: MusicalKey('G', KeyMode.minor),
  ),
  KeySignatureRow(
    accidentals: -1,
    relativeMajor: MusicalKey('F', KeyMode.major),
    relativeMinor: MusicalKey('D', KeyMode.minor),
  ),
  KeySignatureRow(
    accidentals: 0,
    relativeMajor: MusicalKey('C', KeyMode.major),
    relativeMinor: MusicalKey('A', KeyMode.minor),
  ),
  KeySignatureRow(
    accidentals: 1,
    relativeMajor: MusicalKey('G', KeyMode.major),
    relativeMinor: MusicalKey('E', KeyMode.minor),
  ),
  KeySignatureRow(
    accidentals: 2,
    relativeMajor: MusicalKey('D', KeyMode.major),
    relativeMinor: MusicalKey('B', KeyMode.minor),
  ),
  KeySignatureRow(
    accidentals: 3,
    relativeMajor: MusicalKey('A', KeyMode.major),
    relativeMinor: MusicalKey('F♯', KeyMode.minor),
  ),
  KeySignatureRow(
    accidentals: 4,
    relativeMajor: MusicalKey('E', KeyMode.major),
    relativeMinor: MusicalKey('C♯', KeyMode.minor),
  ),
  KeySignatureRow(
    accidentals: 5,
    relativeMajor: MusicalKey('B', KeyMode.major),
    relativeMinor: MusicalKey('G♯', KeyMode.minor),
  ),
  KeySignatureRow(
    accidentals: 6,
    relativeMajor: MusicalKey('F♯', KeyMode.major),
    relativeMinor: MusicalKey('D♯', KeyMode.minor),
  ),
  KeySignatureRow(
    accidentals: 7,
    relativeMajor: MusicalKey('C♯', KeyMode.major),
    relativeMinor: MusicalKey('A♯', KeyMode.minor),
  ),
];

final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;
  void setThemeMode(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ChordNotationNotifier extends Notifier<ChordNotation> {
  @override
  ChordNotation build() => ChordNotation.standard;
  void setNotation(ChordNotation v) => state = v;
}

final chordNotationProvider =
    NotifierProvider<ChordNotationNotifier, ChordNotation>(
      ChordNotationNotifier.new,
    );

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

@immutable
class WhatChordLayoutSpec {
  // Keyboard
  final int whiteKeyCount;
  final double whiteKeyAspectRatio;
  final int startMidiNote;

  // Analysis
  final EdgeInsets analysisPadding;
  final double chordCardMaxWidth;

  // Right-side controls (landscape)
  final EdgeInsets controlPanePadding;

  // Chips
  final EdgeInsets noteChipsPadding;

  // Function bar
  final double functionBarHeight;

  const WhatChordLayoutSpec({
    required this.whiteKeyCount,
    this.whiteKeyAspectRatio = 7.0,
    required this.startMidiNote,
    required this.analysisPadding,
    required this.chordCardMaxWidth,
    required this.controlPanePadding,
    required this.noteChipsPadding,
    required this.functionBarHeight,
  });
}

const portraitSpec = WhatChordLayoutSpec(
  whiteKeyCount: 21,
  whiteKeyAspectRatio: 7.0,
  startMidiNote: 48, // C3
  analysisPadding: EdgeInsets.fromLTRB(16, 16, 16, 16),
  chordCardMaxWidth: 520,
  controlPanePadding: EdgeInsets.zero,
  noteChipsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  functionBarHeight: 56,
);

const landscapeSpec = WhatChordLayoutSpec(
  // Full 88-key view: 52 white keys from A0 (MIDI 21) to C8.
  whiteKeyCount: 52,
  whiteKeyAspectRatio: 7.0,
  startMidiNote: 21, // A0
  analysisPadding: EdgeInsets.fromLTRB(16, 16, 8, 16),
  chordCardMaxWidth: 520,
  controlPanePadding: EdgeInsets.fromLTRB(8, 12, 16, 12),
  noteChipsPadding: EdgeInsets.zero,
  functionBarHeight: 56,
);

final layoutSpecProvider = Provider<WhatChordLayoutSpec>((ref) {
  throw StateError('layoutSpecProvider must be overridden in HomePage');
});

final midiConnectionProvider =
    NotifierProvider<MidiConnectionNotifier, MidiConnectionState>(
      MidiConnectionNotifier.new,
    );

class MidiConnectionNotifier extends Notifier<MidiConnectionState> {
  @override
  MidiConnectionState build() {
    // Stub default. Replace with persisted/bootstrapped status later.
    return const MidiConnectionState(status: MidiConnectionStatus.connected);
  }

  /// Call this when your MIDI layer reports a new connection state.
  void setStatus(MidiConnectionStatus status, {String? message}) {
    state = state.copyWith(status: status, message: message);
  }

  /// Optional helpers for later (or for quick UI testing).
  void markConnecting() => setStatus(MidiConnectionStatus.connecting);
  void markConnected({String? deviceName}) =>
      setStatus(MidiConnectionStatus.connected, message: deviceName);
  void markDisconnected() => setStatus(MidiConnectionStatus.disconnected);
  void markError(String message) =>
      setStatus(MidiConnectionStatus.error, message: message);
}

final midiHoldProvider = NotifierProvider<MidiHoldNotifier, MidiHoldState>(
  MidiHoldNotifier.new,
);

class MidiHoldNotifier extends Notifier<MidiHoldState> {
  @override
  MidiHoldState build() {
    // Stub defaults for UI testing; replace as you wire in real MIDI.
    return MidiHoldState(
      pressed: <int>{64, 67, 72}, // E4 G4 C5
      sustained: <int>{64},
      sustainDown: true,
    );
  }

  // Call from MIDI Note On
  void noteOn(int midiNote) {
    final nextPressed = {...state.pressed, midiNote};

    // If a sustained note is re-pressed, it should no longer be “sustained”.
    final nextSustained = {...state.sustained}..remove(midiNote);

    state = state.copyWith(pressed: nextPressed, sustained: nextSustained);
  }

  // Call from MIDI Note Off
  void noteOff(int midiNote) {
    if (!state.pressed.contains(midiNote)) return;

    final nextPressed = {...state.pressed}..remove(midiNote);

    if (state.sustainDown) {
      final nextSustained = {...state.sustained, midiNote};
      state = state.copyWith(pressed: nextPressed, sustained: nextSustained);
    } else {
      state = state.copyWith(pressed: nextPressed);
    }
  }

  // Call from MIDI CC64 (sustain)
  // Conventional threshold: >= 64 is down, < 64 is up.
  void setSustainDown(bool down) {
    if (down == state.sustainDown) return;

    if (!down) {
      // Pedal released: all pedal-held notes stop sounding.
      state = state.copyWith(sustainDown: false, sustained: <int>{});
    } else {
      state = state.copyWith(sustainDown: true);
    }
  }

  // Convenience for CC64 values.
  void handleSustainValue(int value) => setSustainDown(value >= 64);
}

/// Stub data for UI layout work. Replace later with real MIDI input/provider output.
final activeMidiNotesProvider = Provider<Set<int>>((ref) {
  return ref.watch(midiHoldProvider.select((s) => s.activeNotes));
});

final chordAnalysisProvider = Provider<ChordAnalysis>((ref) {
  return const ChordAnalysis(
    chordName: ChordNameParts(root: 'C', remainder: 'maj', slashBass: 'E'),
    inversionLabel: '1st inversion',
  );
});

final activeFunctionProvider = Provider<HarmonicFunction?>((ref) {
  final key = ref.watch(selectedKeyProvider);
  final analysis = ref.watch(chordAnalysisProvider);

  // Stub logic
  if (analysis.chordName.toDisplayString().startsWith(key.label)) {
    return HarmonicFunction.one;
  }
  return null;
});

final noteChipModelsProvider = Provider<List<NoteChipModel>>((ref) {
  final hold = ref.watch(midiHoldProvider);

  final models = <NoteChipModel>[];
  if (hold.sustainDown) {
    models.add(const NoteChipModel.sustain());
  }

  final activeSorted = hold.activeNotes.toList()..sort();
  for (final midi in activeSorted) {
    final isPressed = hold.pressed.contains(midi);
    models.add(
      NoteChipModel.note(
        midiNote: midi,
        label: _midiToNoteName(midi),
        hold: isPressed ? NoteChipHold.pressed : NoteChipHold.sustained,
      ),
    );
  }

  return models;
});

void main() async {
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

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeMode,

      home: const HomePage(),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final spec = isLandscape ? landscapeSpec : portraitSpec;

        final mq = MediaQuery.of(context);
        final mqFullWidth = isLandscape
            ? mq.copyWith(
                padding: mq.padding.copyWith(left: 0, right: 0),
                viewPadding: mq.viewPadding.copyWith(left: 0, right: 0),
              )
            : mq;

        return ProviderScope(
          overrides: [layoutSpecProvider.overrideWithValue(spec)],
          child: MediaQuery(
            data: mqFullWidth,
            child: _SystemUiModeController(
              isLandscape: isLandscape,
              child: _WakelockMidiGate(
                child: Scaffold(
                  appBar: AppBar(
                    titleSpacing: isLandscape ? 28 : null,
                    // ...
                    backgroundColor: cs.surfaceContainerLow,
                    foregroundColor: cs.onSurface,
                    actions: [
                      const MidiStatusPill(),
                      Padding(
                        padding: EdgeInsets.only(right: isLandscape ? 12 : 0),
                        child: IconButton(
                          tooltip: 'Settings',
                          icon: const Icon(Icons.settings),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SettingsPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  body: SafeArea(
                    child: isLandscape
                        ? const _HomeLandscape()
                        : const _HomePortrait(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    final themeMode = ref.watch(themeModeProvider);
    final chordNotation = ref.watch(chordNotationProvider);
    final palette = ref.watch(appPaletteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: cs.surfaceContainerLow,
        foregroundColor: cs.onSurface,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const _SectionHeader(title: 'Input'),
          ListTile(
            leading: const Icon(Icons.piano),
            title: const Text('MIDI input'),
            subtitle: const Text('Not configured (placeholder)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('MIDI config placeholder')),
              );
            },
          ),

          const SizedBox(height: 16),
          const _SectionHeader(title: 'Chord display'),
          RadioGroup<ChordNotation>(
            groupValue: chordNotation,
            onChanged: (ChordNotation? v) {
              if (v == null) return;
              ref.read(chordNotationProvider.notifier).setNotation(v);
            },
            child: const Column(
              children: [
                RadioListTile<ChordNotation>(
                  title: Text('Standard notation'),
                  subtitle: Text('E.g., Cmaj7, F#m7b5'),
                  value: ChordNotation.standard,
                ),
                RadioListTile<ChordNotation>(
                  title: Text('Jazz notation'),
                  subtitle: Text('E.g., CΔ7, F#ø7'),
                  value: ChordNotation.jazz,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const _SectionHeader(title: 'Appearance'),
          const _SubsectionLabel(title: 'Theme'),
          RadioGroup<ThemeMode>(
            groupValue: themeMode,
            onChanged: (ThemeMode? mode) {
              if (mode == null) return;
              ref.read(themeModeProvider.notifier).setThemeMode(mode);
            },
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text('System'),
                  subtitle: Text('Follow device setting'),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Light'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Dark'),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const _SubsectionLabel(title: 'Color palette'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Color palette'),
            subtitle: Text(palette.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final selected = await showModalBottomSheet<AppPalette>(
                context: context,
                showDragHandle: true,
                builder: (context) {
                  final current = palette;
                  return SafeArea(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final p in AppPalette.values)
                          ListTile(
                            title: Text(p.label),
                            trailing: (p == current)
                                ? const Icon(Icons.check)
                                : null,
                            onTap: () => Navigator.of(context).pop(p),
                          ),
                      ],
                    ),
                  );
                },
              );

              if (selected != null) {
                ref.read(appPaletteProvider.notifier).setPalette(selected);
              }
            },
          ),

          const SizedBox(height: 16),
          const _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('WhatChord'),
            subtitle: ref
                .watch(appVersionProvider)
                .when(
                  data: (version) => Text('Version $version'),
                  loading: () => const Text('Version —'),
                  error: (_, _) => const Text('Version unavailable'),
                ),
          ),

          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Source code'),
            subtitle: const Text('View on GitHub'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              final messenger = ScaffoldMessenger.of(context);
              final uri = Uri.parse(
                'https://github.com/EarthmanMuons/what_chord',
              );

              Future<void> open() async {
                try {
                  final ok = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );

                  if (!ok) {
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Could not open link')),
                    );
                  }
                } on PlatformException {
                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Could not open link')),
                  );
                } catch (_) {
                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Could not open link')),
                  );
                }
              }

              open();
            },
          ),
        ],
      ),
    );
  }
}

class _HomePortrait extends ConsumerWidget {
  const _HomePortrait({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spec = ref.watch(layoutSpecProvider);

    return Column(
      children: [
        const Flexible(fit: FlexFit.loose, child: AnalysisSection()),

        SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const NoteChipsArea(),
              KeyFunctionBar(height: spec.functionBarHeight),
              const Divider(height: 1),
              const KeyboardSection(),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeLandscape extends ConsumerWidget {
  const _HomeLandscape({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spec = ref.watch(layoutSpecProvider);
    return Column(
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(flex: 6, child: AnalysisSection()),
              Expanded(
                flex: 7,
                child: Padding(
                  padding: spec.controlPanePadding,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: const NoteChipsArea(),
                  ),
                ),
              ),
            ],
          ),
        ),

        SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KeyFunctionBar(height: spec.functionBarHeight),
              const Divider(height: 1),
              const KeyboardSection(),
            ],
          ),
        ),
      ],
    );
  }
}

class AnalysisSection extends ConsumerWidget {
  const AnalysisSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(chordAnalysisProvider);
    final spec = ref.watch(layoutSpecProvider);

    return Padding(
      padding: spec.analysisPadding,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: spec.chordCardMaxWidth),
            child: ChordIdentityCard(
              chord: analysis.chordName,
              inversionLabel: analysis.inversionLabel,
            ),
          ),
        ),
      ),
    );
  }
}

class KeyFunctionBar extends ConsumerWidget {
  const KeyFunctionBar({super.key, required this.height});
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
                onPressed: () async {
                  if (!context.mounted) return;

                  final navigator = Navigator.of(context, rootNavigator: true);
                  final isLandscape =
                      MediaQuery.of(context).orientation ==
                      Orientation.landscape;

                  navigator.push(
                    ModalBottomSheetRoute(
                      builder: (_) => _KeyPickerSheet(
                        closeOnSelect: false,
                        initialIsLandscape: isLandscape,
                      ),
                      isScrollControlled: true,
                      showDragHandle: true,
                    ),
                  );
                },
                icon: const Icon(Icons.music_note),
                label: Text('Key: ${selectedKey.longLabel}'),
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

class KeyboardSection extends ConsumerWidget {
  const KeyboardSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeMidiNotesProvider);
    final spec = ref.watch(layoutSpecProvider);

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

class _SystemUiModeController extends StatefulWidget {
  const _SystemUiModeController({
    required this.child,
    required this.isLandscape,
  });

  final Widget child;
  final bool isLandscape;

  @override
  State<_SystemUiModeController> createState() =>
      _SystemUiModeControllerState();
}

class _SystemUiModeControllerState extends State<_SystemUiModeController> {
  bool? _last;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _apply(widget.isLandscape);
  }

  @override
  void didUpdateWidget(covariant _SystemUiModeController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLandscape != widget.isLandscape) {
      _apply(widget.isLandscape);
    }
  }

  void _apply(bool isLandscape) {
    if (_last == isLandscape) return;
    _last = isLandscape;

    if (isLandscape) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: const [],
      );
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _WakelockMidiGate extends ConsumerStatefulWidget {
  const _WakelockMidiGate({required this.child});

  final Widget child;

  @override
  ConsumerState<_WakelockMidiGate> createState() => _WakelockMidiGateState();
}

class _WakelockMidiGateState extends ConsumerState<_WakelockMidiGate> {
  bool? _lastApplied;

  @override
  void dispose() {
    // Safety: ensure wakelock is off when leaving this subtree.
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shouldKeepAwake = ref.watch(
      midiConnectionProvider.select(
        (s) =>
            s.status == MidiConnectionStatus.connected ||
            s.status == MidiConnectionStatus.connecting,
      ),
    );

    if (_lastApplied != shouldKeepAwake) {
      _lastApplied = shouldKeepAwake;

      // Avoid doing platform work in the middle of the build pipeline.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        WakelockPlus.toggle(enable: shouldKeepAwake);
      });
    }

    return widget.child;
  }
}

class MidiStatusPill extends ConsumerWidget {
  const MidiStatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final midi = ref.watch(midiConnectionProvider);

    final (label, bg, fg, border) = switch (midi.status) {
      MidiConnectionStatus.connected => (
        'MIDI: Connected',
        cs.secondaryContainer,
        cs.onSecondaryContainer,
        cs.outlineVariant.withValues(alpha: 0.35),
      ),
      MidiConnectionStatus.connecting => (
        'MIDI: Connecting…',
        cs.secondaryContainer,
        cs.onSecondaryContainer,
        cs.outlineVariant.withValues(alpha: 0.35),
      ),
      MidiConnectionStatus.error => (
        'MIDI: Error',
        cs.errorContainer,
        cs.onErrorContainer,
        cs.outlineVariant.withValues(alpha: 0.35),
      ),
      MidiConnectionStatus.disconnected => (
        'MIDI: Disconnected',
        cs.surfaceContainerHigh,
        cs.onSurfaceVariant,
        cs.outlineVariant.withValues(alpha: 0.55),
      ),
    };

    final tooltip = midi.message?.trim().isNotEmpty == true
        ? '$label\n${midi.message}'
        : label;

    return Semantics(
      label: 'MIDI connection status',
      value: label,
      child: Tooltip(
        message: tooltip,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: bg,
            shape: StadiumBorder(side: BorderSide(color: border)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MidiStatusDot(status: midi.status, colorScheme: cs),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MidiStatusDot extends StatefulWidget {
  const _MidiStatusDot({required this.status, required this.colorScheme});

  final MidiConnectionStatus status;
  final ColorScheme colorScheme;

  @override
  State<_MidiStatusDot> createState() => _MidiStatusDotState();
}

class _MidiStatusDotState extends State<_MidiStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _MidiStatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.status == MidiConnectionStatus.connecting) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0; // reset to “rest” state
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = switch (widget.status) {
      MidiConnectionStatus.connected => Colors.green.shade600,
      MidiConnectionStatus.connecting => widget.colorScheme.secondary,
      MidiConnectionStatus.error => widget.colorScheme.error,
      MidiConnectionStatus.disconnected =>
        widget.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
    };

    // Pulse only when connecting; otherwise it will sit at the base values.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value; // 0..1
        final scale = 1.0 + (0.20 * t); // up to 1.20x
        final opacity = 0.70 + (0.30 * t); // 0.70..1.00

        return Opacity(
          opacity: widget.status == MidiConnectionStatus.connecting
              ? opacity
              : 1.0,
          child: Transform.scale(
            scale: widget.status == MidiConnectionStatus.connecting
                ? scale
                : 1.0,
            child: child,
          ),
        );
      },
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
      ),
    );
  }
}

class ChordIdentityCard extends StatelessWidget {
  final ChordNameParts chord;
  final String? inversionLabel;

  const ChordIdentityCard({
    super.key,
    required this.chord,
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

    final rootStyle = chordStyle.copyWith(fontWeight: FontWeight.w900);

    final inversionStyle = theme.textTheme.titleMedium!.copyWith(
      color: cs.onPrimary.withValues(alpha: 0.85),
      height: 1.1,
    );

    final minCardHeight = 124.0;
    final padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 18);

    Widget chordText() {
      final spans = <InlineSpan>[
        TextSpan(text: chord.root, style: rootStyle),
        if (chord.remainder.isNotEmpty) ...[
          const TextSpan(text: '\u200A'), // hair space
          TextSpan(text: chord.remainder),
        ],
        if (chord.hasSlash) ...[
          const TextSpan(text: ' / '),
          TextSpan(text: chord.slashBass),
        ],
      ];

      return Text.rich(
        TextSpan(style: chordStyle, children: spans),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

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
                    chordText(),
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
              : Center(child: chordText()),
        ),
      ),
    );
  }
}

class NoteChipsArea extends ConsumerStatefulWidget {
  const NoteChipsArea({super.key});

  @override
  ConsumerState<NoteChipsArea> createState() => _NoteChipsAreaState();
}

class _NoteChipsAreaState extends ConsumerState<NoteChipsArea> {
  final _listKey = GlobalKey<AnimatedListState>();

  late List<NoteChipModel> _items;
  ProviderSubscription<List<NoteChipModel>>? _sub;

  @override
  void initState() {
    super.initState();

    _items = ref.read(noteChipModelsProvider);

    _sub = ref.listenManual<List<NoteChipModel>>(noteChipModelsProvider, (
      prev,
      next,
    ) {
      if (!mounted) return;
      _applyDiff(next);
    });
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  void _applyDiff(List<NoteChipModel> next) {
    final currentIds = _items.map((e) => e.id).toList();
    final nextIds = next.map((e) => e.id).toList();

    // 1) Remove items that no longer exist (reverse order keeps indices valid).
    for (int i = _items.length - 1; i >= 0; i--) {
      final id = _items[i].id;
      if (!nextIds.contains(id)) {
        final removed = _items.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _buildAnimatedChip(removed, animation),
          duration: const Duration(milliseconds: 120),
        );
      }
    }

    // 2) Insert new items in forward order at their target indices.
    for (int i = 0; i < next.length; i++) {
      final id = next[i].id;
      if (!currentIds.contains(id)) {
        _items.insert(i, next[i]);
        _listKey.currentState?.insertItem(
          i,
          duration: const Duration(milliseconds: 140),
        );
      }
    }

    // 3) Update existing items (pressed <-> sustained transitions, etc.).
    // Ensure _items matches next order/content.
    // Our order is stable (sustain at 0 + ascending MIDI), so this is safe.
    setState(() {
      _items = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spec = ref.watch(layoutSpecProvider);
    final models = ref.watch(noteChipModelsProvider);
    final hold = ref.watch(midiHoldProvider);

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    const minHeight = 44.0;

    final showPrompt = models.isEmpty && !hold.sustainDown;

    return Padding(
      padding: spec.noteChipsPadding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minHeight),
        child: showPrompt
            ? Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Play notes…',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              )
            : SizedBox(
                height: minHeight,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: minHeight,
                    child: AnimatedList(
                      key: _listKey,
                      initialItemCount: _items.length,
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index, animation) {
                        final model = _items[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildAnimatedChip(model, animation),
                        );
                      },
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAnimatedChip(NoteChipModel model, Animation<double> animation) {
    // Use a SizeTransition for smooth insertion/removal, plus a slight slide/fade.
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    final slideFrom = model.kind == NoteChipKind.sustainIndicator
        ? const Offset(-0.20, 0) // sustain pill slides in from left
        : const Offset(0.0, 0); // notes just fade/size in

    return SizeTransition(
      sizeFactor: curved,
      axis: Axis.horizontal,
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: slideFrom,
            end: Offset.zero,
          ).animate(curved),
          child: _NoteChip(model: model),
        ),
      ),
    );
  }
}

class SustainPedalMark extends StatelessWidget {
  const SustainPedalMark({super.key});

  static const double slotWidth = 36;
  static const double glyphSize = 32;
  static const Offset opticalOffset = Offset(0, -3);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: Semantics(
        label: 'Sustain pedal held',
        child: Tooltip(
          message: 'Sustain pedal held',
          child: SizedBox(
            width: slotWidth,
            height: double.infinity,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: opticalOffset,
                child: SvgPicture.asset(
                  'assets/glyphs/keyboard_pedal_ped.svg',
                  width: glyphSize,
                  height: glyphSize,
                  alignment: Alignment.centerLeft,
                  colorFilter: ColorFilter.mode(
                    cs.onSurfaceVariant,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteChip extends ConsumerWidget {
  const _NoteChip({required this.model});

  final NoteChipModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (model.kind == NoteChipKind.sustainIndicator) {
      return const SustainPedalMark();
    }

    final hold = ref.watch(midiHoldProvider);
    final sustainDown = hold.sustainDown;

    final isSustainedNote =
        model.kind == NoteChipKind.note && model.hold == NoteChipHold.sustained;

    final bgColor = model.kind == NoteChipKind.sustainIndicator
        ? Colors.transparent
        : cs.surfaceContainerLow;

    final fgColor = model.kind == NoteChipKind.sustainIndicator
        ? cs.onSurfaceVariant
        : cs.onSurface;

    // Slightly darken all note borders when sustain is down,
    // and darken further (or thicken) for sustained notes.
    final borderColor = model.kind == NoteChipKind.sustainIndicator
        ? cs.outlineVariant
        : (isSustainedNote
              ? cs.outlineVariant.withValues(alpha: 0.92)
              : cs.outlineVariant.withValues(alpha: sustainDown ? 0.78 : 0.60));

    final borderWidth = isSustainedNote ? 1.6 : 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: model.kind == NoteChipKind.sustainIndicator
          ? Tooltip(
              message: 'Sustain pedal held',
              child: Semantics(
                label: 'Sustain pedal held',
                child: Icon(
                  Icons.keyboard_double_arrow_down_rounded,
                  size: 18,
                  color: fgColor,
                ),
              ),
            )
          : Text(
              model.label,
              style: theme.textTheme.titleMedium?.copyWith(color: fgColor),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: cs.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SubsectionLabel extends StatelessWidget {
  const _SubsectionLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(color: cs.onSurface),
      ),
    );
  }
}

class _KeyPickerSheet extends ConsumerStatefulWidget {
  final bool closeOnSelect;
  final bool initialIsLandscape;

  const _KeyPickerSheet({
    required this.initialIsLandscape,
    this.closeOnSelect = false,
  });

  @override
  ConsumerState<_KeyPickerSheet> createState() => _KeyPickerSheetState();
}

class _KeyPickerSheetState extends ConsumerState<_KeyPickerSheet> {
  static const _loopMultiplier = 200;

  static const double _rowExtent = 62.0;
  static const double _headerExtent = 46.0;
  static const double _chipWidth = 64.0;

  late final ScrollController _controller;
  late final List<KeySignatureRow> _rows;

  bool? _lastIsLandscape;

  @override
  void initState() {
    super.initState();

    _rows = _buildOrderedRows();
    _controller = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _centerSelectedRow();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedKeyProvider);

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final selectedRowBg = Color.alphaBlend(
      cs.primary.withValues(alpha: 0.06),
      cs.surface,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscapeNow = constraints.maxWidth > constraints.maxHeight;

        // Detect orientation change and recenter if needed
        if (_lastIsLandscape != null && _lastIsLandscape != isLandscapeNow) {
          _lastIsLandscape = isLandscapeNow;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _centerSelectedRow();
          });
        } else {
          _lastIsLandscape = isLandscapeNow; // Set on first pass
        }

        final mq = MediaQuery.of(context);

        // Always strip left/right for full-width expansion (existing, for full internal use of route space)
        final mqAdjusted = isLandscapeNow
            ? mq.copyWith(
                padding: mq.padding.copyWith(left: 0, right: 0),
                viewPadding: mq.viewPadding.copyWith(left: 0, right: 0),
              )
            : mq;

        final screenHeight = mqAdjusted.size.height;
        final sheetHeight = isLandscapeNow
            ? screenHeight // Full height in landscape
            : screenHeight * 0.5; // Half height in portrait

        return MediaQuery(
          data: mqAdjusted,
          child: SafeArea(
            left: !isLandscapeNow,
            right: !isLandscapeNow,
            child: SizedBox(
              height: sheetHeight,
              child: CustomScrollView(
                controller: _controller,
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _KeyPickerHeaderDelegate(
                      extent: _headerExtent,
                      chipWidth: _chipWidth,
                      brightness: cs.brightness,
                      backgroundColor: cs.surfaceContainerLow,
                    ),
                  ),
                  SliverFixedExtentList(
                    itemExtent: _rowExtent,
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final row = _rows[index % _rows.length];
                      final major = row.relativeMajor;
                      final minor = row.relativeMinor;

                      final rowSelected =
                          selected == major || selected == minor;
                      final majorSelected = selected == major;
                      final minorSelected = selected == minor;

                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: rowSelected
                              ? selectedRowBg
                              : Colors.transparent,
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        row.signatureLabel,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: _chipWidth,
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: _KeyChoiceChip(
                                          label: major.label,
                                          selected: majorSelected,
                                          onTap: () => _selectKey(major),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: _chipWidth,
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: _KeyChoiceChip(
                                          label: minor.label,
                                          selected: minorSelected,
                                          onTap: () => _selectKey(minor),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Divider(height: 1),
                            ),
                          ],
                        ),
                      );
                    }, childCount: _rows.length * _loopMultiplier),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<KeySignatureRow> _buildOrderedRows() {
    KeySignatureRow rowFor(int acc) =>
        keySignatureRows.firstWhere((r) => r.accidentals == acc);

    return <KeySignatureRow>[
      for (var n = 7; n >= 1; n--) rowFor(n), // 7♯ … 1♯
      rowFor(0), // 0
      for (var n = 1; n <= 7; n++) rowFor(-n), // 1♭ … 7♭
    ];
  }

  int _baseIndexForSelected(MusicalKey selected) {
    final i = _rows.indexWhere(
      (row) => row.relativeMajor == selected || row.relativeMinor == selected,
    );
    if (i >= 0) return i;

    return _rows.indexWhere((row) => row.accidentals == 0);
  }

  void _centerSelectedRow() {
    if (!_controller.hasClients) return;

    final selected = ref.read(selectedKeyProvider);
    final viewport = _controller.position.viewportDimension;

    final base = _baseIndexForSelected(selected);
    final middleStart = _rows.length * (_loopMultiplier ~/ 2);
    final selectedIndex = middleStart + base;

    final target =
        (selectedIndex * _rowExtent) - (viewport / 2) + (_rowExtent / 2);

    _controller.jumpTo(
      target.clamp(
        _controller.position.minScrollExtent,
        _controller.position.maxScrollExtent,
      ),
    );
  }

  Future<void> _selectKey(MusicalKey key) async {
    ref.read(selectedKeyProvider.notifier).setKey(key);

    if (!widget.closeOnSelect) return;

    // If you do close, let the UI update be visible first.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (mounted) Navigator.of(context).pop();
  }
}

class _KeyChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _KeyChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final side = BorderSide(
      color: selected ? cs.primary : cs.outlineVariant,
      width: selected ? 1.5 : 1.0,
    );

    return ChoiceChip(
      label: SizedBox(
        width: 44,
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: side,
      ),
    );
  }
}

class _KeyPickerHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double extent;
  final double chipWidth;
  final Brightness brightness;
  final Color backgroundColor;

  const _KeyPickerHeaderDelegate({
    required this.extent,
    required this.chipWidth,
    required this.brightness,
    required this.backgroundColor,
  });

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final headerStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    );

    return Material(
      color: backgroundColor,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: Text('Signature', style: headerStyle)),
                  SizedBox(
                    width: chipWidth,
                    child: Text(
                      'Major',
                      textAlign: TextAlign.center,
                      style: headerStyle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: chipWidth,
                    child: Text(
                      'Minor',
                      textAlign: TextAlign.center,
                      style: headerStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, thickness: 2),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _KeyPickerHeaderDelegate oldDelegate) {
    return oldDelegate.extent != extent ||
        oldDelegate.chipWidth != chipWidth ||
        oldDelegate.brightness != brightness ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

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
