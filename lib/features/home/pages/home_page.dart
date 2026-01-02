import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/core/widgets/widgets.dart';
import 'package:what_chord/features/midi/midi.dart';
import 'package:what_chord/features/piano/piano.dart';
import 'package:what_chord/features/settings/settings.dart';

import '../models/home_layout_config.dart';
import '../widgets/sections/analysis_section.dart';
import '../widgets/sections/details_section.dart';
import '../widgets/sections/keyboard_section.dart';
import '../widgets/sections/tonality_bar.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    // Initialize MIDI service and install lifecycle + reconnect behavior.
    ref.watch(midiServiceInitProvider);
    ref.watch(midiLifecycleControllerProvider);

    // Listen for connection state changes and show feedback.
    ref.listen(midiLinkManagerProvider, (prev, next) {
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
      if (prev?.phase != MidiLinkPhase.connected &&
          next.phase == MidiLinkPhase.connected) {
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
      if (prev?.phase != MidiLinkPhase.deviceUnavailable &&
          next.phase == MidiLinkPhase.deviceUnavailable) {
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
      if (prev?.phase != MidiLinkPhase.bluetoothUnavailable &&
          next.phase == MidiLinkPhase.bluetoothUnavailable) {
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
      if (prev?.phase != MidiLinkPhase.error &&
          next.phase == MidiLinkPhase.error) {
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

      // Optional: disconnection toast (only if we were connected and now idle)
      if (prev?.phase == MidiLinkPhase.connected &&
          (next.phase == MidiLinkPhase.idle ||
              next.phase == MidiLinkPhase.connecting ||
              next.phase == MidiLinkPhase.retrying)) {
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
