import 'package:flutter/material.dart';

import 'package:whatchord/core/core.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../models/explore_chord_spec.dart';
import '../models/explore_chord_state.dart';
import '../models/explore_root.dart';
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
    required this.onExtensionsChanged,
    required this.onBassChanged,
  });

  final ExploreChordState state;
  final ChordIdentity identity;
  final Tonality tonality;
  final NoteNameSystem noteNameSystem;
  final bool isLandscape;
  final ValueChanged<ExploreRoot> onRootChanged;
  final ValueChanged<ExploreBaseQuality> onBaseQualityChanged;
  final ValueChanged<ExploreSeventhKind> onSeventhKindChanged;
  final ValueChanged<ExploreFifthAlteration> onFifthAlterationChanged;
  final ValueChanged<Set<ChordExtension>> onExtensionsChanged;
  final ValueChanged<int> onBassChanged;

  @override
  Widget build(BuildContext context) {
    final extensionGroups = buildExploreExtensionControlGroups(state.quality);
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
                  value: state.root,
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
                      _buildBassChoice(
                        pc: pc,
                        rootPc: identity.rootPc,
                        bassName: _spellBass(
                          pc: pc,
                          identity: identity,
                          tonality: tonality,
                          rootName: state.root.label,
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
    required String rootName,
  }) {
    final interval = _normalizedPitchClass(pc - identity.rootPc);
    final role = identity.toneRolesByInterval[interval];
    return spellPitchClass(
      pc,
      tonality: tonality,
      chordRootName: rootName,
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
        child: AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                transitionBuilder: _coreToneTransition,
                child: showFifth
                    ? _CoreToneSegmentedControl(
                        key: const ValueKey('fifth'),
                        label: 'Fifth',
                        value: _fifthAlterationSemanticLabel(
                          fifthAlterationChoices[fifthIndex],
                        ),
                        labels: [
                          for (final choice in fifthAlterationChoices)
                            theoryTokenDisplayLabel(
                              _fifthAlterationLabel(choice),
                            ),
                        ],
                        semanticLabels: [
                          for (final choice in fifthAlterationChoices)
                            _fifthAlterationSemanticLabel(choice),
                        ],
                        selectedIndex: fifthIndex,
                        onSelected: (index) => onFifthAlterationChanged(
                          fifthAlterationChoices[index],
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('no-fifth')),
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
      ),
    );
  }

  Widget _coreToneTransition(Widget child, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      alignment: AlignmentDirectional.topStart,
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  int _selectedIndex<T>(List<T> choices, T value) {
    final index = choices.indexOf(value);
    return index < 0 ? 0 : index;
  }
}

class _CoreToneSegmentedControl extends StatelessWidget {
  const _CoreToneSegmentedControl({
    super.key,
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
    return CyclicWheel<T>(
      label: label,
      value: value,
      choices: choices,
      displayLabelFor: (value) => theoryTokenDisplayLabel(labelFor(value)),
      semanticLabelFor: semanticLabelFor,
      onChanged: onChanged,
    );
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

class _RootWheel extends StatelessWidget {
  const _RootWheel({
    required this.value,
    required this.noteNameSystem,
    required this.onChanged,
  });

  final ExploreRoot value;
  final NoteNameSystem noteNameSystem;
  final ValueChanged<ExploreRoot> onChanged;

  @override
  Widget build(BuildContext context) {
    return CyclicWheel<ExploreRoot>(
      label: 'Root',
      value: value,
      choices: exploreRootChoices,
      displayLabelFor: (root) =>
          noteDisplayLabel(root.label, noteNameSystem: noteNameSystem),
      semanticLabelFor: (root) =>
          noteSemanticLabel(root.label, noteNameSystem: noteNameSystem),
      targetItemWidth: 72,
      selectedMinWidth: 46,
      unselectedMinWidth: 40,
      selectedHorizontalPadding: 8,
      unselectedHorizontalPadding: 4,
      onChanged: onChanged,
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
