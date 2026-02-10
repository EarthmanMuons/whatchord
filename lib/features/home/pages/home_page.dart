import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/input/input.dart';
import 'package:whatchord/features/midi/midi.dart';
import 'package:whatchord/features/settings/settings.dart';

import '../models/home_layout_config.dart';
import '../widgets/analysis_section.dart';
import '../widgets/app_bar_title.dart';
import '../widgets/details_section.dart';
import '../widgets/edge_to_edge_controller.dart';
import '../widgets/keyboard_section.dart';
import '../widgets/tonality_bar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final ProviderSubscription<MidiConnectionState> _midiSub;

  @override
  void initState() {
    super.initState();

    _midiSub = ref.listenManual(midiConnectionStateProvider, (prev, next) {
      if (prev?.phase != MidiConnectionPhase.connected &&
          next.phase == MidiConnectionPhase.connected) {
        final name = next.device?.displayName;
        final text = name != null ? 'MIDI connected: $name' : 'MIDI connected';

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final mq = MediaQuery.of(context);
        final isLandscape = constraints.maxWidth > constraints.maxHeight;

        final config = isLandscape
            ? landscapeLayoutConfig
            : portraitLayoutConfig;

        final toolbarHeight = isLandscape ? 44.0 : kToolbarHeight;

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
              body: Column(
                children: [
                  ColoredBox(
                    color: cs.surfaceContainerLow,
                    child: SafeArea(
                      bottom: false, // only protect status bar
                      left: !isLandscape, // allow full-bleed in landscape
                      right: !isLandscape,
                      child: _HomeTopBar(
                        toolbarHeight: toolbarHeight,
                        isLandscape: isLandscape,
                        horizontalInset: horizontalInset,
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
                              isLandscape: true,
                              horizontalInset: horizontalInset,
                            )
                          : _HomePortrait(
                              config: config,
                              isLandscape: false,
                              horizontalInset: horizontalInset,
                            ),
                    ),
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
    required this.isLandscape,
    required this.horizontalInset,
  });

  final double toolbarHeight;
  final bool isLandscape;
  final double horizontalInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleLarge;

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
                  child: const AppBarTitle(),
                ),
              ),
              const SizedBox(width: 4),
              Transform.translate(
                offset: Offset(isLandscape ? 0 : settingsIconDx, 0),
                child: MidiStatusIcon(isLandscape: isLandscape),
              ),
              Transform.translate(
                offset: const Offset(settingsIconDx, 0),
                child: IconButton(
                  visualDensity: isLandscape
                      ? VisualDensity.compact
                      : VisualDensity.standard,
                  constraints: isLandscape
                      ? const BoxConstraints(minWidth: 40, minHeight: 40)
                      : const BoxConstraints(),
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
    required this.isLandscape,
    required this.horizontalInset,
  });
  final HomeLayoutConfig config;
  final bool isLandscape;
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
              Expanded(
                flex: 7,
                child: AnalysisSection(
                  config: config,
                  isLandscape: isLandscape,
                ),
              ),
              Expanded(
                flex: 6,
                child: DetailsSection(config: config, isLandscape: isLandscape),
              ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TonalityBar(
              height: config.tonalityBarHeight,
              horizontalInset: horizontalInset,
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
    required this.isLandscape,
    required this.horizontalInset,
  });
  final HomeLayoutConfig config;
  final bool isLandscape;
  final double horizontalInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: AnalysisSection(config: config, isLandscape: isLandscape),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InputDisplay(padding: config.inputDisplayPadding),
            TonalityBar(
              height: config.tonalityBarHeight,
              horizontalInset: horizontalInset,
            ),
            const Divider(height: 1),
            KeyboardSection(config: config),
          ],
        ),
      ],
    );
  }
}
