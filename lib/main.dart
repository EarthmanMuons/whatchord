import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'features/midi/models/bluetooth_state.dart';
import 'features/midi/models/midi_connection_state.dart';
import 'features/midi/models/midi_message.dart';
import 'features/midi/models/midi_note_state.dart';
import 'features/midi/providers/midi_providers.dart';
import 'features/midi/services/stub_midi_service.dart';
import 'features/midi/widgets/midi_device_picker.dart';

import 'features/piano/piano.dart';

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

enum ChordSymbolStyle { standard, jazz }

@immutable
class ChordSymbol {
  final String root; // e.g., "C", "F#", "Bb"
  final String quality; // e.g., "maj", "m7(b5)", "sus4", "" (optional)
  final String? bass; // e.g., "E" in "Cmaj / E" (no leading " / ")

  const ChordSymbol({required this.root, this.quality = '', this.bass});

  bool get hasBass => bass?.trim().isNotEmpty ?? false;

  String format() {
    final base = '$root$quality';
    return hasBass ? '$base / ${bass!}' : base;
  }
}

@immutable
class ChordAnalysis {
  final ChordSymbol symbol;
  final String? inversion;

  const ChordAnalysis({required this.symbol, required this.inversion});

  bool get hasInversion => inversion != null && inversion!.trim().isNotEmpty;
}

@immutable
class ActiveNote {
  final int midiNote;
  final String label; // e.g., "C4", "F#5"
  final bool isSustained; // true if held by pedal, false if currently pressed

  const ActiveNote({
    required this.midiNote,
    required this.label,
    required this.isSustained,
  });

  /// Stable ID for AnimatedList diffing.
  String get id => 'note_$midiNote';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveNote &&
          runtimeType == other.runtimeType &&
          midiNote == other.midiNote &&
          label == other.label &&
          isSustained == other.isSustained;

  @override
  int get hashCode => Object.hash(midiNote, label, isSustained);
}

enum TonalityMode { major, minor }

@immutable
class Tonality {
  final String tonic; // e.g. "C", "F#", "Bb"
  final TonalityMode mode;

  const Tonality(this.tonic, this.mode);

  bool get isMajor => mode == TonalityMode.major;
  bool get isMinor => mode == TonalityMode.minor;

  String get label => isMajor ? tonic : tonic.toLowerCase();

  String get displayName => isMajor ? '$tonic major' : '$tonic minor';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tonality &&
          runtimeType == other.runtimeType &&
          tonic == other.tonic &&
          mode == other.mode;

  @override
  int get hashCode => Object.hash(tonic, mode);

  @override
  String toString() => displayName;
}

final selectedTonalityProvider =
    NotifierProvider<SelectedTonalityNotifier, Tonality>(
      SelectedTonalityNotifier.new,
    );

class SelectedTonalityNotifier extends Notifier<Tonality> {
  @override
  Tonality build() => const Tonality('C', TonalityMode.major);

  void setTonality(Tonality tonality) => state = tonality;
}

enum ScaleDegree {
  one('I'),
  two('ii'),
  three('iii'),
  four('IV'),
  five('V'),
  six('vi'),
  seven('vii°');

  final String romanNumeral;
  const ScaleDegree(this.romanNumeral);
}

@immutable
class KeySignature {
  /// Negative = flats, positive = sharps. e.g. -2 means 2 flats, +3 means 3 sharps.
  final int accidentalCount;
  final Tonality relativeMajor;
  final Tonality relativeMinor;

  const KeySignature({
    required this.accidentalCount,
    required this.relativeMajor,
    required this.relativeMinor,
  });

  String get label {
    if (accidentalCount == 0) return 'no sharps/flats';
    final n = accidentalCount.abs();
    final countText = n == 1 ? '1' : '$n';
    return accidentalCount > 0
        ? '$countText sharp${n == 1 ? '' : 's'}'
        : '$countText flat${n == 1 ? '' : 's'}';
  }
}

