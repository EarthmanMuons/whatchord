import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/midi/midi.dart';
import 'package:whatchord/features/piano/piano.dart';
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
  @override
  void initState() {
    super.initState();

    ref.listenManual(midiConnectionProvider, (prev, next) {
      // Show once when transitioning into connected
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
        final iconSize = isLandscape ? 20.0 : 24.0;

        final appBarPadLeft = isLandscape ? 24.0 : 16.0;
        final appBarPadRight = isLandscape ? 16.0 : 0.0;

        const tonalityPadBase = 16.0;
        const tonalityPadCutout = 12.0;

        final leftCutout = isLandscape ? mq.viewPadding.left : 0.0;
        final rightCutout = isLandscape ? mq.viewPadding.right : 0.0;

        final insetLeft =
            tonalityPadBase +
            (leftCutout > 0 ? leftCutout + tonalityPadCutout : 0);
        final insetRight =
            tonalityPadBase +
            (rightCutout > 0 ? rightCutout + tonalityPadCutout : 0);

        return EdgeToEdgeController(
          child: WakelockController(
            child: Scaffold(
              appBar: AppBar(
                toolbarHeight: toolbarHeight,
                centerTitle: false,
                automaticallyImplyLeading: false,
                titleSpacing: 0,
                title: Padding(
                  padding: EdgeInsets.only(left: appBarPadLeft),
                  child: const AppBarTitle(),
                ),
                backgroundColor: cs.surfaceContainerLow,
                foregroundColor: cs.onSurface,
                actionsIconTheme: IconThemeData(size: iconSize),
                actions: [
                  Padding(
                    padding: EdgeInsets.only(right: appBarPadRight),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const MidiStatusPill(),
                        IconButton(
                          visualDensity: isLandscape
                              ? VisualDensity.compact
                              : VisualDensity.standard,
                          constraints: isLandscape
                              ? const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                )
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
                      ],
                    ),
                  ),
                ],
              ),
              body: SafeArea(
                bottom: false, // piano draws to bottom
                left: !isLandscape, // allow full-bleed in landscape
                right: !isLandscape,
                child: isLandscape
                    ? _HomeLandscape(
                        config: config,
                        isLandscape: true,
                        insetLeft: insetLeft,
                        insetRight: insetRight,
                      )
                    : _HomePortrait(
                        config: config,
                        isLandscape: false,
                        insetLeft: insetLeft,
                        insetRight: insetRight,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeLandscape extends ConsumerWidget {
  const _HomeLandscape({
    // ignore: unused_element_parameter
    super.key,
    required this.config,
    required this.isLandscape,
    required this.insetLeft,
    required this.insetRight,
  });
  final HomeLayoutConfig config;
  final bool isLandscape;
  final double insetLeft;
  final double insetRight;

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
              height: config.tonalityBarHeight * 0.85,
              insetLeft: insetLeft,
              insetRight: insetRight,
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
    required this.insetLeft,
    required this.insetRight,
  });
  final HomeLayoutConfig config;
  final bool isLandscape;
  final double insetLeft;
  final double insetRight;

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
            ActiveInput(padding: config.activeInputPadding),
            TonalityBar(
              height: config.tonalityBarHeight,
              insetLeft: insetLeft,
              insetRight: insetRight,
            ),
            const Divider(height: 1),
            KeyboardSection(config: config),
          ],
        ),
      ],
    );
  }
}
