import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/demo/demo.dart';
import 'package:whatchord/features/input/input.dart';
import 'package:whatchord/features/midi/midi.dart';
import 'package:whatchord/features/onboarding/onboarding.dart';
import 'package:whatchord/features/settings/settings.dart';

import '../models/home_layout_config.dart';
import '../widgets/analysis_section.dart';
import '../widgets/app_bar_title.dart';
import '../widgets/demo_mode_explanation.dart';
import '../widgets/details_section.dart';
import '../widgets/edge_to_edge_controller.dart';
import '../widgets/keyboard_section.dart';
import '../widgets/tonality_bar.dart';

const _tonalityBarHeight = kToolbarHeight;

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final ProviderSubscription<MidiConnectionState> _midiSub;
  final GlobalKey _midiStatusIconKey = GlobalKey(debugLabel: 'midiStatusIcon');

  @override
  void initState() {
    super.initState();

    _midiSub = ref.listenManual(midiConnectionStateProvider, (prev, next) {
      if (!mounted) return;
      if (prev?.phase != MidiConnectionPhase.connected &&
          next.phase == MidiConnectionPhase.connected) {
        final demoEnabled = ref.read(demoModeProvider);
        final demoVariant = ref.read(demoModeVariantProvider);
        final disableInteractiveDemo =
            demoEnabled && demoVariant == DemoModeVariant.interactive;
        if (disableInteractiveDemo) {
          ref
              .read(demoModeProvider.notifier)
              .setEnabledFor(
                enabled: false,
                variant: DemoModeVariant.interactive,
              );
        }

        final name = next.device?.displayName;
        final baseText = name != null
            ? 'MIDI connected: $name'
            : 'MIDI connected';
        final text = disableInteractiveDemo
            ? '$baseText\nDemo Mode disabled'
            : baseText;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text)));
      }
    });
  }

  @override
  void dispose() {
    _midiSub.close();
    super.dispose();
  }

  void _openMidiSettings() {
    unawaited(ref.read(midiSettingsOnboardingProvider.notifier).markSeen());
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MidiSettingsPage()));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final mq = MediaQuery.of(context);
        final config = resolveHomeLayoutConfig(constraints);
        final isLandscape = config.isLandscape;

        final toolbarHeight = kToolbarHeight;

        const barBaseInset = 16.0;
        final maxHorizontalCutout = isLandscape
            ? math.max(mq.viewPadding.left, mq.viewPadding.right)
            : 0.0;

        // Symmetric rail inset for top bar and tonality bar.
        // In landscape we draw full-bleed horizontally, so we add the largest system cutout inset.
        final horizontalInset = barBaseInset + maxHorizontalCutout;

        return EdgeToEdgeController(
          child: WakelockController(
            child: Scaffold(
              body: Stack(
                children: [
                  Column(
                    children: [
                      ColoredBox(
                        color: cs.surfaceContainerLow,
                        child: SafeArea(
                          bottom: false, // only protect status bar
                          left: !isLandscape, // allow full-bleed in landscape
                          right: !isLandscape,
                          child: _HomeTopBar(
                            toolbarHeight: toolbarHeight,
                            horizontalInset: horizontalInset,
                            midiStatusIconKey: _midiStatusIconKey,
                            onOpenMidiSettings: _openMidiSettings,
                          ),
                        ),
                      ),

                      Expanded(
                        child: SafeArea(
                          top: false, // already handled above
                          bottom: false, // piano draws to bottom
                          left: !isLandscape,
                          right: !isLandscape,
                          child: isLandscape
                              ? _HomeLandscape(
                                  config: config,
                                  horizontalInset: horizontalInset,
                                )
                              : _HomePortrait(
                                  config: config,
                                  horizontalInset: horizontalInset,
                                ),
                        ),
                      ),
                    ],
                  ),
                  MidiIconOnboardingOverlay(
                    targetKey: _midiStatusIconKey,
                    onTargetTap: _openMidiSettings,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeTopBar extends ConsumerWidget {
  const _HomeTopBar({
    required this.toolbarHeight,
    required this.horizontalInset,
    required this.midiStatusIconKey,
    required this.onOpenMidiSettings,
  });

  final double toolbarHeight;
  final double horizontalInset;
  final GlobalKey midiStatusIconKey;
  final VoidCallback onOpenMidiSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleLarge;
    final demoEnabled = ref.watch(demoModeProvider);
    final demoVariant = ref.watch(demoModeVariantProvider);
    final showInteractiveDemoPill =
        demoEnabled && demoVariant == DemoModeVariant.interactive;

    // Optical-only tweak.
    const settingsIconDx = 6.0;

    return Material(
      color: cs.surfaceContainerLow,
      child: SizedBox(
        height: toolbarHeight,
        child: Padding(
          padding: EdgeInsets.only(
            left: horizontalInset,
            right: horizontalInset,
          ),
          child: Row(
            children: [
              Expanded(
                child: DefaultTextStyle(
                  style: titleStyle!,
                  child: AppBarTitle(maxHeight: toolbarHeight),
                ),
              ),
              if (showInteractiveDemoPill)
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 16),
                  child: _DemoModePill(
                    onPressed: () {
                      ref
                          .read(demoModeProvider.notifier)
                          .setEnabledFor(enabled: false, variant: demoVariant);
                    },
                  ),
                ),
              const SizedBox(width: 4),
              MidiStatusIcon(
                iconButtonKey: midiStatusIconKey,
                onPressed: onOpenMidiSettings,
              ),
              Transform.translate(
                offset: const Offset(settingsIconDx, 0),
                child: IconButton(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(Icons.settings),
                  tooltip: 'Settings',
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
        ),
      ),
    );
  }
}

class _HomeLandscape extends ConsumerWidget {
  const _HomeLandscape({
    // ignore: unused_element_parameter
    super.key,
    required this.config,
    required this.horizontalInset,
  });
  final HomeLayoutConfig config;
  final double horizontalInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 7, child: AnalysisSection(config: config)),
              Expanded(flex: 6, child: DetailsSection(config: config)),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TonalityBar(
              height: _tonalityBarHeight,
              horizontalInset: horizontalInset,
              keyTextScaleMultiplier: config.tonalityButtonTextScale,
              scaleDegreesTextScaleMultiplier: config.scaleDegreesTextScale,
            ),
            const Divider(height: 1),
            KeyboardSection(config: config),
          ],
        ),
      ],
    );
  }
}

class _HomePortrait extends ConsumerWidget {
  const _HomePortrait({
    // ignore: unused_element_parameter
    super.key,
    required this.config,
    required this.horizontalInset,
  });
  final HomeLayoutConfig config;
  final double horizontalInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: AnalysisSection(config: config),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DemoModeExplanation(),
            InputDisplay(
              padding: config.inputDisplayPadding,
              visualScaleMultiplier: config.inputDisplayVisualScale,
            ),
            TonalityBar(
              height: _tonalityBarHeight,
              horizontalInset: horizontalInset,
              keyTextScaleMultiplier: config.tonalityButtonTextScale,
              scaleDegreesTextScaleMultiplier: config.scaleDegreesTextScale,
            ),
            const Divider(height: 1),
            KeyboardSection(config: config),
          ],
        ),
      ],
    );
  }
}

class _DemoModePill extends StatelessWidget {
  const _DemoModePill({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontSize: 13,
      letterSpacing: 0.25,
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
    );
    final scaler = TextScaler.linear(
      MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.35),
    );

    return Tooltip(
      message: 'Turn off demo mode',
      child: ActionChip(
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: cs.surface,
        side: BorderSide(color: cs.outlineVariant),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        label: Text('DEMO', textScaler: scaler, style: textStyle),
      ),
    );
  }
}
