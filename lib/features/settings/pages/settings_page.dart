import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:what_chord/core/theme/theme.dart';
import 'package:what_chord/core/utils/utils.dart';
import 'package:what_chord/core/widgets/widgets.dart';
import 'package:what_chord/features/midi/midi.dart';
import 'package:what_chord/features/theory/theory.dart';

import '../services/settings_reset_service.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    final chordNotationStyle = ref.watch(chordNotationStyleProvider);
    final themeMode = ref.watch(themeModeProvider);
    final palette = ref.watch(appPaletteProvider);
    final palettes = [...AppPalette.values]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final connection = ref.watch(midiConnectionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: cs.surfaceContainerLow,
        foregroundColor: cs.onSurface,
        scrolledUnderElevation: 0,
      ),
      body: Scrollbar(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            const SectionHeader(title: 'Input', icon: Icons.piano),

            ListTile(
              title: const Text('MIDI settings'),
              subtitle: Text(connection.detail ?? connection.label),
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
            const SectionHeader(
              title: 'Chord Display Options',
              icon: Icons.queue_music_outlined,
            ),

            const SubsectionLabel(title: 'Notation Style'),
            RadioGroup<ChordNotationStyle>(
              groupValue: chordNotationStyle,
              onChanged: (ChordNotationStyle? style) {
                if (style == null) return;
                ref.read(chordNotationStyleProvider.notifier).setStyle(style);
              },
              child: const Column(
                children: [
                  RadioListTile<ChordNotationStyle>(
                    title: Text('Textual'),
                    subtitle: Text('E.g., Cmaj7, F#m7b5'),
                    value: ChordNotationStyle.textual,
                  ),
                  RadioListTile<ChordNotationStyle>(
                    title: Text('Symbolic'),
                    subtitle: Text('E.g., CΔ7, F#ø7'),
                    value: ChordNotationStyle.symbolic,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const SectionHeader(
              title: 'Appearance',
              icon: Icons.palette_outlined,
            ),

            const SubsectionLabel(title: 'Theme'),
            const SizedBox(height: 8),

            SegmentedButton<ThemeMode>(
              segments: const <ButtonSegment<ThemeMode>>[
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.settings_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: <ThemeMode>{themeMode},
              onSelectionChanged: (selection) {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(selection.first);
              },
            ),

            const SizedBox(height: 8),
            ListTile(
              leading: PaletteSwatch(palette: palette),
              title: const Text('Color Palette'),
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
                          for (final p in palettes)
                            ListTile(
                              tileColor: p == current
                                  ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withValues(alpha: 0.35)
                                  : null,
                              leading: PaletteSwatch(palette: p),
                              title: Text(p.label),
                              trailing: p == current
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
                    data: (v) => Text('Version $v'),
                    loading: () => const Text('Version —'),
                    error: (_, _) => const Text('Version unavailable'),
                  ),
              onLongPress: () async {
                final version = ref
                    .read(appVersionProvider)
                    .maybeWhen(
                      data: (v) => 'WhatChord v$v',
                      orElse: () => null,
                    );

                if (version == null) return;

                await Clipboard.setData(ClipboardData(text: version));
                HapticFeedback.selectionClick();
              },
            ),

            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Source Code'),
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
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: const Text('Reset to Defaults'),
              subtitle: const Text(
                'Clears all saved preferences and MIDI settings.',
              ),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset all settings?'),
                    content: const Text(
                      'This will restore all preferences and MIDI settings to their default values. '
                      'Any connected MIDI devices will be disconnected. '
                      'This action can’t be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) return;

                await ref.read(settingsResetProvider).resetAllToDefaults();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings reset to defaults')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
