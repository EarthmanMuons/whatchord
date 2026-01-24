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
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final config = isLandscape
            ? landscapeLayoutConfig
            : portraitLayoutConfig;

        // Single knob for horizontal insets used by the app bar + tonality bar.
        final pageInset = isLandscape ? 58.0 : 16.0;

        final mq = MediaQuery.of(context);
        final mqFullWidth = isLandscape
            ? mq.copyWith(
                padding: mq.padding.copyWith(left: 0, right: 0),
                viewPadding: mq.viewPadding.copyWith(left: 0, right: 0),
              )
            : mq;

        return MediaQuery(
          data: mqFullWidth,
          child: EdgeToEdgeController(
            isLandscape: isLandscape,
            child: WakelockController(
              child: Scaffold(
                appBar: AppBar(
                  centerTitle: false,
                  titleSpacing: pageInset,
                  title: const AppBarTitle(),
                  backgroundColor: cs.surfaceContainerLow,
                  foregroundColor: cs.onSurface,
                  actions: [
                    Padding(
                      padding: EdgeInsets.only(right: pageInset - 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const MidiStatusPill(),
                          IconButton(
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
                        ],
                      ),
                    ),
                  ],
                ),
                body: SafeArea(
                  child: isLandscape
                      ? _HomeLandscape(
                          config: config,
                          isLandscape: true,
                          pageInset: pageInset,
                        )
                      : _HomePortrait(
                          config: config,
                          isLandscape: false,
                          pageInset: pageInset,
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

class _HomeLandscape extends ConsumerWidget {
  const _HomeLandscape({
    // ignore: unused_element_parameter
    super.key,
    required this.config,
    required this.isLandscape,
    required this.pageInset,
  });
  final HomeLayoutConfig config;
  final bool isLandscape;
  final double pageInset;

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
        SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TonalityBar(
                height: config.tonalityBarHeight,
                horizontalInset: pageInset,
              ),
              const Divider(height: 1),
              KeyboardSection(config: config),
            ],
          ),
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
    required this.pageInset,
  });
  final HomeLayoutConfig config;
  final bool isLandscape;
  final double pageInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: AnalysisSection(config: config, isLandscape: isLandscape),
        ),
        SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ActiveInput(padding: config.activeInputPadding),
              TonalityBar(
                height: config.tonalityBarHeight,
                horizontalInset: pageInset,
              ),
              const Divider(height: 1),
              KeyboardSection(config: config),
            ],
          ),
        ),
      ],
    );
  }
}
