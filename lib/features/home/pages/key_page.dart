import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/core.dart';
import 'package:whatchord/features/input/input.dart';
import 'package:whatchord/features/key/key.dart';
import 'package:whatchord/features/midi/midi.dart';
import 'package:whatchord/features/settings/settings.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../models/home_layout_config.dart';
import '../widgets/resizable_keyboard_area.dart';

/// The key page: manual key-signature selection and the auto-detected key,
/// as one surface with the live keyboard below, so the detector can be
/// watched while playing (Phase 2 integration spec).
class KeyPage extends ConsumerWidget {
  const KeyPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const KeyPage());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(keyModeProvider);
    final liveNotes = ref.watch(liveSoundingNoteNumbersProvider);
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final mq = MediaQuery.of(context);
        final config = resolveHomeLayoutConfig(constraints);
        final isLandscape = config.isLandscape;

        final toolbarHeight = config.tightenForStatusBar
            ? kAndroidLandscapeToolbarHeight
            : kToolbarHeight;
        final toolbarBottomInset = config.tightenForStatusBar
            ? kAndroidLandscapeToolbarBottomInset
            : 0.0;

        const barBaseInset = 16.0;
        final maxHorizontalCutout = isLandscape
            ? math.max(mq.viewPadding.left, mq.viewPadding.right)
            : 0.0;
        final horizontalInset = barBaseInset + maxHorizontalCutout;

        return Scaffold(
          body: Column(
            children: [
              ColoredBox(
                color: cs.surfaceContainerLow,
                child: SafeArea(
                  bottom: false,
                  left: !isLandscape,
                  right: !isLandscape,
                  child: _KeyTopBar(
                    toolbarHeight: toolbarHeight,
                    contentBottomInset: toolbarBottomInset,
                    horizontalInset: horizontalInset,
                  ),
                ),
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  bottom: false,
                  left: !isLandscape,
                  right: !isLandscape,
                  child: LayoutBuilder(
                    builder: (context, bodyConstraints) {
                      return Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalInset,
                              12,
                              horizontalInset,
                              12,
                            ),
                            child: _ModeSegments(mode: mode),
                          ),
                          Expanded(
                            child: mode == KeyMode.auto
                                ? _AutoPane(
                                    isLandscape: isLandscape,
                                    horizontalInset: horizontalInset,
                                  )
                                : const TonalityPickerBody(),
                          ),
                          ResizableKeyboardArea(
                            config: config,
                            maxKeyboardHeight: maxKeyboardHeightForLayout(
                              availableHeight: bodyConstraints.maxHeight,
                              isLandscape: isLandscape,
                              reservedChrome:
                                  kToolbarHeight +
                                  (isLandscape
                                      ? 1
                                      : kPianoSeparatorLineHeight + 1),
                            ),
                            highlightedNotes: liveNotes,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModeSegments extends ConsumerWidget {
  const _ModeSegments({required this.mode});

  final KeyMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<KeyMode>(
      segments: const [
        ButtonSegment(
          value: KeyMode.manual,
          label: Text('Manual'),
          icon: Icon(Icons.music_note),
        ),
        ButtonSegment(
          value: KeyMode.auto,
          label: Text('Auto'),
          icon: Icon(Icons.hdr_auto),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (selection) => unawaited(
        ref.read(keyModeProvider.notifier).setMode(selection.first),
      ),
    );
  }
}

class _AutoPane extends ConsumerWidget {
  const _AutoPane({required this.isLandscape, required this.horizontalInset});

  final bool isLandscape;
  final double horizontalInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inferred = ref.watch(inferredKeyProvider);

    // Landscape has no room for the wheel; the strip is the circle of fifths
    // unrolled, keeping the same adjacency story in a short wide band.
    if (isLandscape) {
      return FadedScrollView(
        padding: EdgeInsets.fromLTRB(horizontalInset, 0, horizontalInset, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AutoKeyStatus(),
            const SizedBox(height: 12),
            KeyPosteriorStrip(
              ranked: inferred.ranked,
              claim: inferred.displayKey?.tonality,
            ),
            const SizedBox(height: 12),
            const RecentChordsStrip(),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Shrink the wheel before letting it hide behind the keyboard: leave
        // room for the status header and the recent-chords strip, and fall
        // back to scrolling only below the wheel's readable minimum.
        const surroundingContent = 220.0;
        final wheelSize = math
            .min(
              constraints.maxWidth - 2 * horizontalInset,
              constraints.maxHeight - surroundingContent,
            )
            .clamp(160.0, 300.0);

        return FadedScrollView(
          padding: EdgeInsets.fromLTRB(horizontalInset, 4, horizontalInset, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AutoKeyStatus(),
              const SizedBox(height: 12),
              Center(
                child: SizedBox(
                  width: wheelSize,
                  height: wheelSize,
                  child: KeyPosteriorWheel(
                    ranked: inferred.ranked,
                    claim: inferred.displayKey?.tonality,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const RecentChordsStrip(),
            ],
          ),
        );
      },
    );
  }
}

class _KeyTopBar extends StatelessWidget {
  const _KeyTopBar({
    required this.toolbarHeight,
    required this.contentBottomInset,
    required this.horizontalInset,
  });

  final double toolbarHeight;
  final double contentBottomInset;
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(letterSpacing: -0.2);

    // Match the standard AppBar leading-control position while the title and
    // content retain their shared horizontal inset.
    const arrowIconDx = -12.0;

    return Material(
      color: cs.surfaceContainerLow,
      child: SizedBox(
        height: toolbarHeight,
        child: Padding(
          padding: EdgeInsets.only(
            left: horizontalInset,
            right: horizontalInset,
            bottom: contentBottomInset,
          ),
          child: Row(
            children: [
              Transform.translate(
                offset: const Offset(arrowIconDx, 0),
                child: IconButton(
                  tooltip: 'Back',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const BackButtonIcon(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  header: true,
                  namesRoute: true,
                  child: Text(
                    'Key Signature',
                    style: titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const MidiStatusIcon(),
              const SizedBox(width: 4),
              Transform.translate(
                offset: const Offset(6, 0),
                child: IconButton(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  tooltip: 'Settings',
                  onPressed: () {
                    unawaited(
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsPage(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
