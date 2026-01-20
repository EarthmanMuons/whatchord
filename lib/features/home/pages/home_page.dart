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

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    // Initialize MIDI service and install lifecycle + reconnect behavior.
    ref.watch(midiServiceInitProvider);
    ref.watch(midiLifecycleObserverProvider);

    // Listen for connection state changes and show feedback.
    ref.listen(midiConnectionProvider, (prev, next) {
      if (prev?.phase == next.phase && prev?.message == next.message) return;

      final messenger = ScaffoldMessenger.of(context);

      void show(
        String text, {
        Color? bg,
        Color? fg,
        int seconds = 3,
        SnackBarAction? action,
      }) {
        final trimmed = text.trim();
        if (trimmed.isEmpty) return;

        // Prevent "spam"/re-show loops from feeling undismissable.
        messenger.hideCurrentSnackBar();

        messenger.showSnackBar(
          SnackBar(
            content: Text(trimmed),
            duration: Duration(seconds: seconds),
            action: action,
          ),
        );
      }

      // Connected (show once when transitioning into connected)
      if (prev?.phase != MidiConnectionPhase.connected &&
          next.phase == MidiConnectionPhase.connected) {
        final deviceName = next.device?.name;
        show(
          deviceName != null ? 'MIDI connected: $deviceName' : 'MIDI connected',
          bg: cs.primaryContainer,
          fg: cs.onPrimaryContainer,
          seconds: 2,
        );
        return;
      }

      // Device unavailable (show once when transitioning into unavailable)
      if (prev?.phase != MidiConnectionPhase.deviceUnavailable &&
          next.phase == MidiConnectionPhase.deviceUnavailable) {
        final msg = (next.message?.trim().isNotEmpty ?? false)
            ? next.message!.trim()
            : 'MIDI device unavailable';

        show(
          msg,
          bg: cs.surfaceContainerHighest,
          fg: cs.onSurface,
          seconds: 4,
          action: SnackBarAction(
            label: 'MIDI Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MidiSettingsPage(),
                ),
              );
            },
          ),
        );
        return;
      }

      // Bluetooth unavailable (show once per transition)
      if (prev?.phase != MidiConnectionPhase.bluetoothUnavailable &&
          next.phase == MidiConnectionPhase.bluetoothUnavailable) {
        show(
          next.message ?? 'Bluetooth unavailable',
          bg: cs.errorContainer,
          fg: cs.onErrorContainer,
          seconds: 5,
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
              );
            },
          ),
        );
        return;
      }

      // Error (show once per transition)
      if (prev?.phase != MidiConnectionPhase.error &&
          next.phase == MidiConnectionPhase.error) {
        show(
          next.message ?? 'MIDI error',
          bg: cs.errorContainer,
          fg: cs.onErrorContainer,
          seconds: 5,
          action: SnackBarAction(
            label: 'MIDI Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MidiSettingsPage(),
                ),
              );
            },
          ),
        );
        return;
      }

      // Disconnection toast (only if we were connected and now idle)
      if (prev?.phase == MidiConnectionPhase.connected &&
          (next.phase == MidiConnectionPhase.idle ||
              next.phase == MidiConnectionPhase.connecting ||
              next.phase == MidiConnectionPhase.retrying)) {
        show(
          'MIDI disconnected',
          bg: cs.surfaceContainerHighest,
          fg: cs.onSurface,
          seconds: 2,
        );
      }
    });

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
