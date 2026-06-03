import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/core.dart';
import 'package:whatchord/features/audio/audio.dart';
import 'package:whatchord/features/explore_scales/explore_scales.dart';
import 'package:whatchord/features/home/home.dart';
import 'package:whatchord/features/piano/piano.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../models/explore_chord_example.dart';
import '../models/explore_chord_state.dart';
import '../providers/explore_preferences_notifier.dart';
import '../services/explore_chord_example_builder.dart';
import '../services/explore_chord_state_transitions.dart';
import '../services/explore_preview_animation_controller.dart';
import '../widgets/explore_chord_members_section.dart';
import '../widgets/explore_controls.dart';
import '../widgets/explore_keyboard.dart';
import '../widgets/explore_summary.dart';
import '../widgets/explore_top_bar.dart';

class ExploreChordPage extends ConsumerStatefulWidget {
  const ExploreChordPage({super.key, required this.seedIdentity});

  final ChordIdentity seedIdentity;

  static Route<void> route({required ChordIdentity seedIdentity}) {
    return MaterialPageRoute<void>(
      builder: (_) => ExploreChordPage(seedIdentity: seedIdentity),
    );
  }

  @override
  ConsumerState<ExploreChordPage> createState() => _ExploreChordPageState();
}

class _ExploreChordPageState extends ConsumerState<ExploreChordPage> {
  late ExploreChordState _state;
  late final ExplorePreviewAnimationController _previewAnimationController;
  ExplorePreviewAnimationState _previewAnimation =
      ExplorePreviewAnimationState.idle;

  @override
  void initState() {
    super.initState();
    _previewAnimationController = ExplorePreviewAnimationController(
      onChanged: (state) {
        if (!mounted) return;
        setState(() {
          _previewAnimation = state;
        });
      },
    );
    _state = normalizeExploreChordState(
      ExploreChordState.fromIdentity(widget.seedIdentity),
    );
  }