/// Circle-of-fifths-ish ordering that also includes the “full” 15 signatures:
/// 7 flats ... 0 ... 7 sharps
const keySignatureRows = <KeySignature>[
  KeySignature(
    accidentalCount: -7,
    relativeMajor: Tonality('C♭', TonalityMode.major),
    relativeMinor: Tonality('A♭', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -6,
    relativeMajor: Tonality('G♭', TonalityMode.major),
    relativeMinor: Tonality('E♭', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -5,
    relativeMajor: Tonality('D♭', TonalityMode.major),
    relativeMinor: Tonality('B♭', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -4,
    relativeMajor: Tonality('A♭', TonalityMode.major),
    relativeMinor: Tonality('F', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -3,
    relativeMajor: Tonality('E♭', TonalityMode.major),
    relativeMinor: Tonality('C', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -2,
    relativeMajor: Tonality('B♭', TonalityMode.major),
    relativeMinor: Tonality('G', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -1,
    relativeMajor: Tonality('F', TonalityMode.major),
    relativeMinor: Tonality('D', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 0,
    relativeMajor: Tonality('C', TonalityMode.major),
    relativeMinor: Tonality('A', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 1,
    relativeMajor: Tonality('G', TonalityMode.major),
    relativeMinor: Tonality('E', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 2,
    relativeMajor: Tonality('D', TonalityMode.major),
    relativeMinor: Tonality('B', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 3,
    relativeMajor: Tonality('A', TonalityMode.major),
    relativeMinor: Tonality('F♯', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 4,
    relativeMajor: Tonality('E', TonalityMode.major),
    relativeMinor: Tonality('C♯', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 5,
    relativeMajor: Tonality('B', TonalityMode.major),
    relativeMinor: Tonality('G♯', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 6,
    relativeMajor: Tonality('F♯', TonalityMode.major),
    relativeMinor: Tonality('D♯', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 7,
    relativeMajor: Tonality('C♯', TonalityMode.major),
    relativeMinor: Tonality('A♯', TonalityMode.minor),
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

class ChordSymbolNotifier extends Notifier<ChordSymbolStyle> {
  @override
  ChordSymbolStyle build() => ChordSymbolStyle.standard;
  void setStyle(ChordSymbolStyle style) => state = style;
}

final chordSymbolProvider =
    NotifierProvider<ChordSymbolNotifier, ChordSymbolStyle>(
      ChordSymbolNotifier.new,
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
class HomeLayoutConfig {
  // Analysis
  final EdgeInsets analysisPadding;
  final double chordCardMaxWidth;
  final EdgeInsets detailsSectionPadding; // right panel (landscape)
  final EdgeInsets activeInputPadding;

  // Tonality
  final double tonalityBarHeight;

  // Keyboard
  final int whiteKeyCount;
  final double whiteKeyAspectRatio;
  final int firstMidiNote;

  const HomeLayoutConfig({
    required this.analysisPadding,
    required this.chordCardMaxWidth,
    required this.detailsSectionPadding,
    required this.activeInputPadding,
    required this.tonalityBarHeight,
    required this.whiteKeyCount,
    this.whiteKeyAspectRatio = 7.0,
    required this.firstMidiNote,
  });
}

const portraitLayoutConfig = HomeLayoutConfig(
  analysisPadding: EdgeInsets.fromLTRB(16, 16, 16, 16),
  chordCardMaxWidth: 520,
  detailsSectionPadding: EdgeInsets.zero,
  activeInputPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  tonalityBarHeight: 56,
  whiteKeyCount: 21,
  whiteKeyAspectRatio: 7.0,
  firstMidiNote: 48, // C3
);

const landscapeLayoutConfig = HomeLayoutConfig(
  analysisPadding: EdgeInsets.fromLTRB(16, 16, 8, 16),
  chordCardMaxWidth: 520,
  detailsSectionPadding: EdgeInsets.fromLTRB(8, 12, 16, 12),
  activeInputPadding: EdgeInsets.zero,
  tonalityBarHeight: 56,
  // Full 88-key view: 52 white keys from A0 (MIDI 21) to C8.
  whiteKeyCount: 52,
  whiteKeyAspectRatio: 7.0,
  firstMidiNote: 21, // A0
);

final midiConnectionProvider =
    NotifierProvider<MidiConnectionNotifier, MidiConnectionState>(
      MidiConnectionNotifier.new,
    );

class MidiConnectionNotifier extends Notifier<MidiConnectionState> {
  @override
  MidiConnectionState build() {
    debugPrint('[MidiConnectionNotifier] build()');

    // Watch bluetooth state and handle errors
    ref.listen(bluetoothStateStreamProvider, (previous, next) {
      next.when(
        data: (BluetoothState state) {
          if (state == BluetoothState.off) {
            setStatus(MidiConnectionStatus.error, message: 'Bluetooth is off');
          } else if (state == BluetoothState.unauthorized) {
            setStatus(
              MidiConnectionStatus.error,
              message: 'Bluetooth permission required',
            );
          }
        },
        loading: () {},
        error: (_, _) {},
      );
    });

    // Update status based on the connected device provider.
    ref.listen(connectedMidiDeviceProvider, (prev, next) {
      next.when(
        data: (device) {
          if (device != null && device.isConnected) {
            markConnected(deviceName: device.name);
          } else {
            markDisconnected();
          }
        },
        loading: () {},
        error: (_, _) => markDisconnected(),
      );
    });

    return const MidiConnectionState(status: MidiConnectionStatus.disconnected);
  }

  void setStatus(MidiConnectionStatus status, {String? message}) {
    state = state.copyWith(status: status, message: message);
  }

  void markConnecting() => setStatus(MidiConnectionStatus.connecting);
  void markConnected({String? deviceName}) =>
      setStatus(MidiConnectionStatus.connected, message: deviceName);
  void markDisconnected() => setStatus(MidiConnectionStatus.disconnected);
  void markError(String message) =>
      setStatus(MidiConnectionStatus.error, message: message);
}

final midiNoteStateProvider =
    NotifierProvider<MidiNoteStateNotifier, MidiNoteState>(
      MidiNoteStateNotifier.new,
    );

class MidiNoteStateNotifier extends Notifier<MidiNoteState> {
  @override
  MidiNoteState build() {
    // Start with empty state
    final initialState = const MidiNoteState(
      pressed: {},
      sustained: {},
      isPedalDown: false,
    );

    // Listen to MIDI messages and update state
    ref.listen(midiMessageStreamProvider, (previous, next) {
      next.when(
        data: (message) {
          if (message != null) {
            _handleMidiMessage(message);
          }
        },
        loading: () {},
        error: (error, stack) {
          print('MIDI message error: $error');
        },
      );
    });

    return initialState;
  }

  void _handleMidiMessage(MidiMessage message) {
    switch (message.type) {
      case MidiMessageType.noteOn:
        if (message.note != null) {
          noteOn(message.note!);
        }
        break;

      case MidiMessageType.noteOff:
        if (message.note != null) {
          noteOff(message.note!);
        }
        break;

      case MidiMessageType.controlChange:
        // CC64 is the sustain pedal
        if (message.controller == 64 && message.value != null) {
          handlePedalValue(message.value!);
        }
        break;

      default:
        // Ignore other message types
        break;
    }
  }

  void noteOn(int midiNote) {
    final nextPressed = {...state.pressed, midiNote};

    // If a sustained note is re-pressed, remove it from sustained.
    final nextSustained = {...state.sustained}..remove(midiNote);

    state = state.copyWith(pressed: nextPressed, sustained: nextSustained);
  }

  void noteOff(int midiNote) {
    if (!state.pressed.contains(midiNote)) return;

    final nextPressed = {...state.pressed}..remove(midiNote);

    if (state.isPedalDown) {
      final nextSustained = {...state.sustained, midiNote};
      state = state.copyWith(pressed: nextPressed, sustained: nextSustained);
    } else {
      state = state.copyWith(pressed: nextPressed);
    }
  }

  void setPedalDown(bool down) {
    if (down == state.isPedalDown) return;

    if (!down) {
      // Pedal released: clear all sustained notes.
      state = state.copyWith(isPedalDown: false, sustained: <int>{});
    } else {
      state = state.copyWith(isPedalDown: true);
    }
  }

  // Convenience for MIDI CC64 values (sustain pedal).
  // Convention: >= 64 is down, < 64 is up.
  void handlePedalValue(int value) => setPedalDown(value >= 64);
}

// Raw MIDI note numbers for keyboard highlighting.
final activeMidiNotesProvider = Provider<Set<int>>((ref) {
  final state = ref.watch(midiNoteStateProvider);
  return state.activeNotes;
});

// Sustain pedal state for display.
final isPedalDownProvider = Provider<bool>((ref) {
  return ref.watch(midiNoteStateProvider.select((s) => s.isPedalDown));
});

// Rich note objects for display, sorted by pitch.
final activeNotesProvider = Provider<List<ActiveNote>>((ref) {
  final state = ref.watch(midiNoteStateProvider);

  final notes = <ActiveNote>[];
  final activeSorted = state.activeNotes.toList()..sort();

  for (final midi in activeSorted) {
    notes.add(
      ActiveNote(
        midiNote: midi,
        label: _midiToNoteName(midi),
        isSustained: state.sustained.contains(midi),
      ),
    );
  }

  return notes;
});

final chordAnalysisProvider = Provider<ChordAnalysis>((ref) {
  return const ChordAnalysis(
    symbol: ChordSymbol(root: 'C', quality: 'maj', bass: 'E'),
    inversion: '1st inversion',
  );
});

final activeScaleDegreeProvider = Provider<ScaleDegree?>((ref) {
  final tonality = ref.watch(selectedTonalityProvider);
  final analysis = ref.watch(chordAnalysisProvider);

  // Stub logic
  if (analysis.symbol.format().startsWith(tonality.label)) {
    return ScaleDegree.one;
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

    // Initialize MIDI service on first build.
    ref.watch(midiServiceInitProvider);

    // Listen for connection state changes and show feedback.
    ref.listen(midiConnectionProvider, (previous, next) {
      // Only show notifications if the state actually changed
      if (previous?.status == next.status) return;

      // Show error notifications
      if (next.status == MidiConnectionStatus.error) {
        // Extract clean error message
        final errorMsg = next.message ?? 'MIDI connection error';
        final cleanMsg = errorMsg
            .replaceAll('MidiException: ', '')
            .replaceAll('Exception: ', '');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(cleanMsg)),
              ],
            ),
            backgroundColor: cs.error,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
                );
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }

      // Show connection success
      if (previous?.status != MidiConnectionStatus.connected &&
          next.status == MidiConnectionStatus.connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('MIDI Connected: ${next.message ?? "Device"}'),
                ),
              ],
            ),
            backgroundColor: cs.primaryContainer,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Show disconnection
      if (previous?.status == MidiConnectionStatus.connected &&
          next.status == MidiConnectionStatus.disconnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.bluetooth_disabled, color: Colors.white),
                SizedBox(width: 12),
                Text('MIDI disconnected'),
              ],
            ),
            backgroundColor: cs.surfaceContainerHighest,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final config = isLandscape
            ? landscapeLayoutConfig
            : portraitLayoutConfig;

        final mq = MediaQuery.of(context);
        final mqFullWidth = isLandscape
            ? mq.copyWith(
                padding: mq.padding.copyWith(left: 0, right: 0),
                viewPadding: mq.viewPadding.copyWith(left: 0, right: 0),
              )
            : mq;

        return MediaQuery(
          data: mqFullWidth,
          child: _EdgeToEdgeController(
            isLandscape: isLandscape,
            child: _WakelockController(
              child: Scaffold(
                appBar: AppBar(
                  titleSpacing: isLandscape ? 28 : null,
                  title: const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'What'),
                        TextSpan(
                          text: 'Chord',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
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
                      ? _HomeLandscape(config: config)
                      : _HomePortrait(config: config),
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
    final chordNotation = ref.watch(chordSymbolProvider);
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
            subtitle: _buildMidiSubtitle(ref),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MidiSettingsPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          const _SectionHeader(title: 'Chord display'),
          RadioGroup<ChordSymbolStyle>(
            groupValue: chordNotation,
            onChanged: (ChordSymbolStyle? style) {
              if (style == null) return;
              ref.read(chordSymbolProvider.notifier).setStyle(style);
            },
            child: const Column(
              children: [
                RadioListTile<ChordSymbolStyle>(
                  title: Text('Standard notation'),
                  subtitle: Text('E.g., Cmaj7, F#m7b5'),
                  value: ChordSymbolStyle.standard,
                ),
                RadioListTile<ChordSymbolStyle>(
                  title: Text('Jazz notation'),
                  subtitle: Text('E.g., CΔ7, F#ø7'),
                  value: ChordSymbolStyle.jazz,
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

  Widget _buildMidiSubtitle(WidgetRef ref) {
    final connectionState = ref.watch(midiConnectionProvider);
    final mode = ref.watch(midiModeProvider);

    if (connectionState.isConnected) {
      return Text('${connectionState.message ?? 'Connected'} (${mode.name})');
    }

    return Text('Not connected (${mode.name})');
  }
}

class MidiSettingsPage extends ConsumerStatefulWidget {
  const MidiSettingsPage({super.key});

  @override
  ConsumerState<MidiSettingsPage> createState() => _MidiSettingsPageState();
}

class _MidiSettingsPageState extends ConsumerState<MidiSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mode = ref.watch(midiModeProvider);
    final connectionState = ref.watch(midiConnectionProvider);
    final isInitializing = ref.watch(midiServiceInitProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MIDI Input'),
        backgroundColor: cs.surfaceContainerLow,
        foregroundColor: cs.onSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mode Toggle (Development only - can remove in production)
          Card(
            child: SwitchListTile(
              title: const Text('Use Real MIDI Hardware'),
              subtitle: Text('Current mode: ${mode.name}'),
              value: mode == MidiMode.real,
              onChanged: (_) {
                ref.read(midiModeProvider.notifier).toggle();
              },
            ),
          ),

          const SizedBox(height: 16),

          // Connection Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connection Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatusIndicator(connectionState.status),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          connectionState.isConnected
                              ? 'Connected to ${connectionState.message}'
                              : switch (connectionState.status) {
                                  MidiConnectionStatus.connecting =>
                                    'Connecting...',
                                  MidiConnectionStatus.error =>
                                    connectionState.message ?? 'Error',
                                  _ => 'Not connected',
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Live MIDI Preview (shows current notes)
          const SizedBox(height: 16),
          const _MidiLivePreview(),

          const SizedBox(height: 24),

          // Test Section (only in stub mode)
          if (mode == MidiMode.stub) ...[
            const _SectionHeader(title: 'Testing'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Stub Mode Test Controls',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Watch the preview above to see MIDI events',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.music_note),
                      label: const Text('Play C Major Chord'),
                      onPressed: _testCMajorChord,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.music_note),
                      label: const Text('Play F Major Chord'),
                      onPressed: _testFMajorChord,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.piano),
                      label: const Text('Test Sustain Pedal'),
                      onPressed: _testSustainPedal,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Real MIDI controls
          if (mode == MidiMode.real) ...[
            const _SectionHeader(title: 'Device Management'),

            // Connection info
            if (connectionState.isConnected)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.bluetooth_connected),
                  title: const Text('Connected Device'),
                  subtitle: Text(connectionState.message ?? 'Unknown'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final actions = ref.read(midiConnectionActionsProvider);
                      await actions.disconnect();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Disconnected')),
                        );
                      }
                    },
                    child: const Text('Disconnect'),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Scan button
            if (isInitializing)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Initializing MIDI service...'),
                    ],
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.bluetooth_searching),
                label: Text(
                  connectionState.isConnected
                      ? 'Connect Different Device'
                      : 'Scan for Devices',
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    isScrollControlled: true,
                    builder: (_) => const MidiDevicePicker(),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  void _testCMajorChord() {
    final service = ref.read(midiServiceProvider);
    if (service is! StubMidiService) return;

    // Play all notes
    service.simulateNoteOn(60); // C4
    Future.delayed(const Duration(milliseconds: 50), () {
      service.simulateNoteOn(64); // E4
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      service.simulateNoteOn(67); // G4
    });

    // Release all notes after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      service.simulateNoteOff(60);
    });
    Future.delayed(const Duration(seconds: 2, milliseconds: 50), () {
      service.simulateNoteOff(64);
    });
    Future.delayed(const Duration(seconds: 2, milliseconds: 100), () {
      service.simulateNoteOff(67);
    });
  }

  void _testFMajorChord() {
    final service = ref.read(midiServiceProvider);
    if (service is! StubMidiService) return;

    service.simulateNoteOn(65); // F4
    Future.delayed(const Duration(milliseconds: 50), () {
      service.simulateNoteOn(69); // A4
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      service.simulateNoteOn(72); // C5
    });

    Future.delayed(const Duration(seconds: 2), () {
      service.simulateNoteOff(65);
    });
    Future.delayed(const Duration(seconds: 2, milliseconds: 50), () {
      service.simulateNoteOff(69);
    });
    Future.delayed(const Duration(seconds: 2, milliseconds: 100), () {
      service.simulateNoteOff(72);
    });
  }

  void _testSustainPedal() {
    final service = ref.read(midiServiceProvider);
    if (service is! StubMidiService) return;

    // Press pedal
    service.simulatePedal(true);

    // Play chord while pedal is down
    Future.delayed(const Duration(milliseconds: 200), () {
      service.simulateNoteOn(60); // C4
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      service.simulateNoteOn(64); // E4
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      service.simulateNoteOn(67); // G4
    });

    // Release notes (they should sustain because pedal is down)
    Future.delayed(const Duration(milliseconds: 800), () {
      service.simulateNoteOff(60);
    });
    Future.delayed(const Duration(milliseconds: 850), () {
      service.simulateNoteOff(64);
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      service.simulateNoteOff(67);
    });

    // Release pedal (notes should stop)
    Future.delayed(const Duration(milliseconds: 2500), () {
      service.simulatePedal(false);
    });
  }

  Widget _buildStatusIndicator(MidiConnectionStatus status) {
    final color = switch (status) {
      MidiConnectionStatus.connected => Colors.green,
      MidiConnectionStatus.connecting => Colors.orange,
      MidiConnectionStatus.error => Colors.red,
      MidiConnectionStatus.disconnected => Colors.grey,
    };

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _MidiLivePreview extends ConsumerWidget {
  const _MidiLivePreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final activeNotes = ref.watch(activeNotesProvider);
    final isPedalDown = ref.watch(isPedalDownProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.visibility, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Live MIDI Preview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pedal indicator - only show when pedal is down
            if (isPedalDown)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(height: 40, child: const PedalIndicator()),
                    const SizedBox(width: 8),
                    const Text('Sustain pedal held'),
                  ],
                ),
              ),

            // Active notes display
            if (activeNotes.isEmpty && !isPedalDown)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No active notes',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              )
            else if (activeNotes.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final note in activeNotes)
                    Chip(
                      label: Text(note.label),
                      backgroundColor: note.isSustained
                          ? cs.secondaryContainer.withValues(alpha: 0.6)
                          : cs.primaryContainer,
                      labelStyle: TextStyle(
                        color: note.isSustained
                            ? cs.onSecondaryContainer.withValues(alpha: 0.8)
                            : cs.onPrimaryContainer,
                        fontWeight: note.isSustained
                            ? FontWeight.w500
                            : FontWeight.w600,
                      ),
                      side: note.isSustained
                          ? BorderSide(color: cs.outline.withValues(alpha: 0.5))
                          : BorderSide.none,
                    ),
                ],
              )
            else if (isPedalDown)
              // Show placeholder when pedal is down but no notes
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Pedal down, waiting for notes...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HomePortrait extends ConsumerWidget {
  // ignore: unused_element_parameter
  const _HomePortrait({super.key, required this.config});
  final HomeLayoutConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: AnalysisSection(config: config),
        ),
        SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ActiveInput(padding: config.activeInputPadding),
              TonalityBar(height: config.tonalityBarHeight),
              const Divider(height: 1),
              KeyboardSection(config: config),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeLandscape extends ConsumerWidget {
  // ignore: unused_element_parameter
  const _HomeLandscape({super.key, required this.config});
  final HomeLayoutConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 6, child: AnalysisSection(config: config)),
              Expanded(flex: 7, child: DetailsSection(config: config)),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TonalityBar(height: config.tonalityBarHeight),
              const Divider(height: 1),
              KeyboardSection(config: config),
            ],
          ),
        ),
      ],
    );
  }
}

class AnalysisSection extends ConsumerWidget {
  const AnalysisSection({super.key, required this.config});
  final HomeLayoutConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(chordAnalysisProvider);

    return Padding(
      padding: config.analysisPadding,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: config.chordCardMaxWidth),
            child: ChordCard(
              symbol: analysis.symbol,
              inversion: analysis.inversion,
            ),
          ),
        ),
      ),
    );
  }
}

class DetailsSection extends ConsumerWidget {
  const DetailsSection({super.key, required this.config});
  final HomeLayoutConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: config.detailsSectionPadding,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: ActiveInput(padding: config.activeInputPadding), // ⭐
      ),
    );
  }
}

class TonalityBar extends ConsumerWidget {
  const TonalityBar({super.key, required this.height});
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final selectedTonality = ref.watch(selectedTonalityProvider);
    final active = ref.watch(activeScaleDegreeProvider);

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

                  navigator.push(
                    ModalBottomSheetRoute(
                      builder: (_) => _TonalityPickerSheet(),
                      isScrollControlled: true,
                      showDragHandle: true,
                    ),
                  );
                },
                icon: const Icon(Icons.music_note),
                label: Text('Key: ${selectedTonality.displayName}'),
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
                  child: ScaleDegrees(active: active),
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
  const KeyboardSection({super.key, required this.config});
  final HomeLayoutConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMidiNotes = ref.watch(activeMidiNotesProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final whiteKeyWidth = width / config.whiteKeyCount;

        var height = whiteKeyWidth * config.whiteKeyAspectRatio;

        // Guardrails to prevent extremes.
        height = height.clamp(90.0, 200.0);

        return PianoKeyboard(
          whiteKeyCount: config.whiteKeyCount,
          firstMidiNote: config.firstMidiNote,
          activeMidiNotes: activeMidiNotes,
          height: height,
        );
      },
    );
  }
}

