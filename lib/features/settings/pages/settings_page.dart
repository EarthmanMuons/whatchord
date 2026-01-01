import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:what_chord/core/theme/theme.dart';
import 'package:what_chord/core/utils/utils.dart';
import 'package:what_chord/core/widgets/widgets.dart';
import 'package:what_chord/features/midi/midi.dart';
import 'package:what_chord/features/theory/theory.dart';

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
          const SectionHeader(title: 'Input'),
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
          const SectionHeader(title: 'Chord display'),
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
          const SectionHeader(title: 'Appearance'),
          const SubsectionLabel(title: 'Theme'),
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
          const SubsectionLabel(title: 'Color palette'),
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
          const SectionHeader(title: 'About'),
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
    final ui = ref.watch(midiUiStatusProvider);
    return Text(ui.detail ?? ui.label);
  }
}
