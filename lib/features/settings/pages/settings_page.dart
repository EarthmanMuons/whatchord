import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/core.dart';
import 'package:whatchord/features/audio/audio.dart';
import 'package:whatchord/features/midi/midi.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../services/settings_reset_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isAdjustingAudioVolume = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final chordNotationStyle = ref.watch(chordNotationStyleProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final palette = ref.watch(appPaletteProvider);
    final palettes = [...AppPalette.values]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final midiStatus = ref.watch(midiConnectionStatusProvider);
    final audioSettings = ref.watch(audioMonitorSettingsNotifier);
    final audioVolumePercent = (audioSettings.volume * 100).round();
    final volumeIconColor = audioSettings.enabled
        ? cs.onSurfaceVariant
        : Theme.of(context).disabledColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: cs.surfaceContainerLow,
        foregroundColor: cs.onSurface,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Scrollbar(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              const SectionHeader(title: 'Input', icon: Icons.piano),

              Semantics(
                onTapHint: 'Open MIDI settings',
                child: ListTile(
                  title: const Text('MIDI Settings'),
                  subtitle: Text(midiStatus.subtitle ?? midiStatus.title),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MidiSettingsPage(),
                      ),
                    );
                  },
                ),
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Audio Monitor'),
                subtitle: const Text('Plays a piano sound from incoming MIDI'),
                value: audioSettings.enabled,
                onChanged: (enabled) {
                  ref
                      .read(audioMonitorSettingsNotifier.notifier)
                      .setEnabled(enabled);
                },
              ),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _isAdjustingAudioVolume
                      ? 'Volume $audioVolumePercent%'
                      : 'Volume',
                ),
                subtitle: Semantics(
                  label: 'Audio Monitor volume',
                  value: '$audioVolumePercent percent',
                  child: Row(
                    children: [
                      Icon(Icons.volume_mute_outlined, color: volumeIconColor),
                      Expanded(
                        child: Slider(
                          value: audioSettings.volume,
                          min: 0,
                          max: 1,
                          divisions: 100,
                          onChangeStart: audioSettings.enabled
                              ? (_) => setState(
                                  () => _isAdjustingAudioVolume = true,
                                )
                              : null,
                          onChangeEnd: audioSettings.enabled
                              ? (_) => setState(
                                  () => _isAdjustingAudioVolume = false,
                                )
                              : null,
                          onChanged: audioSettings.enabled
                              ? (value) {
                                  ref
                                      .read(
                                        audioMonitorSettingsNotifier.notifier,
                                      )
                                      .setVolume(value);
                                }
                              : null,
                        ),
                      ),
                      Icon(Icons.volume_up_outlined, color: volumeIconColor),
                    ],
                  ),
                ),
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
                      .read(appThemeModeProvider.notifier)
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
                  await showAdaptiveSelectionSheet<void>(
                    context: context,
                    title: 'Color Palette',
                    builder: (context) {
                      return _PaletteSelectionList(palettes: palettes);
                    },
                  );
                },
              ),

              const SizedBox(height: 16),
              const SectionHeader(title: 'About'),
              Semantics(
                onLongPressHint: 'Copy app version to clipboard',
                child: ListTile(
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
                    final version = ref.read(appVersionProvider).asData?.value;
                    if (version == null) return;

                    final messenger = Platform.isIOS
                        ? ScaffoldMessenger.maybeOf(context)
                        : null;

                    await Clipboard.setData(
                      ClipboardData(text: 'WhatChord v$version'),
                    );

                    messenger?.hideCurrentSnackBar();
                    messenger?.showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                ),
              ),

              Semantics(
                onTapHint: 'Open support page in browser',
                child: ListTile(
                  leading: const Icon(Icons.support_agent_outlined),
                  title: const Text('Support'),
                  subtitle: const Text('Report an issue or contact support'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    openUrl(
                      context,
                      Uri.parse(
                        'https://github.com/EarthmanMuons/whatchord/blob/main/SUPPORT.md',
                      ),
                    );
                  },
                ),
              ),

              Semantics(
                onTapHint: 'Open GitHub repository in browser',
                child: ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Source Code'),
                  subtitle: const Text('Browse the repository on GitHub'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    openUrl(
                      context,
                      Uri.parse('https://github.com/EarthmanMuons/whatchord'),
                    );
                  },
                ),
              ),

              Semantics(
                onTapHint: 'Open privacy policy in browser',
                child: ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('No data collected'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    openUrl(
                      context,
                      Uri.parse(
                        'https://github.com/EarthmanMuons/whatchord/blob/main/PRIVACY.md',
                      ),
                    );
                  },
                ),
              ),

              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: const Text('Reset to Defaults'),
                subtitle: const Text(
                  'Clear all saved preferences, MIDI settings, and audio monitor settings',
                ),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Reset all settings?'),
                      content: const Text(
                        'This will restore all preferences, MIDI settings, and audio monitor settings to their default values. '
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
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onError,
                          ),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;

                  await ref.read(settingsResetProvider).resetAllToDefaults();

                  if (context.mounted) {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings reset to defaults'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteSelectionList extends ConsumerWidget {
  const _PaletteSelectionList({required this.palettes});

  final List<AppPalette> palettes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(appPaletteProvider);
    final cs = Theme.of(context).colorScheme;
    final selectedRowColor = cs.primaryContainer.withValues(alpha: 0.55);

    return ListView(
      shrinkWrap: true,
      children: [
        for (final p in palettes)
          Semantics(
            container: true,
            button: true,
            selected: p == current,
            label: '${p.label} palette',
            onTapHint: 'Apply color palette',
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: p == current ? selectedRowColor : Colors.transparent,
                ),
                child: ListTile(
                  selected: p == current,
                  selectedColor: cs.onSurface,
                  textColor: cs.onSurface,
                  iconColor: cs.onSurfaceVariant,
                  leading: PaletteSwatch(palette: p),
                  title: Text(p.label),
                  trailing: p == current
                      ? Icon(Icons.check, color: cs.primary)
                      : null,
                  onTap: () =>
                      ref.read(appPaletteProvider.notifier).setPalette(p),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Future<T?> showAdaptiveSelectionSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required String title,
}) {
  final panelColor = Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF151515)
      : const Color(0xFFF4F4F4);

  final shortestSide = MediaQuery.sizeOf(context).shortestSide;
  final isCompact = shortestSide < 600;

  if (isCompact) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      backgroundColor: panelColor,
      builder: (context) => ColoredBox(
        color: panelColor,
        child: SafeArea(child: builder(context)),
      ),
    );
  }

  final maxDialogHeight = MediaQuery.sizeOf(context).height * 0.72;

  return showDialog<T>(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 440,
            maxHeight: maxDialogHeight,
          ),
          child: Material(
            color: panelColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 60,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Flexible(child: builder(context)),
              ],
            ),
          ),
        ),
      );
    },
  );
}