class _EdgeToEdgeController extends StatefulWidget {
  const _EdgeToEdgeController({required this.child, required this.isLandscape});

  final Widget child;
  final bool isLandscape;

  @override
  State<_EdgeToEdgeController> createState() => _EdgeToEdgeControllerState();
}

class _EdgeToEdgeControllerState extends State<_EdgeToEdgeController> {
  bool? _wasLandscape;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSystemUiMode(widget.isLandscape);
  }

  @override
  void didUpdateWidget(covariant _EdgeToEdgeController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLandscape != widget.isLandscape) {
      _updateSystemUiMode(widget.isLandscape);
    }
  }

  void _updateSystemUiMode(bool isLandscape) {
    if (_wasLandscape == isLandscape) return;
    _wasLandscape = isLandscape;

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

class _WakelockController extends ConsumerStatefulWidget {
  const _WakelockController({required this.child});

  final Widget child;

  @override
  ConsumerState<_WakelockController> createState() =>
      _WakelockControllerState();
}

class _WakelockControllerState extends ConsumerState<_WakelockController> {
  bool? _lastWakelockEnabled;

  @override
  void dispose() {
    // Safety: ensure wakelock is off when leaving this subtree.
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shouldEnableWakelock = ref.watch(
      midiConnectionProvider.select(
        (s) =>
            s.status == MidiConnectionStatus.connected ||
            s.status == MidiConnectionStatus.connecting,
      ),
    );

    if (_lastWakelockEnabled != shouldEnableWakelock) {
      _lastWakelockEnabled = shouldEnableWakelock;

      // Avoid doing platform work in the middle of the build pipeline.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        WakelockPlus.toggle(enable: shouldEnableWakelock);
      });
    }

    return widget.child;
  }
}

