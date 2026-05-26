import 'dart:async';

import 'package:flutter/material.dart';

import 'package:whatchord/features/theory/theory.dart';

import '../models/explore_chord_spec.dart';
import '../models/explore_chord_state.dart';
import '../services/explore_chord_options.dart';

class ExploreControls extends StatelessWidget {
  const ExploreControls({
    super.key,
    required this.state,
    required this.identity,
    required this.tonality,
    required this.noteNameSystem,
    required this.isLandscape,
    required this.onRootChanged,
    required this.onBaseQualityChanged,
    required this.onSeventhKindChanged,
    required this.onFifthAlterationChanged,
    required this.onStateChanged,
    required this.onBassChanged,
  });

  final ExploreChordState state;
  final ChordIdentity identity;
  final Tonality tonality;
  final NoteNameSystem noteNameSystem;
  final bool isLandscape;
  final ValueChanged<int> onRootChanged;
  final ValueChanged<ExploreBaseQuality> onBaseQualityChanged;
  final ValueChanged<ExploreSeventhKind> onSeventhKindChanged;
  final ValueChanged<ExploreFifthAlteration> onFifthAlterationChanged;
  final ValueChanged<ExploreChordState> onStateChanged;
  final ValueChanged<int> onBassChanged;

  @override
  Widget build(BuildContext context) {
    final extensionGroups = buildExploreExtensionControlGroupsForState(state);
    final seventhKindChoices = availableSeventhKindsFor(state.baseQuality);
    final fifthAlterationChoices = availableFifthAlterationsFor(
      baseQuality: state.baseQuality,
      seventhKind: state.seventhKind,
    );
    final memberPitchClasses =
        ChordPresentationBuilder.chordMemberPitchClassesFromMask(
          rootPc: identity.rootPc,
          presentIntervalsMask: identity.presentIntervalsMask,
        );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Explore controls',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final controlWidth = _controlWidthFor(
            availableWidth: constraints.maxWidth,
            isLandscape: isLandscape,
          );

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: controlWidth,
                child: _RootWheel(
                  value: state.rootPc,
                  tonality: tonality,
                  noteNameSystem: noteNameSystem,
                  onChanged: onRootChanged,
                ),
              ),
              SizedBox(
                width: controlWidth,
                child: _BaseQualitySelector(
                  value: state.baseQuality,
                  onChanged: onBaseQualityChanged,
                ),
              ),
              if (seventhKindChoices.length > 1 ||
                  fifthAlterationChoices.length > 1)
                SizedBox(
                  width: controlWidth,
                  child: _CoreTonesSelector(
                    baseQuality: state.baseQuality,
                    seventhKind: state.seventhKind,
                    seventhKindChoices: seventhKindChoices,
                    fifthAlteration: state.fifthAlteration,
                    fifthAlterationChoices: fifthAlterationChoices,
                    onSeventhKindChanged: onSeventhKindChanged,
                    onFifthAlterationChanged: onFifthAlterationChanged,
                  ),
                ),
              SizedBox(
                width: controlWidth,
                child: _ExtensionBuilder(
                  groups: extensionGroups,
                  selectedExtensions: state.extensions,
                  onChoiceSelected: (group, choice) {
                    onStateChanged(
                      selectExploreExtensionChoiceForState(
                        state: state,
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
                      _buildBassChoice(
                        pc: pc,
                        rootPc: identity.rootPc,
                        bassName: _spellBass(
                          pc: pc,
                          identity: identity,
                          tonality: tonality,
                        ),
                        noteNameSystem: noteNameSystem,
                      ),
                  ],
                  onChanged: onBassChanged,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _controlWidthFor({
    required double availableWidth,
    required bool isLandscape,
  }) {
    if (!isLandscape) return double.infinity;
    if (!availableWidth.isFinite) return 420;

    const gap = 12.0;
    const minTwoColumnWidth = 340.0;
    final twoColumnWidth = (availableWidth - gap) / 2;
    if (twoColumnWidth >= minTwoColumnWidth) return twoColumnWidth;

    return availableWidth;
  }

  List<int> _sortedPitchClasses(Set<int> pitchClasses, int rootPc) {
    final values = pitchClasses.toList();
    values.sort((a, b) {
      final intervalA = _normalizedPitchClass(a - rootPc);
      final intervalB = _normalizedPitchClass(b - rootPc);
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
    final interval = _normalizedPitchClass(pc - identity.rootPc);
    final role = identity.toneRolesByInterval[interval];
    return spellPitchClass(
      pc,
      tonality: tonality,
      chordRootName: root,
      role: role,
    );
  }

  int _normalizedPitchClass(int value) {
    final normalized = value % 12;
    return normalized < 0 ? normalized + 12 : normalized;
  }

  _BassChoice _buildBassChoice({
    required int pc,
    required int rootPc,
    required String bassName,
    required NoteNameSystem noteNameSystem,
  }) {
    if (pc == rootPc) {
      return _BassChoice(pc: pc, label: 'Root', semanticLabel: 'Root position');
    }

    return _BassChoice(
      pc: pc,
      label: '/${noteDisplayLabel(bassName, noteNameSystem: noteNameSystem)}',
      semanticLabel:
          'Bass ${noteSemanticLabel(bassName, noteNameSystem: noteNameSystem)}',
    );
  }
}

class _BaseQualitySelector extends StatelessWidget {
  const _BaseQualitySelector({required this.value, required this.onChanged});

  static const _choices = ExploreBaseQuality.values;

  final ExploreBaseQuality value;
  final ValueChanged<ExploreBaseQuality> onChanged;

  @override
  Widget build(BuildContext context) {
    return _OptionWheel<ExploreBaseQuality>(
      label: 'Quality',
      value: value,
      choices: _choices,
      labelFor: _baseQualityLabel,
      semanticLabelFor: _baseQualitySemanticLabel,
      onChanged: onChanged,
    );
  }
}

class _CoreTonesSelector extends StatelessWidget {
  const _CoreTonesSelector({
    required this.baseQuality,
    required this.seventhKind,
    required this.seventhKindChoices,
    required this.fifthAlteration,
    required this.fifthAlterationChoices,
    required this.onSeventhKindChanged,
    required this.onFifthAlterationChanged,
  });

  final ExploreBaseQuality baseQuality;
  final ExploreSeventhKind seventhKind;
  final List<ExploreSeventhKind> seventhKindChoices;
  final ExploreFifthAlteration fifthAlteration;
  final List<ExploreFifthAlteration> fifthAlterationChoices;
  final ValueChanged<ExploreSeventhKind> onSeventhKindChanged;
  final ValueChanged<ExploreFifthAlteration> onFifthAlterationChanged;

  @override
  Widget build(BuildContext context) {
    final showFifth = fifthAlterationChoices.length > 1;
    final showSeventh = seventhKindChoices.length > 1;
    final fifthIndex = _selectedIndex(fifthAlterationChoices, fifthAlteration);
    final seventhIndex = _selectedIndex(seventhKindChoices, seventhKind);

    return Semantics(
      container: true,
      label: 'Core tones',
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Core Tones',
          border: OutlineInputBorder(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showFifth)
              _CoreToneSegmentedControl(
                label: 'Fifth',
                value: _fifthAlterationSemanticLabel(
                  fifthAlterationChoices[fifthIndex],
                ),
                labels: [
                  for (final choice in fifthAlterationChoices)
                    theoryTokenDisplayLabel(_fifthAlterationLabel(choice)),
                ],
                semanticLabels: [
                  for (final choice in fifthAlterationChoices)
                    _fifthAlterationSemanticLabel(choice),
                ],
                selectedIndex: fifthIndex,
                onSelected: (index) =>
                    onFifthAlterationChanged(fifthAlterationChoices[index]),
              ),
            if (showFifth && showSeventh) const SizedBox(height: 12),
            if (showSeventh)
              _CoreToneSegmentedControl(
                label: 'Sixth / Seventh',
                value: _seventhKindSemanticLabel(
                  seventhKindChoices[seventhIndex],
                ),
                labels: [
                  for (final choice in seventhKindChoices)
                    theoryTokenDisplayLabel(
                      _seventhKindLabel(choice, baseQuality),
                    ),
                ],
                semanticLabels: [
                  for (final choice in seventhKindChoices)
                    _seventhKindSemanticLabel(choice),
                ],
                selectedIndex: seventhIndex,
                onSelected: (index) =>
                    onSeventhKindChanged(seventhKindChoices[index]),
              ),
          ],
        ),
      ),
    );
  }

  int _selectedIndex<T>(List<T> choices, T value) {
    final index = choices.indexOf(value);
    return index < 0 ? 0 : index;
  }
}

class _CoreToneSegmentedControl extends StatelessWidget {
  const _CoreToneSegmentedControl({
    required this.label,
    required this.value,
    required this.labels,
    required this.semanticLabels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final String label;
  final String value;
  final List<String> labels;
  final List<String> semanticLabels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: label,
      value: value,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.labelMedium),
          const SizedBox(height: 6),
          _ExploreSegmentedChoiceGroup(
            labels: labels,
            semanticLabels: semanticLabels,
            selectedIndex: selectedIndex,
            onSelected: onSelected,
          ),
        ],
      ),
    );
  }
}