  @override
  void dispose() {
    _previewAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tonality = ref.watch(selectedTonalityProvider);
    final notation = ref.watch(chordNotationStyleProvider);
    final noteNameSystem = ref.watch(noteNameSystemProvider);
    final showChordMemberDegrees = ref.watch(exploreChordMemberDegreesProvider);
    final example = ExploreChordExampleBuilder.build(
      state: _state,
      tonality: tonality,
      notation: notation,
      noteNameSystem: noteNameSystem,
    );
    final presentation = example.presentation;

    final showScaleNotes = ref.watch(showScaleNotesProvider);
    final diatonicPitchClasses = ref.watch(diatonicPitchClassesProvider);

    final markedNoteNumbers = showScaleNotes
        ? <int>{
            for (
              int midi = PianoGeometry.fullKeyboardLowestMidi;
              midi <= PianoGeometry.fullKeyboardHighestMidi;
              midi++
            )
              if (diatonicPitchClasses.contains(midi % 12)) midi,
          }
        : const <int>{};

    final cs = Theme.of(context).colorScheme;
    final previewPitchClasses = {
      for (final midiNote in _previewAnimation.activeNotes) midiNote % 12,
    };
    final displayedKeyboardNotes = _previewAnimation.isRunning
        ? _previewAnimation.activeNotes
        : example.normalizedVoicing.toSet();

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
                  child: ExploreTopBar(
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
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildMainContent(
                          example: example,
                          presentation: presentation,
                          tonality: tonality,
                          noteNameSystem: noteNameSystem,
                          showChordMemberDegrees: showChordMemberDegrees,
                          previewPitchClasses: previewPitchClasses,
                          isLandscape: isLandscape,
                          horizontalInset: horizontalInset,
                        ),
                      ),
                      TonalityBarView(
                        height: kToolbarHeight,
                        tonality: tonality,
                        scaleDegreeAnalysis: presentation.scaleDegreeAnalysis,
                        onScaleDegreesTap: () => Navigator.of(
                          context,
                        ).push(ScaleExplorerPage.route()),
                        onOpenPicker: () => openTonalityPicker(
                          context,
                          useSideSheet: useHomeSideSheet(context),
                          showSideSheet:
                              ({
                                required context,
                                required barrierLabel,
                                required builder,
                              }) {
                                unawaited(
                                  showHomeSideSheet<void>(
                                    context: context,
                                    barrierLabel: barrierLabel,
                                    builder: builder,
                                  ),
                                );
                              },
                        ),
                        horizontalInset: horizontalInset,
                        keyTextScaleMultiplier: config.tonalityButtonTextScale,
                        scaleDegreesTextScaleMultiplier:
                            config.scaleDegreesTextScale,
                      ),
                      const Divider(height: 1),
                      ExploreKeyboard(
                        config: config,
                        highlightedNotes: displayedKeyboardNotes,
                        markedNotes: markedNoteNumbers,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent({
    required ExploreChordExample example,
    required ChordPresentation presentation,
    required Tonality tonality,
    required NoteNameSystem noteNameSystem,
    required bool showChordMemberDegrees,
    required Set<int> previewPitchClasses,
    required bool isLandscape,
    required double horizontalInset,
  }) {
    if (isLandscape) {
      return Padding(
        padding: EdgeInsets.fromLTRB(horizontalInset, 16, horizontalInset, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 7,
              child: FadedScrollView(
                padding: const EdgeInsets.only(top: 4, right: 12),
                child: _buildSummaryAndMembers(
                  example: example,
                  presentation: presentation,
                  noteNameSystem: noteNameSystem,
                  showChordMemberDegrees: showChordMemberDegrees,
                  previewPitchClasses: previewPitchClasses,
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: FadedScrollView(
                padding: const EdgeInsets.only(top: 4, left: 12),
                child: _buildControls(
                  example: example,
                  tonality: tonality,
                  noteNameSystem: noteNameSystem,
                  isLandscape: true,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryAndMembers(
            example: example,
            presentation: presentation,
            noteNameSystem: noteNameSystem,
            showChordMemberDegrees: showChordMemberDegrees,
            previewPitchClasses: previewPitchClasses,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FadedScrollView(
              padding: const EdgeInsets.only(top: 4),
              maintainVisualPositionOnResize: true,
              child: _buildControls(
                example: example,
                tonality: tonality,
                noteNameSystem: noteNameSystem,
                isLandscape: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryAndMembers({
    required ExploreChordExample example,
    required ChordPresentation presentation,
    required NoteNameSystem noteNameSystem,
    required bool showChordMemberDegrees,
    required Set<int> previewPitchClasses,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircularPlayButton(
              label: 'Play chord',
              tapHint: 'Play the current Explore chord',
              onPressed: () => _playChord(example.normalizedVoicing),
            ),
            const SizedBox(width: 12),
            Expanded(child: ExploreSummary(presentation: presentation)),
          ],
        ),
        const SizedBox(height: 20),
        ExploreChordMembersSection(
          members: example.members,
          memberDegrees: example.memberDegrees,
          noteNameSystem: noteNameSystem,
          showDegrees: showChordMemberDegrees,
          onShowDegreesChanged: (value) => unawaited(
            ref
                .read(exploreChordMemberDegreesProvider.notifier)
                .setShowDegrees(value),
          ),
          activePitchClasses: previewPitchClasses,
          memberPitchClasses: example.memberPitchClassesInOrder,
        ),
      ],
    );
  }

  Widget _buildControls({
    required ExploreChordExample example,
    required Tonality tonality,
    required NoteNameSystem noteNameSystem,
    required bool isLandscape,
  }) {
    return ExploreControls(
      state: _state,
      identity: example.identity,
      tonality: tonality,
      noteNameSystem: noteNameSystem,
      isLandscape: isLandscape,
      onRootChanged: (value) =>
          _updateState(exploreStateWithRoot(_state, value)),
      onBaseQualityChanged: (value) =>
          _updateState(exploreStateWithBaseQuality(_state, value)),
      onSeventhKindChanged: (value) =>
          _updateState(exploreStateWithSeventhKind(_state, value)),
      onFifthAlterationChanged: (value) =>
          _updateState(exploreStateWithFifthAlteration(_state, value)),
      onExtensionsChanged: (value) =>
          _updateState(exploreStateWithExtensions(_state, value)),
      onBassChanged: (value) =>
          _updateState(exploreStateWithBass(_state, value)),
    );
  }

  void _updateState(ExploreChordState next) {
    _previewAnimationController.cancel();
    setState(() {
      _state = next;
    });
  }

  void _playChord(List<int> notes) {
    _previewAnimationController.start(notes);
    ref.read(audioMonitorNotifier.notifier).playRolledPreviewNotes(notes);
  }
}