class MidiStatusPill extends ConsumerWidget {
  const MidiStatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(midiConnectionProvider.select((s) => s.status));
    final message = ref.watch(midiConnectionProvider.select((s) => s.message));

    final cs = Theme.of(context).colorScheme;

    final (label, bg, fg, border) = switch (status) {
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

    final tooltip = message?.trim().isNotEmpty == true
        ? '$label\n$message'
        : label;

    return Semantics(
      label: 'MIDI connection status. Tap to configure.',
      button: true,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const MidiSettingsPage()),
            );
          },
          borderRadius: BorderRadius.circular(999),
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
                  _MidiStatusDot(status: status, colorScheme: cs),
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

class ChordCard extends StatelessWidget {
  final ChordSymbol symbol;
  final String? inversion;

  const ChordCard({super.key, required this.symbol, required this.inversion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final hasInversion = inversion != null && inversion!.trim().isNotEmpty;

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
        TextSpan(text: symbol.root, style: rootStyle),
        if (symbol.quality.isNotEmpty) ...[
          const TextSpan(text: '\u200A'), // hair space
          TextSpan(text: symbol.quality),
        ],
        if (symbol.hasBass) ...[
          const TextSpan(text: ' / '),
          TextSpan(text: symbol.bass),
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
                      inversion!,
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

class ActiveInput extends ConsumerStatefulWidget {
  const ActiveInput({super.key, required this.padding});
  final EdgeInsets padding;

  @override
  ConsumerState<ActiveInput> createState() => _ActiveInputState();
}

class _ActiveInputState extends ConsumerState<ActiveInput> {
  final _listKey = GlobalKey<AnimatedListState>();
  late List<ActiveNote> _notes;
  late bool _pedal;
  ProviderSubscription<List<ActiveNote>>? _notesSub;
  ProviderSubscription<bool>? _pedalSub;

  @override
  void initState() {
    super.initState();

    _notes = ref.read(activeNotesProvider);
    _pedal = ref.read(isPedalDownProvider);

    _notesSub = ref.listenManual<List<ActiveNote>>(activeNotesProvider, (
      prev,
      next,
    ) {
      if (!mounted) return;
      _applyNotesDiff(next);
    });

    _pedalSub = ref.listenManual<bool>(isPedalDownProvider, (prev, next) {
      if (!mounted) return;
      setState(() => _pedal = next);
    });
  }

  @override
  void dispose() {
    _notesSub?.close();
    _pedalSub?.close();
    super.dispose();
  }

  void _applyNotesDiff(List<ActiveNote> next) {
    final nextIdSet = next.map((e) => e.id).toSet();
    final currentIdSet = _notes.map((e) => e.id).toSet();

    final nextById = <String, ActiveNote>{for (final n in next) n.id: n};

    // Remove notes that no longer exist
    for (int i = _notes.length - 1; i >= 0; i--) {
      final id = _notes[i].id;
      if (!nextIdSet.contains(id)) {
        final removed = _notes.removeAt(i);
        currentIdSet.remove(id);
        _listKey.currentState?.removeItem(
          // Offset by 1 if pedal is showing
          _pedal ? i + 1 : i,
          (context, animation) => _buildAnimatedNoteChip(removed, animation),
          duration: const Duration(milliseconds: 120),
        );
      }
    }

    // Insert new notes
    for (int i = 0; i < next.length; i++) {
      final id = next[i].id;
      if (!currentIdSet.contains(id)) {
        _notes.insert(i, next[i]);
        currentIdSet.add(id);
        _listKey.currentState?.insertItem(
          // Offset by 1 if pedal is showing
          _pedal ? i + 1 : i,
          duration: const Duration(milliseconds: 140),
        );
      }
    }

    // Update existing notes in-place (for pressed <-> sustained transitions)
    setState(() {
      for (int i = 0; i < _notes.length; i++) {
        final updated = nextById[_notes[i].id];
        if (updated != null) {
          _notes[i] = updated;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    const minHeight = 44.0;

    final showPrompt = _notes.isEmpty && !_pedal;

    return Padding(
      padding: widget.padding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minHeight),
        child: showPrompt
            ? Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Play some notes…',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              )
            : SizedBox(
                height: minHeight,
                child: AnimatedList(
                  key: _listKey,
                  initialItemCount: _pedal ? _notes.length + 1 : _notes.length,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index, animation) {
                    // Pedal always at index 0 when showing
                    if (_pedal && index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildAnimatedPedalIndicator(animation),
                      );
                    }

                    final noteIndex = _pedal ? index - 1 : index;
                    final note = _notes[noteIndex];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildAnimatedNoteChip(note, animation),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildAnimatedPedalIndicator(Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    return SizeTransition(
      sizeFactor: curved,
      axis: Axis.horizontal,
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.20, 0),
            end: Offset.zero,
          ).animate(curved),
          child: const PedalIndicator(key: ValueKey('sustain')),
        ),
      ),
    );
  }

  Widget _buildAnimatedNoteChip(ActiveNote note, Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    return SizeTransition(
      sizeFactor: curved,
      axis: Axis.horizontal,
      child: FadeTransition(
        opacity: curved,
        child: NoteChip(key: ValueKey(note.id), note: note),
      ),
    );
  }
}

class PedalIndicator extends StatelessWidget {
  const PedalIndicator({super.key});

  static const double slotWidth = 36;
  static const double glyphSize = 32;
  static const Offset opticalOffset = Offset(0, -3);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
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
    );
  }
}

class NoteChip extends ConsumerWidget {
  const NoteChip({super.key, required this.note});
  final ActiveNote note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final isPedalDown = ref.watch(isPedalDownProvider);

    final bgColor = cs.surfaceContainerLow;
    final fgColor = cs.onSurface;

    // Visual feedback for sustain state:
    // - Slightly darker borders when pedal is down
    // - Even darker/thicker borders for sustained notes
    final borderColor = note.isSustained
        ? cs.outlineVariant.withValues(alpha: 0.92)
        : cs.outlineVariant.withValues(alpha: isPedalDown ? 0.78 : 0.60);

    final borderWidth = note.isSustained ? 1.6 : 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        note.label,
        style: theme.textTheme.titleMedium?.copyWith(color: fgColor),
      ),
    );
  }
}

class ScaleDegrees extends StatelessWidget {
  final ScaleDegree? active;
  final values = ScaleDegree.values;

