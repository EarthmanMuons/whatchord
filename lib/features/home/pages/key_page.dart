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
                          if (!isLandscape) ...[
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
                                  ? _PortraitAutoPane(
                                      horizontalInset: horizontalInset,
                                    )
                                  : const TonalityPickerBody(),
                            ),
                          ] else
                            Expanded(
                              child: _LandscapeBody(
                                mode: mode,
                                horizontalInset: horizontalInset,
                              ),
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

class _PortraitAutoPane extends ConsumerWidget {
  const _PortraitAutoPane({required this.horizontalInset});

  final double horizontalInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inferred = ref.watch(inferredKeyProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // The wheel absorbs whatever height remains, so growing the keyboard
        // eats slack around the wheel before shrinking it; below the wheel's
        // readable minimum the pane falls back to scrolling.
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AutoKeyStatus(),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 300,
                      maxHeight: 300,
                    ),
                    child: KeyPosteriorWheel(
                      ranked: inferred.ranked,
                      claim: inferred.displayKey?.tonality,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const RecentChordsStrip(),
          ],
        );

        const surroundingContent = 190.0;
        const minWheel = 150.0;
        if (constraints.maxHeight < surroundingContent + minWheel) {
          return FadedScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalInset,
              4,
              horizontalInset,
              4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AutoKeyStatus(),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: minWheel,
                    height: minWheel,
                    child: KeyPosteriorWheel(
                      ranked: inferred.ranked,
                      claim: inferred.displayKey?.tonality,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const RecentChordsStrip(),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(horizontalInset, 4, horizontalInset, 4),
          child: content,
        );
      },
    );
  }
}

/// Landscape splits like the Explore pages: mode control and context on the
/// left, the working surface (posterior strip and chords, or the key list)
/// on the right.
class _LandscapeBody extends ConsumerWidget {
  const _LandscapeBody({required this.mode, required this.horizontalInset});

  final KeyMode mode;
  final double horizontalInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inferred = ref.watch(inferredKeyProvider);
    final selected = ref.watch(selectedTonalityProvider);

    // Pane content centers in whatever height the keyboard leaves, so the
    // layout rebalances as the keyboard is resized; it degrades to a plain
    // scroll when the content no longer fits.
    Widget balanced({
      required List<Widget> children,
      required CrossAxisAlignment crossAxisAlignment,
    }) {
      return LayoutBuilder(
        builder: (context, paneConstraints) => FadedScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, paneConstraints.maxHeight - 16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: crossAxisAlignment,
              children: children,
            ),
          ),
        ),
      );
    }

    final left = balanced(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModeSegments(mode: mode),
        const SizedBox(height: 14),
        if (mode == KeyMode.auto)
          const AutoKeyStatus()
        else
          Center(
            child: KeySignatureStaffPreview(
              keySignature: selected.keySignature,
            ),
          ),
      ],
    );

    final right = mode == KeyMode.auto
        ? balanced(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeyPosteriorStrip(
                ranked: inferred.ranked,
                claim: inferred.displayKey?.tonality,
              ),
              const SizedBox(height: 12),
              const RecentChordsStrip(),
            ],
          )
        : const TonalityPickerBody(
            showStaffPreview: false,
            compact: true,
            headerHeight: TonalityPickerBody.slimHeaderHeight,
            listBottomPadding: 0,
          );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalInset),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: left),
          const SizedBox(width: 16),
          Expanded(flex: 7, child: right),
        ],
      ),
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
