import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/core.dart';
import 'package:whatchord/features/audio/audio.dart';
import 'package:whatchord/features/demo/demo.dart';
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
  Timer? _audioVolumeLabelDismissTimer;
  Timer? _volumeRepeatTimer;
  DateTime? _volumeRepeatStartedAt;

  static const int _volumeNudgeStepPercent = 5;
  static const int _volumeFastNudgeStepPercent = 10;
  static const Duration _volumeRepeatInterval = Duration(milliseconds: 100);
  static const Duration _volumeRepeatAccelerationDelay = Duration(
    milliseconds: 800,
  );

  @override
  void dispose() {
    _audioVolumeLabelDismissTimer?.cancel();
    _audioVolumeLabelDismissTimer = null;
    _stopVolumeRepeat();
    super.dispose();
  }

  void _showAudioVolumePercentLabel() {
    _audioVolumeLabelDismissTimer?.cancel();
    _audioVolumeLabelDismissTimer = null;
    if (_isAdjustingAudioVolume) return;
    setState(() => _isAdjustingAudioVolume = true);
  }

  void _scheduleAudioVolumePercentLabelDismiss() {
    _audioVolumeLabelDismissTimer?.cancel();
    _audioVolumeLabelDismissTimer = Timer(
      const Duration(milliseconds: 900),
      () {
        if (!mounted) return;
        setState(() => _isAdjustingAudioVolume = false);
      },
    );
  }

  void _adjustAudioVolumeByPercent(int deltaPercent) {
    final settings = ref.read(audioMonitorSettingsNotifier);
    if (!settings.enabled) return;
    _showAudioVolumePercentLabel();

    final notifier = ref.read(audioMonitorSettingsNotifier.notifier);
    final currentPercent = (settings.volume * 100).round();
    final nextPercent = (currentPercent + deltaPercent).clamp(0, 100);
    if (nextPercent == currentPercent) return;

    notifier.setVolume(nextPercent / 100);
    HapticFeedback.selectionClick();
  }

  void _startVolumeRepeat(int direction) {
    final settings = ref.read(audioMonitorSettingsNotifier);
    if (!settings.enabled) return;

    _stopVolumeRepeat();
    _volumeRepeatStartedAt = DateTime.now();
    _volumeRepeatTimer = Timer.periodic(_volumeRepeatInterval, (_) {
      final startedAt = _volumeRepeatStartedAt;
      if (startedAt == null) return;
      final elapsed = DateTime.now().difference(startedAt);
      final tickStep = elapsed >= _volumeRepeatAccelerationDelay
          ? _volumeFastNudgeStepPercent
          : _volumeNudgeStepPercent;
      _adjustAudioVolumeByPercent(direction * tickStep);
    });
  }

  void _stopVolumeRepeat() {
    _volumeRepeatTimer?.cancel();
    _volumeRepeatTimer = null;
    _volumeRepeatStartedAt = null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final chordNotationStyle = ref.watch(chordNotationStyleProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final palette = ref.watch(appPaletteProvider);
    final palettes = [...AppPalette.values]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final midiStatus = ref.watch(midiConnectionStatusProvider);
    final demoEnabled = ref.watch(demoModeProvider);
    final demoVariant = ref.watch(demoModeVariantProvider);
    final userDemoEnabled =
        demoEnabled && demoVariant == DemoModeVariant.interactive;
    final audioSettings = ref.watch(audioMonitorSettingsNotifier);
    final audioVolumePercent = (audioSettings.volume * 100).round();
    final disabledTextColor = cs.onSurface.withValues(alpha: 0.38);
    final disabledIconColor = cs.onSurfaceVariant.withValues(alpha: 0.38);
    final volumeLabelColor = audioSettings.enabled
        ? cs.onSurface
        : disabledTextColor;
    final volumeIconColor = audioSettings.enabled
        ? cs.onSurfaceVariant
        : disabledIconColor;

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
                title: const Text('Demo Mode'),
                subtitle: const Text(
                  'Explore chord examples without a MIDI device',
                ),
                value: userDemoEnabled,
                onChanged: (enabled) {
                  ref
                      .read(demoModeProvider.notifier)
                      .setEnabledFor(
                        enabled: enabled,
                        variant: DemoModeVariant.interactive,
                      );
                },
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
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Volume', style: TextStyle(color: volumeLabelColor)),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: _isAdjustingAudioVolume
                          ? Text(
                              ' $audioVolumePercent%',
                              style: TextStyle(color: volumeLabelColor),
                              key: ValueKey<int>(audioVolumePercent),
                            )
                          : const SizedBox.shrink(key: ValueKey<String>('off')),
                    ),
                  ],
                ),
                subtitle: Semantics(
                  container: true,
                  enabled: audioSettings.enabled,
                  child: SizedBox(
                    height: 48,
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.volume_mute_outlined,
                              color: volumeIconColor,
                            ),
                            Expanded(
                              child: Slider(
                                value: audioSettings.volume,
                                min: 0,
                                max: 1,
                                divisions: 100,
                                onChangeStart: audioSettings.enabled
                                    ? (_) => _showAudioVolumePercentLabel()
                                    : null,
                                onChangeEnd: audioSettings.enabled
                                    ? (_) =>
                                          _scheduleAudioVolumePercentLabelDismiss()
                                    : null,
                                onChanged: audioSettings.enabled
                                    ? (value) {
                                        _showAudioVolumePercentLabel();
                                        ref
                                            .read(
                                              audioMonitorSettingsNotifier
                                                  .notifier,
                                            )
                                            .setVolume(value);
                                      }
                                    : null,
                              ),
                            ),
                            Icon(
                              Icons.volume_up_outlined,
                              color: volumeIconColor,
                            ),
                          ],
                        ),
                        Positioned.fill(
                          child: Row(
                            children: [
                              _VolumeNudgeHitTarget(
                                semanticsLabel: 'Decrease volume',
                                enabled: audioSettings.enabled,
                                onTap: () {
                                  _adjustAudioVolumeByPercent(
                                    -_volumeNudgeStepPercent,
                                  );
                                  _scheduleAudioVolumePercentLabelDismiss();
                                },
                                onLongPressStart: () {
                                  _showAudioVolumePercentLabel();
                                  _startVolumeRepeat(-1);
                                },
                                onLongPressEnd: () {
                                  _stopVolumeRepeat();
                                  _scheduleAudioVolumePercentLabelDismiss();
                                },
                              ),
                              const Expanded(child: SizedBox()),
                              _VolumeNudgeHitTarget(
                                semanticsLabel: 'Increase volume',
                                enabled: audioSettings.enabled,
                                onTap: () {
                                  _adjustAudioVolumeByPercent(
                                    _volumeNudgeStepPercent,
                                  );
                                  _scheduleAudioVolumePercentLabelDismiss();
                                },
                                onLongPressStart: () {
                                  _showAudioVolumePercentLabel();
                                  _startVolumeRepeat(1);
                                },
                                onLongPressEnd: () {
                                  _stopVolumeRepeat();
                                  _scheduleAudioVolumePercentLabelDismiss();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

class _VolumeNudgeHitTarget extends StatelessWidget {
  const _VolumeNudgeHitTarget({
    required this.semanticsLabel,
    required this.enabled,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  final String semanticsLabel;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      enabled: enabled,
      onTap: enabled ? onTap : null,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: enabled ? onTap : null,
        onLongPressStart: enabled ? (_) => onLongPressStart() : null,
        onLongPressEnd: enabled ? (_) => onLongPressEnd() : null,
        onLongPressCancel: enabled ? onLongPressEnd : null,
        child: const SizedBox(width: 48, height: 48),
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
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: panelColor,
      builder: (context) {
        final mq = MediaQuery.of(context);
        final isLandscape = mq.size.width > mq.size.height;
        final maxSheetHeight = modalBottomSheetMaxHeight(context);

        return ColoredBox(
          color: panelColor,
          child: SafeArea(
            top: false,
            left: !isLandscape,
            right: !isLandscape,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxSheetHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ModalPanelHeader(title: title),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 1),
                  ),
                  Flexible(child: builder(context)),
                ],
              ),
            ),
          ),
        );
      },
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
                ModalPanelHeader(title: title, showCloseButton: true),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1),
                ),
                Flexible(child: builder(context)),
              ],
            ),
          ),
        ),
      );
    },
  );
}