class _OptionWheel<T> extends StatelessWidget {
  const _OptionWheel({
    required this.label,
    required this.value,
    required this.choices,
    required this.labelFor,
    required this.semanticLabelFor,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> choices;
  final String Function(T value) labelFor;
  final String Function(T value) semanticLabelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return _CyclicWheel<T>(
      label: label,
      value: value,
      choices: choices,
      displayLabelFor: (value) => theoryTokenDisplayLabel(labelFor(value)),
      semanticLabelFor: semanticLabelFor,
      targetItemWidth: 96,
      selectedMinWidth: 76,
      unselectedMinWidth: 64,
      selectedHorizontalPadding: 8,
      unselectedHorizontalPadding: 6,
      onChanged: onChanged,
    );
  }
}

class _CyclicWheel<T> extends StatefulWidget {
  const _CyclicWheel({
    required this.label,
    required this.value,
    required this.choices,
    required this.displayLabelFor,
    required this.semanticLabelFor,
    required this.targetItemWidth,
    required this.selectedMinWidth,
    required this.unselectedMinWidth,
    required this.selectedHorizontalPadding,
    required this.unselectedHorizontalPadding,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> choices;
  final String Function(T value) displayLabelFor;
  final String Function(T value) semanticLabelFor;
  final double targetItemWidth;
  final double selectedMinWidth;
  final double unselectedMinWidth;
  final double selectedHorizontalPadding;
  final double unselectedHorizontalPadding;
  final ValueChanged<T> onChanged;

  @override
  State<_CyclicWheel<T>> createState() => _CyclicWheelState<T>();
}

class _CyclicWheelState<T> extends State<_CyclicWheel<T>> {
  static const _initialLoop = 500;
  static const _wheelHeight = 64.0;
  static const _wheelContentPadding = EdgeInsets.fromLTRB(8, 10, 8, 6);

  PageController? _controller;
  double? _viewportFraction;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage =
        (_initialLoop * widget.choices.length) + _indexOf(widget.value);
  }

  @override
  void didUpdateWidget(covariant _CyclicWheel<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.choices != widget.choices) {
      _resetControllerToValue();
      return;
    }

    if (oldWidget.value == widget.value) return;

    final visiblePage = _visiblePage;
    if (_valueForPage(visiblePage) == widget.value) return;

    final targetPage = _nearestPageForValue(widget.value);
    _currentPage = targetPage;
    if (_controller?.hasClients != true) return;

    unawaited(
      _controller!.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedLabel = widget.semanticLabelFor(widget.value);
    return Semantics(
      container: true,
      label: widget.label,
      value: selectedLabel,
      increasedValue: widget.semanticLabelFor(_nextValue(widget.value)),
      decreasedValue: widget.semanticLabelFor(_previousValue(widget.value)),
      onIncrease: () => widget.onChanged(_nextValue(widget.value)),
      onDecrease: () => widget.onChanged(_previousValue(widget.value)),
      child: ExcludeSemantics(
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            contentPadding: _wheelContentPadding,
          ),
          child: SizedBox(
            height: _wheelHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final controller = _controllerForViewport(
                  _wheelViewportFraction(
                    viewportWidth: constraints.maxWidth,
                    targetItemWidth: widget.targetItemWidth,
                  ),
                );

                return Stack(
                  children: [
                    PageView.builder(
                      controller: controller,
                      onPageChanged: _handlePageChanged,
                      itemBuilder: (context, page) {
                        final value = _valueForPage(page);
                        return _WheelItem(
                          label: widget.displayLabelFor(value),
                          selected: value == widget.value,
                          selectedMinWidth: widget.selectedMinWidth,
                          unselectedMinWidth: widget.unselectedMinWidth,
                          selectedHorizontalPadding:
                              widget.selectedHorizontalPadding,
                          unselectedHorizontalPadding:
                              widget.unselectedHorizontalPadding,
                          onTap: () => _selectValue(value),
                        );
                      },
                    ),
                    const Positioned.fill(child: _WheelEdgeFades()),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  PageController _controllerForViewport(double viewportFraction) {
    final existing = _controller;
    if (existing != null &&
        !_viewportFractionChanged(_viewportFraction, viewportFraction)) {
      return existing;
    }

    final page = existing?.hasClients == true
        ? (existing?.page?.round() ?? _currentPage)
        : _currentPage;
    existing?.dispose();
    _currentPage = page;
    _viewportFraction = viewportFraction;
    return _controller = PageController(
      initialPage: _currentPage,
      viewportFraction: viewportFraction,
    );
  }

  void _handlePageChanged(int page) {
    _currentPage = page;
    final value = _valueForPage(page);
    if (value == widget.value) return;
    widget.onChanged(value);
  }

  void _selectValue(T value) {
    final controller = _controller;
    final targetPage = _nearestPageForValue(value);
    _currentPage = targetPage;
    if (controller?.hasClients == true) {
      unawaited(
        controller!.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        ),
      );
    }
    if (value != widget.value) widget.onChanged(value);
  }

  int _nearestPageForValue(T value) {
    final currentPage = _visiblePage;
    final currentIndex = _indexForPage(currentPage);
    var delta = _wrapIndex(_indexOf(value) - currentIndex);
    if (delta > widget.choices.length / 2) delta -= widget.choices.length;
    return currentPage + delta;
  }

  int get _visiblePage => _controller?.hasClients == true
      ? (_controller?.page?.round() ?? _currentPage)
      : _currentPage;

  T _valueForPage(int page) => widget.choices[_indexForPage(page)];

  T _nextValue(T value) {
    return widget.choices[(_indexOf(value) + 1) % widget.choices.length];
  }

  T _previousValue(T value) {
    return widget.choices[_wrapIndex(_indexOf(value) - 1)];
  }

  int _indexForPage(int page) => _wrapIndex(page);

  int _wrapIndex(int value) {
    final index = value % widget.choices.length;
    return index < 0 ? index + widget.choices.length : index;
  }

  int _indexOf(T value) {
    final index = widget.choices.indexOf(value);
    return index < 0 ? 0 : index;
  }

  void _resetControllerToValue() {
    _controller?.dispose();
    _controller = null;
    _viewportFraction = null;
    _currentPage =
        (_initialLoop * widget.choices.length) + _indexOf(widget.value);
  }
}

String _baseQualityLabel(ExploreBaseQuality quality) {
  return switch (quality) {
    ExploreBaseQuality.major => 'maj',
    ExploreBaseQuality.minor => 'min',
    ExploreBaseQuality.diminished => 'dim',
    ExploreBaseQuality.augmented => 'aug',
    ExploreBaseQuality.sus2 => 'sus2',
    ExploreBaseQuality.sus4 => 'sus4',
  };
}

String _baseQualitySemanticLabel(ExploreBaseQuality quality) {
  return switch (quality) {
    ExploreBaseQuality.major => 'Major',
    ExploreBaseQuality.minor => 'Minor',
    ExploreBaseQuality.diminished => 'Diminished',
    ExploreBaseQuality.augmented => 'Augmented',
    ExploreBaseQuality.sus2 => 'Suspended second',
    ExploreBaseQuality.sus4 => 'Suspended fourth',
  };
}

String _seventhKindLabel(
  ExploreSeventhKind kind,
  ExploreBaseQuality baseQuality,
) {
  return switch (kind) {
    ExploreSeventhKind.none => 'None',
    ExploreSeventhKind.sixth => switch (baseQuality) {
      ExploreBaseQuality.minor => 'min6',
      _ => 'maj6',
    },
    ExploreSeventhKind.dominant7 => '7',
    ExploreSeventhKind.major7 => 'maj7',
    ExploreSeventhKind.minor7 => 'min7',
    ExploreSeventhKind.minorMajor7 => 'minmaj7',
    ExploreSeventhKind.halfDiminished7 => 'hdim7',
    ExploreSeventhKind.diminished7 => 'dim7',
  };
}

String _seventhKindSemanticLabel(ExploreSeventhKind kind) {
  return switch (kind) {
    ExploreSeventhKind.none => 'No sixth or seventh',
    ExploreSeventhKind.sixth => 'Sixth',
    ExploreSeventhKind.dominant7 => 'Dominant seventh',
    ExploreSeventhKind.major7 => 'Major seventh',
    ExploreSeventhKind.minor7 => 'Minor seventh',
    ExploreSeventhKind.minorMajor7 => 'Minor-major seventh',
    ExploreSeventhKind.halfDiminished7 => 'Half-diminished seventh',
    ExploreSeventhKind.diminished7 => 'Diminished seventh',
  };
}

String _fifthAlterationLabel(ExploreFifthAlteration alteration) {
  return switch (alteration) {
    ExploreFifthAlteration.natural => '5',
    ExploreFifthAlteration.flat => 'b5',
    ExploreFifthAlteration.sharp => '#5',
  };
}

String _fifthAlterationSemanticLabel(ExploreFifthAlteration alteration) {
  return switch (alteration) {
    ExploreFifthAlteration.natural => 'Natural fifth',
    ExploreFifthAlteration.flat => 'Flat fifth',
    ExploreFifthAlteration.sharp => 'Sharp fifth',
  };
}

double _wheelViewportFraction({
  required double viewportWidth,
  required double targetItemWidth,
}) {
  if (!viewportWidth.isFinite || viewportWidth <= 0) return 1;
  return (targetItemWidth / viewportWidth).clamp(0.08, 0.92);
}

bool _viewportFractionChanged(double? previous, double next) {
  if (previous == null) return true;
  return (previous - next).abs() > 0.001;
}

class _RootWheel extends StatelessWidget {
  const _RootWheel({
    required this.value,
    required this.tonality,
    required this.noteNameSystem,
    required this.onChanged,
  });

  final int value;
  final Tonality tonality;
  final NoteNameSystem noteNameSystem;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _CyclicWheel<int>(
      label: 'Root',
      value: value,
      choices: const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
      displayLabelFor: _labelForPc,
      semanticLabelFor: _labelForPc,
      targetItemWidth: 72,
      selectedMinWidth: 46,
      unselectedMinWidth: 40,
      selectedHorizontalPadding: 8,
      unselectedHorizontalPadding: 4,
      onChanged: onChanged,
    );
  }

  String _labelForPc(int pc) {
    return noteDisplayLabel(
      pcToName(pc, tonality: tonality),
      noteNameSystem: noteNameSystem,
    );
  }
}

class _WheelItem extends StatelessWidget {
  const _WheelItem({
    required this.label,
    required this.selected,
    required this.selectedMinWidth,
    required this.unselectedMinWidth,
    required this.selectedHorizontalPadding,
    required this.unselectedHorizontalPadding,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double selectedMinWidth;
  final double unselectedMinWidth;
  final double selectedHorizontalPadding;
  final double unselectedHorizontalPadding;
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
                minWidth: selected ? selectedMinWidth : unselectedMinWidth,
                minHeight: 48,
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: selected
                          ? selectedHorizontalPadding
                          : unselectedHorizontalPadding,
                    ),
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

class _WheelEdgeFades extends StatelessWidget {
  const _WheelEdgeFades();

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
            child: _WheelFade(
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
            child: _WheelFade(
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

class _WheelFade extends StatelessWidget {
  const _WheelFade({
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
              if (groups.length > 1) ...[
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
