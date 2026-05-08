import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/input/input.dart';
import 'package:whatchord/features/midi/midi.dart';
import 'package:whatchord/features/onboarding/onboarding.dart';
import 'package:whatchord/features/piano/piano.dart';
import 'package:whatchord/features/settings/settings.dart';
import 'package:whatchord/features/theory/domain/theory_domain.dart';
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
  late ExploreChordState _state;

  @override
  void initState() {
    super.initState();
    _state = ExploreChordState.fromIdentity(widget.seedIdentity);
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
      setState(() {
        final next = _state.copyWith(rootPc: value);
        _state = _withValidBass(next);
      });
    }

    void onQualityChanged(ChordQualityToken value) {
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
                  child: _ExploreTopBar(
                    horizontalInset: horizontalInset,
                    onOpenMidiSettings: () {
                      unawaited(
                        ref
                            .read(midiSettingsOnboardingProvider.notifier)
                            .markSeen(),
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MidiSettingsPage(),
                        ),
                      );
                    },
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
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.only(
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
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 6,
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.only(
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
                            : SingleChildScrollView(
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
                                    ),
                                    const SizedBox(height: 20),
                                    _ExploreControls(
                                      state: _state,
                                      identity: identity,
                                      tonality: tonality,
                                      isLandscape: false,
                                      onRootChanged: onRootChanged,
                                      onQualityChanged: onQualityChanged,
                                      onExtensionsChanged: onExtensionsChanged,
                                      onBassChanged: onBassChanged,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      TonalityBarView(
                        height: kToolbarHeight,
                        tonality: tonality,
                        degree: presentation.scaleDegree,
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
                        highlightedNotes: presentation.normalizedVoicing
                            .toSet(),
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
}

class _ExploreMidiAction extends StatelessWidget {
  const _ExploreMidiAction({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return MidiStatusIcon(
      onPressed: () {
        unawaited(ref.read(midiSettingsOnboardingProvider.notifier).markSeen());
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const MidiSettingsPage()),
        );
      },
    );
  }
}

class _ExploreTopBar extends ConsumerWidget {
  const _ExploreTopBar({
    required this.horizontalInset,
    required this.onOpenMidiSettings,
  });

  final double horizontalInset;
  final VoidCallback onOpenMidiSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleLarge;

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
              IconButton(
                tooltip: 'Back',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Explore',
                  style: titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              _ExploreMidiAction(ref: ref),
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

class _ExploreSummary extends StatelessWidget {
  const _ExploreSummary({required this.presentation});

  final ChordPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      header: true,
      label: presentation.longLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            toSmufl(presentation.symbol.toString()),
            style: textTheme.headlineMedium?.copyWith(
              color: colorScheme.onSurface,
              fontFamilyFallback: const ['Bravura'],
              height: 1.0,
            ),
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

class _ChordMembersSection extends StatelessWidget {
  const _ChordMembersSection({required this.members});

  final List<String> members;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Chord members',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final member in members)
            _ExploreMemberChip(label: toGlyphAccidentals(member)),
        ],
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
            contentPadding: EdgeInsets.fromLTRB(8, 12, 8, 8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 72,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _controller,
                      onPageChanged: _handlePageChanged,
                      itemBuilder: (context, page) {
                        final quality = _qualityForPage(page);
                        return _QualityWheelItem(
                          label: quality.label(
                            ChordQualityLabelForm.standalone,
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
              const SizedBox(height: 4),
              Center(
                child: Text(
                  _titleCase(selectedLabel),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
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
                minHeight: selected ? 48 : 44,
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
            contentPadding: EdgeInsets.fromLTRB(8, 12, 8, 8),
          ),
          child: SizedBox(
            height: 72,
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
                minHeight: selected ? 48 : 44,
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
              Text(groups[index].label, style: labelStyle),
              const SizedBox(height: 6),
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
  const _ExploreMemberChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sizeScale = InputDisplaySizing.noteScale(context);
    final verticalScale = InputDisplaySizing.noteVerticalScale(context);

    final labelStyle = theme.textTheme.titleMedium?.copyWith(
      color: cs.onSurface,
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10 * sizeScale),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.60),
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 10 * sizeScale,
              vertical: (6 * verticalScale) + extraVertical,
            ),
            child: Text(label, strutStyle: labelStrut, style: labelStyle),
          ),
        ),
      ),
    );
  }
}

String _titleCase(String value) {
  return value
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');
}
