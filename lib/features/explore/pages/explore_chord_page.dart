import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/audio/audio.dart';
import 'package:whatchord/features/input/input.dart';
import 'package:whatchord/features/piano/piano.dart';
import 'package:whatchord/features/settings/settings.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../../home/models/home_layout_config.dart';
import '../../home/widgets/adaptive_side_sheet.dart';
import '../models/explore_chord_state.dart';
import '../services/explore_chord_derivation.dart';
import '../services/explore_chord_options.dart';

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
  static const Duration _previewDuration = Duration(milliseconds: 1400);
  static const Duration _rolledPreviewStep = Duration(milliseconds: 180);
  static const Duration _rolledPreviewNoteDuration = Duration(
    milliseconds: 220,
  );
  static const Duration _rolledPreviewBlockGap = Duration(milliseconds: 260);
  static const Duration _rolledPreviewBlockDuration = Duration(
    milliseconds: 1400,
  );

  late ExploreChordState _state;
  final List<Timer> _previewAnimationTimers = <Timer>[];
  Set<int> _previewActiveNotes = const <int>{};
  bool _isPreviewAnimationRunning = false;
  int _previewAnimationGeneration = 0;

  @override
  void initState() {
    super.initState();
    final seedState = ExploreChordState.fromIdentity(widget.seedIdentity);
    _state = seedState.copyWith(
      extensions: normalizeExtensionsForQuality(
        quality: seedState.quality,
        extensions: seedState.extensions,
      ),
    );
  }

  @override
  void dispose() {
    _cancelPreviewAnimation(notify: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final identity = buildExploreChordIdentity(_state);
    final tonality = ref.watch(selectedTonalityProvider);
    final notation = ref.watch(chordNotationStyleProvider);
    final presentation = ChordPresentationBuilder.fromIdentity(
      identity: identity,
      tonality: tonality,
      notation: notation,
    );
    void onRootChanged(int value) {
      _cancelPreviewAnimation();
      setState(() {
        final next = _state.copyWith(rootPc: value);
        _state = _withValidBass(next);
      });
    }

    void onQualityChanged(ChordQualityToken value) {
      _cancelPreviewAnimation();
      setState(() {
        final normalizedExtensions = normalizeExtensionsForQuality(
          quality: value,
          extensions: _state.extensions,
        );
        final next = _state.copyWith(
          quality: value,
          extensions: normalizedExtensions,
        );
        _state = _withValidBass(next);
      });
    }

    void onExtensionsChanged(Set<ChordExtension> value) {
      _cancelPreviewAnimation();
      setState(() {
        final next = _state.copyWith(
          extensions: normalizeExtensionsForQuality(
            quality: _state.quality,
            extensions: value,
          ),
        );
        _state = _withValidBass(next);
      });
    }

    void onBassChanged(int value) {
      _cancelPreviewAnimation();
      setState(() {
        _state = _withValidBass(_state.copyWith(bassPc: value));
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
      for (final midiNote in _previewActiveNotes) midiNote % 12,
    };
    final displayedKeyboardNotes = _isPreviewAnimationRunning
        ? _previewActiveNotes
        : presentation.normalizedVoicing.toSet();

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
                  child: _ExploreTopBar(horizontalInset: horizontalInset),
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
                                      child: _ExploreFadedScrollView(
                                        padding: const EdgeInsets.only(
                                          top: 4,
                                          right: 12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            _ExploreSummary(
                                              presentation: presentation,
                                            ),
                                            const SizedBox(height: 20),
                                            _ChordMembersSection(
                                              members: presentation.members,
                                              previewNotes: presentation
                                                  .normalizedVoicing,
                                              activePitchClasses:
                                                  previewPitchClasses,
                                              memberPitchClasses:
                                                  _memberPitchClassesInOrder(
                                                    identity,
                                                  ),
                                              onPreviewStarted:
                                                  _startPreviewAnimation,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 6,
                                      child: _ExploreFadedScrollView(
                                        padding: const EdgeInsets.only(
                                          top: 4,
                                          left: 12,
                                        ),
                                        child: _ExploreControls(
                                          state: _state,
                                          identity: identity,
                                          tonality: tonality,
                                          isLandscape: true,
                                          onRootChanged: onRootChanged,
                                          onQualityChanged: onQualityChanged,
                                          onExtensionsChanged:
                                              onExtensionsChanged,
                                          onBassChanged: onBassChanged,
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
                                    _ExploreSummary(presentation: presentation),
                                    const SizedBox(height: 20),
                                    _ChordMembersSection(
                                      members: presentation.members,
                                      previewNotes:
                                          presentation.normalizedVoicing,
                                      activePitchClasses: previewPitchClasses,
                                      memberPitchClasses:
                                          _memberPitchClassesInOrder(identity),
                                      onPreviewStarted: _startPreviewAnimation,
                                    ),
                                    const SizedBox(height: 20),
                                    Expanded(
                                      child: _ExploreFadedScrollView(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: _ExploreControls(
                                          state: _state,
                                          identity: identity,
                                          tonality: tonality,
                                          isLandscape: false,
                                          onRootChanged: onRootChanged,
                                          onQualityChanged: onQualityChanged,
                                          onExtensionsChanged:
                                              onExtensionsChanged,
                                          onBassChanged: onBassChanged,
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
                                showHomeSideSheet<void>(
                                  context: context,
                                  barrierLabel: barrierLabel,
                                  builder: builder,
                                );
                              },
                        ),
                        horizontalInset: horizontalInset,
                        keyTextScaleMultiplier: config.tonalityButtonTextScale,
                        scaleDegreesTextScaleMultiplier:
                            config.scaleDegreesTextScale,
                      ),
                      const Divider(height: 1),
                      _ExploreKeyboard(
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

  ExploreChordState _withValidBass(ExploreChordState candidate) {
    final identity = buildExploreChordIdentity(candidate);
    final pitchClasses =
        ChordPresentationBuilder.chordMemberPitchClassesFromMask(
          rootPc: identity.rootPc,
          presentIntervalsMask: identity.presentIntervalsMask,
        );

    final bassPc = pitchClasses.contains(candidate.bassPc)
        ? candidate.bassPc
        : candidate.rootPc;

    return candidate.copyWith(bassPc: bassPc);
  }

  List<int> _memberPitchClassesInOrder(ChordIdentity identity) {
    return ChordPresentationBuilder.sortedIntervalsForIdentity(
      identity,
    ).map((interval) => (identity.rootPc + interval) % 12).toList();
  }

  void _startPreviewAnimation(List<int> previewNotes) {
    final notes =
        previewNotes.map((note) => note.clamp(0, 127)).toSet().toList()..sort();
    if (notes.isEmpty) return;

    _cancelPreviewAnimation();
    final generation = ++_previewAnimationGeneration;

    void setActive(Set<int> notes) {
      if (!mounted || generation != _previewAnimationGeneration) return;
      setState(() {
        _isPreviewAnimationRunning = true;
        _previewActiveNotes = Set<int>.unmodifiable(notes);
      });
    }

    void schedule(Duration delay, VoidCallback callback) {
      _previewAnimationTimers.add(Timer(delay, callback));
    }

    if (notes.length == 1) {
      setActive(notes.toSet());
      schedule(_previewDuration, () => _finishPreviewAnimation(generation));
      return;
    }

    final activeNotes = <int>{};
    for (var i = 0; i < notes.length; i++) {
      final midiNote = notes[i];
      final noteStart = _rolledPreviewStep * i;
      schedule(noteStart, () {
        activeNotes.add(midiNote);
        setActive(activeNotes);
      });
      schedule(noteStart + _rolledPreviewNoteDuration, () {
        activeNotes.remove(midiNote);
        setActive(activeNotes);
      });
    }

    final blockStart =
        _rolledPreviewStep * notes.length + _rolledPreviewBlockGap;
    schedule(blockStart, () => setActive(notes.toSet()));
    schedule(
      blockStart + _rolledPreviewBlockDuration,
      () => _finishPreviewAnimation(generation),
    );
  }

  void _finishPreviewAnimation(int generation) {
    if (!mounted || generation != _previewAnimationGeneration) return;
    setState(() {
      _isPreviewAnimationRunning = false;
      _previewActiveNotes = const <int>{};
    });
    _clearPreviewAnimationTimers();
  }

  void _cancelPreviewAnimation({bool notify = true}) {
    _previewAnimationGeneration++;
    _clearPreviewAnimationTimers();
    if ((_previewActiveNotes.isEmpty && !_isPreviewAnimationRunning) ||
        !mounted ||
        !notify) {
      _isPreviewAnimationRunning = false;
      _previewActiveNotes = const <int>{};
      return;
    }
    setState(() {
      _isPreviewAnimationRunning = false;
      _previewActiveNotes = const <int>{};
    });
  }

  void _clearPreviewAnimationTimers() {
    for (final timer in _previewAnimationTimers) {
      timer.cancel();
    }
    _previewAnimationTimers.clear();
  }
}

class _ExploreTopBar extends StatelessWidget {
  const _ExploreTopBar({required this.horizontalInset});

  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleLarge;

    // Optical-only tweak.
    const arrowIconDx = -6.0;

    return Material(
      color: cs.surfaceContainerLow,
      child: SizedBox(
        height: kToolbarHeight,
        child: Padding(
          padding: EdgeInsets.only(
            left: horizontalInset,
            right: horizontalInset,
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
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Explore Chords',
                  style: titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsPage(),
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

class _ExploreFadedScrollView extends StatefulWidget {
  const _ExploreFadedScrollView({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  State<_ExploreFadedScrollView> createState() =>
      _ExploreFadedScrollViewState();
}

class _ExploreFadedScrollViewState extends State<_ExploreFadedScrollView> {
  static const _fadeHeight = 24.0;

  final ScrollController _controller = ScrollController();
  bool _showTopFade = false;
  bool _showBottomFade = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateFades);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateFades();
    });
  }

  @override
  void didUpdateWidget(covariant _ExploreFadedScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateFades();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_updateFades);
    _controller.dispose();
    super.dispose();
  }

  void _updateFades() {
    if (!_controller.hasClients) return;

    final position = _controller.position;
    if (!position.hasContentDimensions) return;

    const epsilon = 0.5;
    final maxExtent = position.maxScrollExtent;
    final pixels = position.pixels;
    final nextTop = maxExtent > epsilon && pixels > epsilon;
    final nextBottom = maxExtent > epsilon && pixels < maxExtent - epsilon;

    if (nextTop == _showTopFade && nextBottom == _showBottomFade) return;

    setState(() {
      _showTopFade = nextTop;
      _showBottomFade = nextBottom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fadeColor = Theme.of(context).colorScheme.surface;

    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _updateFades();
        });

        return Stack(
          children: [
            SingleChildScrollView(
              controller: _controller,
              padding: widget.padding,
              child: widget.child,
            ),
            if (_showTopFade)
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: _fadeHeight,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [fadeColor, fadeColor.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ),
            if (_showBottomFade)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _fadeHeight,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [fadeColor, fadeColor.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ExploreSummary extends StatelessWidget {
  const _ExploreSummary({required this.presentation});

  final ChordPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final symbolStyle = textTheme.headlineMedium?.copyWith(
      color: colorScheme.onSurface,
      fontFamilyFallback: const ['Bravura'],
      height: 1.0,
    );
    final rootStyle = symbolStyle?.copyWith(
      fontWeight: FontWeight.w500,
      fontSize: (symbolStyle.fontSize ?? 14) + 6,
    );

    return Semantics(
      container: true,
      header: true,
      label: presentation.longLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: toSmufl(presentation.symbol.root),
                  style: rootStyle,
                ),
                if (presentation.symbol.quality.isNotEmpty) ...[
                  const TextSpan(text: '\u200A'),
                  TextSpan(text: toSmufl(presentation.symbol.quality)),
                ],
                if (presentation.symbol.hasBass) ...[
                  const TextSpan(text: ' / '),
                  TextSpan(text: toSmufl(presentation.symbol.bassRequired)),
                ],
              ],
            ),
            style: symbolStyle,
          ),
          const SizedBox(height: 6),
          Text(
            presentation.longLabel,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChordMembersSection extends StatefulWidget {
  const _ChordMembersSection({
    required this.members,
    required this.previewNotes,
    required this.activePitchClasses,
    required this.memberPitchClasses,
    required this.onPreviewStarted,
  });

  final List<String> members;
  final List<int> previewNotes;
  final Set<int> activePitchClasses;
  final List<int> memberPitchClasses;
  final ValueChanged<List<int>> onPreviewStarted;

  @override
  State<_ChordMembersSection> createState() => _ChordMembersSectionState();
}

class _ChordMembersSectionState extends State<_ChordMembersSection>
    with TickerProviderStateMixin {
  static const Duration _insertDuration = Duration(milliseconds: 140);
  static const Duration _removeDuration = Duration(milliseconds: 120);

  late List<_ExploreMemberChipEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = _createInitialEntries();
  }

  @override
  void didUpdateWidget(covariant _ChordMembersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applyMemberDiff();
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.controller.dispose();
    }
    super.dispose();
  }

  List<_ExploreMemberChipEntry> _createInitialEntries() {
    return [
      for (var i = 0; i < widget.members.length; i++)
        _ExploreMemberChipEntry(
          data: _memberDataAt(i),
          controller: AnimationController(
            vsync: this,
            duration: _insertDuration,
            reverseDuration: _removeDuration,
            value: 1.0,
          ),
        ),
    ];
  }

  _ExploreMemberChipData _memberDataAt(int index) {
    final pitchClass = index < widget.memberPitchClasses.length
        ? widget.memberPitchClasses[index]
        : null;
    final id = pitchClass == null
        ? 'label:${widget.members[index]}'
        : 'pc:$pitchClass';

    return _ExploreMemberChipData(
      id: id,
      label: toGlyphAccidentals(widget.members[index]),
      active:
          pitchClass != null && widget.activePitchClasses.contains(pitchClass),
    );
  }

  void _applyMemberDiff() {
    final nextData = [
      for (var i = 0; i < widget.members.length; i++) _memberDataAt(i),
    ];
    final nextIds = {for (final data in nextData) data.id};
    final entriesById = {
      for (final entry in _entries)
        if (!entry.removing) entry.data.id: entry,
    };
    final nextEntries = <_ExploreMemberChipEntry>[];

    for (final data in nextData) {
      final existing = entriesById[data.id];
      if (existing != null) {
        existing.data = data;
        nextEntries.add(existing);
        continue;
      }

      final entry = _ExploreMemberChipEntry(
        data: data,
        controller: AnimationController(
          vsync: this,
          duration: _insertDuration,
          reverseDuration: _removeDuration,
        ),
      );
      nextEntries.add(entry);
      entry.controller.forward();
    }

    for (final entry in _entries) {
      if (entry.removing || nextIds.contains(entry.data.id)) continue;

      entry.removing = true;
      entry.controller.reverse().whenComplete(() {
        if (!mounted) return;
        setState(() {
          _entries.remove(entry);
        });
        entry.controller.dispose();
      });

      final oldIndex = _entries.indexOf(entry);
      final insertIndex = oldIndex.clamp(0, nextEntries.length);
      nextEntries.insert(insertIndex, entry);
    }

    setState(() {
      _entries = nextEntries;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Chord members',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _ExplorePlayButton(
              previewNotes: widget.previewNotes,
              onPreviewStarted: widget.onPreviewStarted,
            ),
          ),
          for (final entry in _entries)
            _AnimatedExploreMemberChip(
              key: ValueKey(entry.data.id),
              entry: entry,
            ),
        ],
      ),
    );
  }
}

class _ExploreMemberChipData {
  const _ExploreMemberChipData({
    required this.id,
    required this.label,
    required this.active,
  });

  final String id;
  final String label;
  final bool active;
}

class _ExploreMemberChipEntry {
  _ExploreMemberChipEntry({required this.data, required this.controller});

  _ExploreMemberChipData data;
  final AnimationController controller;
  bool removing = false;
}

class _AnimatedExploreMemberChip extends StatelessWidget {
  const _AnimatedExploreMemberChip({super.key, required this.entry});

  final _ExploreMemberChipEntry entry;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: entry.controller,
      curve: Curves.easeOutCubic,
    );

    return SizeTransition(
      sizeFactor: curved,
      axis: Axis.horizontal,
      child: FadeTransition(
        opacity: curved,
        child: _ExploreMemberChip(
          label: entry.data.label,
          active: entry.data.active,
        ),
      ),
    );
  }
}

class _ExplorePlayButton extends ConsumerWidget {
  const _ExplorePlayButton({
    required this.previewNotes,
    required this.onPreviewStarted,
  });

  final List<int> previewNotes;
  final ValueChanged<List<int>> onPreviewStarted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    void playChord() {
      onPreviewStarted(previewNotes);
      ref
          .read(audioMonitorNotifier.notifier)
          .playRolledPreviewNotes(previewNotes);
    }

    return Semantics(
      button: true,
      label: 'Play chord',
      onTapHint: 'Play the current Explore chord',
      onTap: playChord,
      child: Tooltip(
        message: 'Play chord',
        child: ExcludeSemantics(
          child: IconButton.filledTonal(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            style: IconButton.styleFrom(
              fixedSize: const Size.square(48),
              shape: const CircleBorder(),
              backgroundColor: cs.secondaryContainer,
              foregroundColor: cs.onSecondaryContainer,
            ),
            onPressed: playChord,
            icon: const Icon(Icons.play_arrow),
          ),
        ),
      ),
    );
  }
}

class _ExploreControls extends ConsumerWidget {
  const _ExploreControls({
    required this.state,
    required this.identity,
    required this.tonality,
    required this.isLandscape,
    required this.onRootChanged,
    required this.onQualityChanged,
    required this.onExtensionsChanged,
    required this.onBassChanged,
  });

  final ExploreChordState state;
  final ChordIdentity identity;
  final Tonality tonality;
  final bool isLandscape;
  final ValueChanged<int> onRootChanged;
  final ValueChanged<ChordQualityToken> onQualityChanged;
  final ValueChanged<Set<ChordExtension>> onExtensionsChanged;
  final ValueChanged<int> onBassChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extensionGroups = buildExploreExtensionControlGroups(state.quality);
    final memberPitchClasses =
        ChordPresentationBuilder.chordMemberPitchClassesFromMask(
          rootPc: identity.rootPc,
          presentIntervalsMask: identity.presentIntervalsMask,
        );

    final controlWidth = isLandscape
        ? ((MediaQuery.sizeOf(context).width - 48) / 2).clamp(180.0, 360.0)
        : double.infinity;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Explore controls',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: controlWidth,
            child: _RootWheel(
              value: state.rootPc,
              tonality: tonality,
              onChanged: onRootChanged,
            ),
          ),
          SizedBox(
            width: controlWidth,
            child: _QualityWheel(
              value: state.quality,
              onChanged: onQualityChanged,
            ),
          ),
          SizedBox(
            width: controlWidth,
            child: _ExtensionBuilder(
              groups: extensionGroups,
              selectedExtensions: state.extensions,
              onChoiceSelected: (group, choice) {
                onExtensionsChanged(
                  selectExploreExtensionChoice(
                    quality: state.quality,
                    currentExtensions: state.extensions,
                    group: group,
                    choice: choice,
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: controlWidth,
            child: _BassSelector(
              value: state.bassPc,
              choices: [
                for (final pc in _sortedPitchClasses(
                  memberPitchClasses,
                  identity.rootPc,
                ))
                  _BassChoice(
                    pc: pc,
                    label: pc == identity.rootPc
                        ? 'Root'
                        : '/${toGlyphAccidentals(_spellBass(pc: pc, identity: identity, tonality: tonality))}',
                    semanticLabel: pc == identity.rootPc
                        ? 'Root position'
                        : 'Bass ${_spellBass(pc: pc, identity: identity, tonality: tonality)}',
                  ),
              ],
              onChanged: onBassChanged,
            ),
          ),
        ],
      ),
    );
  }

  List<int> _sortedPitchClasses(Set<int> pitchClasses, int rootPc) {
    final values = pitchClasses.toList();
    values.sort((a, b) {
      final intervalA = (a - rootPc) % 12;
      final intervalB = (b - rootPc) % 12;
      return intervalA.compareTo(intervalB);
    });
    return values;
  }

  String _spellBass({
    required int pc,
    required ChordIdentity identity,
    required Tonality tonality,
  }) {
    final root = pcToName(identity.rootPc, tonality: tonality);
    final interval = (pc - identity.rootPc) % 12;
    final role = identity.toneRolesByInterval[interval];
    return spellPitchClass(
      pc,
      tonality: tonality,
      chordRootName: root,
      role: role,
    );
  }
}

class _QualityWheel extends StatefulWidget {
  const _QualityWheel({required this.value, required this.onChanged});

  final ChordQualityToken value;
  final ValueChanged<ChordQualityToken> onChanged;

  @override
  State<_QualityWheel> createState() => _QualityWheelState();
}

class _QualityWheelState extends State<_QualityWheel> {
  static const _qualities = exploreChordQualityOrder;
  static final _qualityCount = _qualities.length;
  static const _initialLoop = 500;
  static const _wheelHeight = 64.0;
  static const _wheelContentPadding = EdgeInsets.fromLTRB(8, 10, 8, 6);

  late final PageController _controller;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = (_initialLoop * _qualityCount) + _indexOf(widget.value);
    _controller = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.34,
    );
  }

  @override
  void didUpdateWidget(covariant _QualityWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;

    final visiblePage = _controller.hasClients
        ? (_controller.page?.round() ?? _currentPage)
        : _currentPage;
    if (_qualityForPage(visiblePage) == widget.value) return;

    final targetPage = _nearestPageForQuality(widget.value);
    _currentPage = targetPage;
    if (!_controller.hasClients) return;

    _controller.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedLabel = _longLabel(widget.value);

    return Semantics(
      container: true,
      label: 'Quality',
      value: selectedLabel,
      increasedValue: _longLabel(_nextQuality(widget.value)),
      decreasedValue: _longLabel(_previousQuality(widget.value)),
      onIncrease: () => widget.onChanged(_nextQuality(widget.value)),
      onDecrease: () => widget.onChanged(_previousQuality(widget.value)),
      child: ExcludeSemantics(
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Quality',
            border: OutlineInputBorder(),
            contentPadding: _wheelContentPadding,
          ),
          child: SizedBox(
            height: _wheelHeight,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  onPageChanged: _handlePageChanged,
                  itemBuilder: (context, page) {
                    final quality = _qualityForPage(page);
                    return _QualityWheelItem(
                      label: theoryTokenDisplayLabel(
                        quality.label(ChordQualityLabelForm.standalone),
                      ),
                      selected: quality == widget.value,
                      onTap: () => _selectQuality(quality),
                    );
                  },
                ),
                const Positioned.fill(child: _RootWheelEdgeFades()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handlePageChanged(int page) {
    _currentPage = page;
    final quality = _qualityForPage(page);
    if (quality == widget.value) return;
    widget.onChanged(quality);
  }

  void _selectQuality(ChordQualityToken quality) {
    final targetPage = _nearestPageForQuality(quality);
    _currentPage = targetPage;
    _controller.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
    if (quality != widget.value) widget.onChanged(quality);
  }

  int _nearestPageForQuality(ChordQualityToken quality) {
    final currentPage = _controller.hasClients
        ? (_controller.page?.round() ?? _currentPage)
        : _currentPage;
    final currentIndex = _indexForPage(currentPage);
    var delta = (_indexOf(quality) - currentIndex) % _qualityCount;
    if (delta > _qualityCount / 2) delta -= _qualityCount;
    return currentPage + delta;
  }

  ChordQualityToken _qualityForPage(int page) =>
      _qualities[_indexForPage(page)];

  ChordQualityToken _nextQuality(ChordQualityToken quality) {
    return _qualities[(_indexOf(quality) + 1) % _qualityCount];
  }

  ChordQualityToken _previousQuality(ChordQualityToken quality) {
    return _qualities[(_indexOf(quality) - 1) % _qualityCount];
  }

  int _indexForPage(int page) => page % _qualityCount;

  int _indexOf(ChordQualityToken quality) {
    final index = _qualities.indexOf(quality);
    return index < 0 ? 0 : index;
  }

  String _longLabel(ChordQualityToken quality) {
    return quality.label(ChordQualityLabelForm.long);
  }
}

class _QualityWheelItem extends StatelessWidget {
  const _QualityWheelItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final labelStyle =
        (selected ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)
            ?.copyWith(
              color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Center(
        child: Material(
          color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: selected ? 76 : 64,
                minHeight: 48,
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: selected ? 8 : 6),
                    child: Text(label, maxLines: 1, style: labelStyle),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RootWheel extends StatefulWidget {
  const _RootWheel({
    required this.value,
    required this.tonality,
    required this.onChanged,
  });

  final int value;
  final Tonality tonality;
  final ValueChanged<int> onChanged;

  @override
  State<_RootWheel> createState() => _RootWheelState();
}

class _RootWheelState extends State<_RootWheel> {
  static const _pitchClassCount = 12;
  static const _initialLoop = 500;
  static const _wheelHeight = 64.0;
  static const _wheelContentPadding = EdgeInsets.fromLTRB(8, 10, 8, 6);

  late final PageController _controller;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = (_initialLoop * _pitchClassCount) + widget.value;
    _controller = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.22,
    );
  }

  @override
  void didUpdateWidget(covariant _RootWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;

    final visiblePage = _controller.hasClients
        ? (_controller.page?.round() ?? _currentPage)
        : _currentPage;
    if (_pcForPage(visiblePage) == widget.value) return;

    final targetPage = _nearestPageForPc(widget.value);
    _currentPage = targetPage;
    if (!_controller.hasClients) return;

    _controller.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedLabel = _labelForPc(widget.value);

    return Semantics(
      container: true,
      label: 'Root',
      value: selectedLabel,
      increasedValue: _labelForPc(_nextPc(widget.value)),
      decreasedValue: _labelForPc(_previousPc(widget.value)),
      onIncrease: () => widget.onChanged(_nextPc(widget.value)),
      onDecrease: () => widget.onChanged(_previousPc(widget.value)),
      child: ExcludeSemantics(
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Root',
            border: OutlineInputBorder(),
            contentPadding: _wheelContentPadding,
          ),
          child: SizedBox(
            height: _wheelHeight,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  onPageChanged: _handlePageChanged,
                  itemBuilder: (context, page) {
                    final pc = _pcForPage(page);
                    return _RootWheelItem(
                      label: _labelForPc(pc),
                      selected: pc == widget.value,
                      onTap: () => _selectPc(pc),
                    );
                  },
                ),
                const Positioned.fill(child: _RootWheelEdgeFades()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handlePageChanged(int page) {
    _currentPage = page;
    final pc = _pcForPage(page);
    if (pc == widget.value) return;
    widget.onChanged(pc);
  }

  void _selectPc(int pc) {
    final targetPage = _nearestPageForPc(pc);
    _currentPage = targetPage;
    _controller.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
    if (pc != widget.value) widget.onChanged(pc);
  }

  int _nearestPageForPc(int pc) {
    final currentPage = _controller.hasClients
        ? (_controller.page?.round() ?? _currentPage)
        : _currentPage;
    final currentPc = _pcForPage(currentPage);
    var delta = (pc - currentPc) % _pitchClassCount;
    if (delta > _pitchClassCount / 2) delta -= _pitchClassCount;
    return currentPage + delta;
  }

  int _pcForPage(int page) => page % _pitchClassCount;

  int _nextPc(int pc) => (pc + 1) % _pitchClassCount;

  int _previousPc(int pc) => (pc - 1) % _pitchClassCount;

  String _labelForPc(int pc) {
    return toGlyphAccidentals(pcToName(pc, tonality: widget.tonality));
  }
}

class _RootWheelItem extends StatelessWidget {
  const _RootWheelItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textStyle =
        (selected ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)
            ?.copyWith(
              color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Center(
        child: Material(
          color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: selected ? 46 : 40,
                minHeight: 48,
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: selected ? 8 : 4),
                    child: Text(label, maxLines: 1, style: textStyle),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RootWheelEdgeFades extends StatelessWidget {
  const _RootWheelEdgeFades();

  static const _fadeWidth = 56.0;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _fadeWidth,
            child: _RootWheelFade(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              surface: surface,
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: _fadeWidth,
            child: _RootWheelFade(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              surface: surface,
            ),
          ),
        ],
      ),
    );
  }
}

class _RootWheelFade extends StatelessWidget {
  const _RootWheelFade({
    required this.begin,
    required this.end,
    required this.surface,
  });

  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          stops: const [0.0, 0.55, 1.0],
          colors: [
            surface,
            surface.withValues(alpha: 0.82),
            surface.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _BassChoice {
  const _BassChoice({
    required this.pc,
    required this.label,
    required this.semanticLabel,
  });

  final int pc;
  final String label;
  final String semanticLabel;
}

class _BassSelector extends StatelessWidget {
  const _BassSelector({
    required this.value,
    required this.choices,
    required this.onChanged,
  });

  final int value;
  final List<_BassChoice> choices;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedChoice = _selectedChoice();

    return Semantics(
      container: true,
      label: 'Bass Note',
      value: selectedChoice?.semanticLabel,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Bass Note',
          border: OutlineInputBorder(),
        ),
        child: _ExploreSegmentedChoiceGroup(
          labels: [for (final choice in choices) choice.label],
          semanticLabels: [for (final choice in choices) choice.semanticLabel],
          selectedIndex: _selectedIndex(),
          onSelected: (index) => onChanged(choices[index].pc),
        ),
      ),
    );
  }

  _BassChoice? _selectedChoice() {
    for (final choice in choices) {
      if (choice.pc == value) return choice;
    }
    return null;
  }

  int _selectedIndex() {
    for (var index = 0; index < choices.length; index++) {
      if (choices[index].pc == value) return index;
    }
    return 0;
  }
}

class _ExtensionBuilder extends StatelessWidget {
  const _ExtensionBuilder({
    required this.groups,
    required this.selectedExtensions,
    required this.onChoiceSelected,
  });

  final List<ExploreExtensionControlGroup> groups;
  final Set<ChordExtension> selectedExtensions;
  final void Function(
    ExploreExtensionControlGroup group,
    ExploreExtensionChoice choice,
  )
  onChoiceSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Semantics(
      container: true,
      label: 'Extensions',
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Extensions',
          border: OutlineInputBorder(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < groups.length; index++) ...[
              if (index > 0) const SizedBox(height: 12),
              if (groups.length > 1 || !groups[index].allowsMultiple) ...[
                Text(groups[index].label, style: labelStyle),
                const SizedBox(height: 6),
              ],
              if (groups[index].allowsMultiple)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final choice in groups[index].choices)
                      Semantics(
                        button: true,
                        selected: _isSelected(groups[index], choice),
                        label: choice.semanticLabel,
                        child: _ExploreMultiChoiceChip(
                          label: choice.label,
                          selected: _isSelected(groups[index], choice),
                          onSelected: (_) =>
                              onChoiceSelected(groups[index], choice),
                        ),
                      ),
                  ],
                )
              else
                _ExploreSegmentedChoiceGroup(
                  labels: [
                    for (final choice in groups[index].choices) choice.label,
                  ],
                  semanticLabels: [
                    for (final choice in groups[index].choices)
                      choice.semanticLabel,
                  ],
                  selectedIndex: _selectedIndex(groups[index]),
                  onSelected: (choiceIndex) => onChoiceSelected(
                    groups[index],
                    groups[index].choices[choiceIndex],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isSelected(
    ExploreExtensionControlGroup group,
    ExploreExtensionChoice choice,
  ) {
    final extension = choice.extension;
    if (extension != null) return selectedExtensions.contains(extension);

    return group.choices
        .where((candidate) => candidate.extension != null)
        .every(
          (candidate) => !selectedExtensions.contains(candidate.extension),
        );
  }

  int _selectedIndex(ExploreExtensionControlGroup group) {
    for (var index = 0; index < group.choices.length; index++) {
      if (_isSelected(group, group.choices[index])) return index;
    }
    return 0;
  }
}

class _ExploreSegmentedChoiceGroup extends StatelessWidget {
  const _ExploreSegmentedChoiceGroup({
    required this.labels,
    required this.semanticLabels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final List<String> semanticLabels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final radius = BorderRadius.circular(8);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Material(
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.70)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < labels.length; index++) ...[
              if (index > 0)
                SizedBox(
                  height: 40,
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.70),
                  ),
                ),
              _ExploreSegmentedChoice(
                label: labels[index],
                semanticLabel: semanticLabels[index],
                selected: index == selectedIndex,
                onTap: () => onSelected(index),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExploreSegmentedChoice extends StatelessWidget {
  const _ExploreSegmentedChoice({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: selected ? cs.onPrimaryContainer : cs.onSurface,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    );

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40, minWidth: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Center(
                  child: Text(label, maxLines: 1, style: labelStyle),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreMultiChoiceChip extends StatelessWidget {
  const _ExploreMultiChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: selected ? cs.onPrimaryContainer : cs.onSurface,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(
        color: selected
            ? Colors.transparent
            : cs.outlineVariant.withValues(alpha: 0.60),
      ),
    );

    return FilterChip(
      label: Text(label, style: labelStyle),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: true,
      checkmarkColor: cs.onPrimaryContainer,
      backgroundColor: cs.surfaceContainerLow,
      selectedColor: cs.primaryContainer,
      shape: shape,
    );
  }
}

class _ExploreKeyboard extends StatelessWidget {
  const _ExploreKeyboard({
    required this.config,
    required this.highlightedNotes,
    required this.markedNotes,
  });

  final HomeLayoutConfig config;
  final Set<int> highlightedNotes;
  final Set<int> markedNotes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final whiteKeyWidth = PianoGeometry.whiteKeyWidthForViewport(
          viewportWidth: constraints.maxWidth,
          visibleWhiteKeyCount: config.whiteKeyCount,
        );

        var height = whiteKeyWidth * config.whiteKeyAspectRatio;
        height = height.clamp(90.0, 200.0);

        return ScrollablePianoKeyboard(
          visibleWhiteKeyCount: config.whiteKeyCount,
          height: height,
          highlightedNoteNumbers: highlightedNotes,
          autoCenter: true,
          fullWhiteKeyCount: PianoGeometry.fullKeyboardWhiteKeyCount,
          lowestNoteNumber: PianoGeometry.fullKeyboardLowestMidi,
          markedNoteNumbers: markedNotes,
          showMiddleCMarker: true,
          middleCLabel: 'C',
          middleCLabelTextScale: config.middleCLabelTextScale,
        );
      },
    );
  }
}

class _ExploreMemberChip extends StatelessWidget {
  const _ExploreMemberChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sizeScale = InputDisplaySizing.noteScale(context);
    final verticalScale = InputDisplaySizing.noteVerticalScale(context);

    final labelStyle = theme.textTheme.titleMedium?.copyWith(
      color: active ? cs.onPrimaryContainer : cs.onSurface,
      fontWeight: active ? FontWeight.w700 : null,
    );
    final fontSize = labelStyle?.fontSize ?? 16.0;
    final defaultHeight = labelStyle?.height ?? 1.2;
    final extraVertical = ((defaultHeight - 1.0) * fontSize / 2).clamp(
      0.0,
      8.0,
    );
    final labelStrut = StrutStyle(
      fontSize: fontSize,
      height: 1.0,
      forceStrutHeight: true,
    );

    return Semantics(
      container: true,
      label: 'Chord member $label',
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: active ? cs.primaryContainer : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10 * sizeScale),
            border: Border.all(
              color: active
                  ? cs.primary.withValues(alpha: 0.82)
                  : cs.outlineVariant.withValues(alpha: 0.60),
              width: active ? 1.6 : 1.0,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 10 * sizeScale,
            vertical: (6 * verticalScale) + extraVertical,
          ),
          child: Text(label, strutStyle: labelStrut, style: labelStyle),
        ),
      ),
    );
  }
}
