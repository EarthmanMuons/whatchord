import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/home/home.dart';
import 'package:whatchord/features/piano/piano.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../models/explore_chord_state.dart';
import '../providers/explore_preferences_notifier.dart';
import '../services/explore_chord_example_builder.dart';
import '../services/explore_chord_state_transitions.dart';
import '../services/explore_preview_animation_controller.dart';
import '../widgets/explore_chord_members_section.dart';
import '../widgets/explore_controls.dart';
import '../widgets/explore_faded_scroll_view.dart';
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

    void updateState(ExploreChordState next) {
      _previewAnimationController.cancel();
      setState(() {
        _state = next;
      });
    }

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
                  child: ExploreTopBar(horizontalInset: horizontalInset),
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
                        child: isLandscape
                            ? Padding(
                                padding: EdgeInsets.fromLTRB(
                                  horizontalInset,
                                  16,
                                  horizontalInset,
                                  12,
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 7,
                                      child: ExploreFadedScrollView(
                                        padding: const EdgeInsets.only(
                                          top: 4,
                                          right: 12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            ExploreSummary(
                                              presentation: presentation,
                                            ),
                                            const SizedBox(height: 20),
                                            ChordMembersSection(
                                              members: example.members,
                                              memberDegrees:
                                                  example.memberDegrees,
                                              noteNameSystem: noteNameSystem,
                                              showDegrees:
                                                  showChordMemberDegrees,
                                              onShowDegreesChanged: (value) =>
                                                  unawaited(
                                                    ref
                                                        .read(
                                                          exploreChordMemberDegreesProvider
                                                              .notifier,
                                                        )
                                                        .setShowDegrees(value),
                                                  ),
                                              previewNotes:
                                                  example.normalizedVoicing,
                                              activePitchClasses:
                                                  previewPitchClasses,
                                              memberPitchClasses: example
                                                  .memberPitchClassesInOrder,
                                              onPreviewStarted:
                                                  _previewAnimationController
                                                      .start,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 6,
                                      child: ExploreFadedScrollView(
                                        padding: const EdgeInsets.only(
                                          top: 4,
                                          left: 12,
                                        ),
                                        child: ExploreControls(
                                          state: _state,
                                          identity: example.identity,
                                          tonality: tonality,
                                          noteNameSystem: noteNameSystem,
                                          isLandscape: true,
                                          onRootChanged: (value) => updateState(
                                            exploreStateWithRoot(_state, value),
                                          ),
                                          onBaseQualityChanged: (value) =>
                                              updateState(
                                                exploreStateWithBaseQuality(
                                                  _state,
                                                  value,
                                                ),
                                              ),
                                          onSeventhKindChanged: (value) =>
                                              updateState(
                                                exploreStateWithSeventhKind(
                                                  _state,
                                                  value,
                                                ),
                                              ),
                                          onFifthAlterationChanged: (value) =>
                                              updateState(
                                                exploreStateWithFifthAlteration(
                                                  _state,
                                                  value,
                                                ),
                                              ),
                                          onExtensionsChanged: (value) =>
                                              updateState(
                                                exploreStateWithExtensions(
                                                  _state,
                                                  value,
                                                ),
                                              ),
                                          onBassChanged: (value) => updateState(
                                            exploreStateWithBass(_state, value),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ExploreSummary(presentation: presentation),
                                    const SizedBox(height: 20),
                                    ChordMembersSection(
                                      members: example.members,
                                      memberDegrees: example.memberDegrees,
                                      noteNameSystem: noteNameSystem,
                                      showDegrees: showChordMemberDegrees,
                                      onShowDegreesChanged: (value) => unawaited(
                                        ref
                                            .read(
                                              exploreChordMemberDegreesProvider
                                                  .notifier,
                                            )
                                            .setShowDegrees(value),
                                      ),
                                      previewNotes: example.normalizedVoicing,
                                      activePitchClasses: previewPitchClasses,
                                      memberPitchClasses:
                                          example.memberPitchClassesInOrder,
                                      onPreviewStarted:
                                          _previewAnimationController.start,
                                    ),
                                    const SizedBox(height: 20),
                                    Expanded(
                                      child: ExploreFadedScrollView(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: ExploreControls(
                                          state: _state,
                                          identity: example.identity,
                                          tonality: tonality,
                                          noteNameSystem: noteNameSystem,
                                          isLandscape: false,
                                          onRootChanged: (value) => updateState(
                                            exploreStateWithRoot(_state, value),
                                          ),
                                          onBaseQualityChanged: (value) =>
                                              updateState(
                                                exploreStateWithBaseQuality(
                                                  _state,
                                                  value,
                                                ),
                                              ),
                                          onSeventhKindChanged: (value) =>
                                              updateState(
                                                exploreStateWithSeventhKind(
                                                  _state,
                                                  value,
                                                ),
                                              ),
                                          onFifthAlterationChanged: (value) =>
                                              updateState(
                                                exploreStateWithFifthAlteration(
                                                  _state,
                                                  value,
                                                ),
                                              ),
                                          onExtensionsChanged: (value) =>
                                              updateState(
                                                exploreStateWithExtensions(
                                                  _state,
                                                  value,
                                                ),
                                              ),
                                          onBassChanged: (value) => updateState(
                                            exploreStateWithBass(_state, value),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      TonalityBarView(
                        height: kToolbarHeight,
                        tonality: tonality,
                        scaleDegreeAnalysis: presentation.scaleDegreeAnalysis,
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
}
