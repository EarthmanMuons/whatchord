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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chord Members', style: theme.textTheme.titleSmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final member in members)
              _ExploreMemberChip(label: toGlyphAccidentals(member)),
          ],
        ),
      ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Controls', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: controlWidth,
              child: _LabeledDropdown<int>(
                label: 'Root',
                value: state.rootPc,
                items: [
                  for (var pc = 0; pc < 12; pc++)
                    DropdownMenuItem<int>(
                      value: pc,
                      child: Text(
                        toGlyphAccidentals(pcToName(pc, tonality: tonality)),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  onRootChanged(value);
                },
              ),
            ),
            SizedBox(
              width: controlWidth,
              child: _LabeledDropdown<ChordQualityToken>(
                label: 'Quality',
                value: state.quality,
                items: [
                  for (final quality in ChordQualityToken.values)
                    DropdownMenuItem<ChordQualityToken>(
                      value: quality,
                      child: Text(
                        _titleCase(quality.label(ChordQualityLabelForm.long)),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  onQualityChanged(value);
                },
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
              child: _LabeledDropdown<int>(
                label: 'Bass',
                value: state.bassPc,
                items: [
                  for (final pc in _sortedPitchClasses(
                    memberPitchClasses,
                    identity.rootPc,
                  ))
                    DropdownMenuItem<int>(
                      value: pc,
                      child: Text(
                        pc == identity.rootPc
                            ? 'Root position'
                            : '/${toGlyphAccidentals(_spellBass(pc: pc, identity: identity, tonality: tonality))}',
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  onBassChanged(value);
                },
              ),
            ),
          ],
        ),
      ],
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final choice in groups[index].choices)
                    Semantics(
                      button: true,
                      selected: _isSelected(groups[index], choice),
                      label: choice.semanticLabel,
                      child: ChoiceChip(
                        label: Text(choice.label),
                        selected: _isSelected(groups[index], choice),
                        onSelected: (_) =>
                            onChoiceSelected(groups[index], choice),
                      ),
                    ),
                ],
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
}

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      isExpanded: true,
      menuMaxHeight: math.min(MediaQuery.sizeOf(context).height * 0.5, 360),
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