  const ScaleDegrees({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < values.length; i++) ...[
            _ScaleDegreeIndicator(
              label: values[i].romanNumeral,
              isActive: values[i] == active,
            ),
            if (i < values.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _ScaleDegreeIndicator extends StatelessWidget {
  final String label;
  final bool isActive;

  const _ScaleDegreeIndicator({required this.label, required this.isActive});

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

class _TonalityPickerSheet extends ConsumerStatefulWidget {
  const _TonalityPickerSheet();

  @override
  ConsumerState<_TonalityPickerSheet> createState() =>
      _TonalityPickerSheetState();
}

class _TonalityPickerSheetState extends ConsumerState<_TonalityPickerSheet> {
  static const _loopMultiplier = 200;

  static const double _rowHeight = 62.0;
  static const double _headerHeight = 46.0;
  static const double _chipWidth = 64.0;

  late final ScrollController _controller;
  late final List<KeySignature> _rows;

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
    final selected = ref.watch(selectedTonalityProvider);

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final selectedRowBg = Color.alphaBlend(
      cs.primary.withValues(alpha: 0.06),
      cs.surface,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;

        final didOrientationChange =
            _lastIsLandscape != null && _lastIsLandscape != isLandscape;

        _lastIsLandscape = isLandscape;

        if (didOrientationChange) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _centerSelectedRow();
          });
        }

        final mq = MediaQuery.of(context);

        // Always strip left/right for full-width expansion (existing, for full internal use of route space)
        final mqAdjusted = isLandscape
            ? mq.copyWith(
                padding: mq.padding.copyWith(left: 0, right: 0),
                viewPadding: mq.viewPadding.copyWith(left: 0, right: 0),
              )
            : mq;

        final screenHeight = mqAdjusted.size.height;
        final sheetHeight = isLandscape
            ? screenHeight // Full height in landscape
            : screenHeight * 0.42; // Roughly half height in portrait

        return MediaQuery(
          data: mqAdjusted,
          child: SafeArea(
            left: !isLandscape,
            right: !isLandscape,
            child: SizedBox(
              height: sheetHeight,
              child: CustomScrollView(
                controller: _controller,
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TonalityPickerHeaderDelegate(
                      extent: _headerHeight,
                      chipWidth: _chipWidth,
                      backgroundColor: cs.surfaceContainerLow,
                    ),
                  ),
                  SliverFixedExtentList(
                    itemExtent: _rowHeight,
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
                                        row.label,
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
                                        child: _TonalityChoiceChip(
                                          label: major.label,
                                          selected: majorSelected,
                                          onTap: () => _selectTonality(major),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: _chipWidth,
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: _TonalityChoiceChip(
                                          label: minor.label,
                                          selected: minorSelected,
                                          onTap: () => _selectTonality(minor),
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

  List<KeySignature> _buildOrderedRows() {
    KeySignature rowFor(int acc) =>
        keySignatureRows.firstWhere((r) => r.accidentalCount == acc);

    return <KeySignature>[
      for (var n = 7; n >= 1; n--) rowFor(n), // 7♯ … 1♯
      rowFor(0), // 0
      for (var n = 1; n <= 7; n++) rowFor(-n), // 1♭ … 7♭
    ];
  }

  int _baseIndexForSelected(Tonality selected) {
    final i = _rows.indexWhere(
      (row) => row.relativeMajor == selected || row.relativeMinor == selected,
    );
    if (i >= 0) return i;

    return _rows.indexWhere((row) => row.accidentalCount == 0);
  }

  void _centerSelectedRow() {
    if (!_controller.hasClients) return;

    final selected = ref.read(selectedTonalityProvider);
    final viewport = _controller.position.viewportDimension;

    final base = _baseIndexForSelected(selected);
    final middleStart = _rows.length * (_loopMultiplier ~/ 2);
    final selectedIndex = middleStart + base;

    final target =
        (selectedIndex * _rowHeight) - (viewport / 2) + (_rowHeight / 2);

    _controller.jumpTo(
      target.clamp(
        _controller.position.minScrollExtent,
        _controller.position.maxScrollExtent,
      ),
    );
  }

  void _selectTonality(Tonality tonality) {
    ref.read(selectedTonalityProvider.notifier).setTonality(tonality);
  }
}

class _TonalityChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TonalityChoiceChip({
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

class _TonalityPickerHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double extent;
  final double chipWidth;
  final Color backgroundColor;

  const _TonalityPickerHeaderDelegate({
    required this.extent,
    required this.chipWidth,
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
  bool shouldRebuild(covariant _TonalityPickerHeaderDelegate oldDelegate) {
    return oldDelegate.extent != extent ||
        oldDelegate.chipWidth != chipWidth ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

String _midiToNoteName(int midiNote) {
  const noteNames = [
    'C',
    'C♯',
    'D',
    'D♯',
    'E',
    'F',
    'F♯',
    'G',
    'G♯',
    'A',
    'A♯',
    'B',
  ];
  return noteNames[midiNote % 12];
}
