import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/core.dart';
import 'package:whatchord/features/audio/audio.dart';
import 'package:whatchord/features/home/home.dart';
import 'package:whatchord/features/piano/piano.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../models/scale_menu.dart';
import '../providers/scale_preferences_notifier.dart';
import '../services/scale_preview_animation_controller.dart';
import '../services/scale_voicing.dart';
import '../widgets/scale_degree_chord_list.dart';
import '../widgets/scale_explorer_top_bar.dart';
import '../widgets/scale_list_style.dart';
import '../widgets/scale_tone_strip.dart';

enum _ScaleView { chords, scales }

class ScaleExplorerPage extends ConsumerStatefulWidget {
  const ScaleExplorerPage({super.key, this.seedPresentation});

  /// Chord to pre-select a degree from when the page opens. When null the page
  /// falls back to the live sounding chord, so opening from the home page seeds
  /// the current performance. Explore Chords passes its built chord here so it
  /// seeds the same way rather than reaching back to stale live input.
  final ChordPresentation? seedPresentation;

  static Route<void> route({ChordPresentation? seedPresentation}) {
    return MaterialPageRoute<void>(
      builder: (_) => ScaleExplorerPage(seedPresentation: seedPresentation),
    );
  }

  @override
  ConsumerState<ScaleExplorerPage> createState() => _ScaleExplorerPageState();
}

class _ScaleExplorerPageState extends ConsumerState<ScaleExplorerPage> {
  late List<Tonic> _tonicChoices;
  late Tonic _tonic;
  late ScaleMenuEntry _scale;
  bool _showSevenths = false;
  int? _selectedOrdinal;
  _ScaleView _view = _ScaleView.chords;

  late final ScalePreviewAnimationController _preview;
  ScalePreviewState _previewState = ScalePreviewState.idle;

  ScaleKind get _kind => _scale.kind;

  @override
  void initState() {
    super.initState();
    final tonality = ref.read(selectedTonalityProvider);
    _scale = commonScaleEntry(
      tonality.isMajor ? ScaleKind.major : ScaleKind.aeolian,
    );
    _tonicChoices = tonicChoicesForKind(_kind);
    _tonic = _resolveTonic(
      tonality.tonic.pitchClass,
      exact: tonality.tonic,
      preferFlat: tonality.keySignature.prefersFlats,
    );
    _seedSelectionFromSoundingChord();
    _preview = ScalePreviewAnimationController(
      onChanged: (state) {
        if (!mounted) return;
        setState(() => _previewState = state);
      },
    );
  }

  @override
  void dispose() {
    _preview.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Scale(_tonic, _kind);
    final harmony = ScaleHarmonizer.harmonize(scale);
    final notation = ref.watch(chordNotationStyleProvider);
    final noteNameSystem = ref.watch(noteNameSystemProvider);
    final showDegrees = ref.watch(showScaleDegreesProvider);

    final selectedChord = _selectedChordMidi(scale, harmony);
    final playing = _previewState.isRunning;

    // During playback the keyboard tracks the sounding notes; at rest it holds
    // the selected chord (and is blank after a scale run, which clears the
    // selection).
    final keyboardNotes = playing ? _previewState.activeNotes : selectedChord;
    final playingPitchClasses = playing
        ? {for (final n in _previewState.activeNotes) n % 12}
        : const <int>{};
    // The selected chord's members keep their outline throughout playback; the
    // rolling fill (playing) layers on top per chip.
    final memberPitchClasses = {for (final n in selectedChord) n % 12};

    final scalePitchClasses = scale.pitchClasses.toSet();
    final scaleNotes = <int>{
      for (
        int midi = PianoGeometry.fullKeyboardLowestMidi;
        midi <= PianoGeometry.fullKeyboardHighestMidi;
        midi++
      )
        if (scalePitchClasses.contains(midi % 12)) midi,
    };

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
                  child: ScaleExplorerTopBar(
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
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalInset,
                            16,
                            horizontalInset,
                            12,
                          ),
                          child: _buildContent(
                            scale: scale,
                            harmony: harmony,
                            notation: notation,
                            noteNameSystem: noteNameSystem,
                            showDegrees: showDegrees,
                            playingPitchClasses: playingPitchClasses,
                            memberPitchClasses: memberPitchClasses,
                            isLandscape: isLandscape,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      _ScaleKeyboard(
                        config: config,
                        highlightedNotes: keyboardNotes,
                        scaleNotes: scaleNotes,
                        tonicPitchClass: scale.tonic.pitchClass,
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

  Widget _buildContent({
    required Scale scale,
    required ScaleHarmony harmony,
    required ChordNotationStyle notation,
    required NoteNameSystem noteNameSystem,
    required bool showDegrees,
    required Set<int> playingPitchClasses,
    required Set<int> memberPitchClasses,
    required bool isLandscape,
  }) {
    final header = Row(
      children: [
        CircularPlayButton(
          label: 'Play scale',
          tapHint: 'Play the scale up and down',
          onPressed: () => _onPlayScale(scale),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ScaleHeader(
            scale: scale,
            kindLabel: _scale.headerLabel,
            noteNameSystem: noteNameSystem,
            functionLabel: _selectedFunctionLabel(scale),
          ),
        ),
      ],
    );

    final toneRow = Row(
      children: [
        NameDegreeToggleButton(
          showDegrees: showDegrees,
          onPressed: () => unawaited(
            ref
                .read(showScaleDegreesProvider.notifier)
                .setShowDegrees(!showDegrees),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ScaleToneStrip(
            harmony: harmony,
            noteNameSystem: noteNameSystem,
            showDegrees: showDegrees,
            playingPitchClasses: playingPitchClasses,
            memberPitchClasses: memberPitchClasses,
          ),
        ),
      ],
    );

    final tonicWheel = CyclicWheel<Tonic>(
      label: 'Tonic',
      value: _tonic,
      choices: _tonicChoices,
      displayLabelFor: (tonic) =>
          noteDisplayLabel(tonic.label, noteNameSystem: noteNameSystem),
      semanticLabelFor: (tonic) =>
          noteSemanticLabel(tonic.label, noteNameSystem: noteNameSystem),
      targetItemWidth: 72,
      selectedMinWidth: 46,
      unselectedMinWidth: 40,
      selectedHorizontalPadding: 8,
      unselectedHorizontalPadding: 4,
      onChanged: _onTonicChanged,
    );

    final viewControl = Row(
      children: [
        SegmentedButton<_ScaleView>(
          showSelectedIcon: false,
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          segments: const [
            ButtonSegment(
              value: _ScaleView.chords,
              icon: Icon(Icons.music_note),
              label: Text('Chords'),
            ),
            ButtonSegment(
              value: _ScaleView.scales,
              icon: Icon(Icons.stairs_outlined),
              label: Text('Scales'),
            ),
          ],
          selected: {_view},
          onSelectionChanged: (selection) =>
              setState(() => _view = selection.first),
        ),
        const Spacer(),
        if (_view == _ScaleView.chords)
          _SeventhsToggle(
            showSevenths: _showSevenths,
            onShowSeventhsChanged: (value) =>
                setState(() => _showSevenths = value),
          ),
      ],
    );

    // Rendered bare (no inner scroll) so it folds into the unified lower-section
    // scroll alongside the tonic wheel and view toggle.
    final chordsList = ScaleDegreeChordList(
      harmony: harmony,
      tonality: Tonality(scale.tonic, TonalityMode.major),
      notation: notation,
      noteNameSystem: noteNameSystem,
      showSevenths: _showSevenths,
      selectedOrdinal: _selectedOrdinal,
      onDegreeTap: _onDegreeSelect,
      onDegreePlay: (degree) => _onDegreePlay(scale, degree),
    );

    // The last row of each section has no separator, so a section's list ends
    // on a clean edge before the next header.
    final lastInSection = {
      for (final section in ScaleSection.values)
        scaleMenuEntries.lastWhere((entry) => entry.section == section),
    };

    PickerList<ScaleMenuEntry> buildScalePicker({required bool scrollable}) {
      return PickerList<ScaleMenuEntry>(
        entries: [
          for (final section in ScaleSection.values) ...[
            PickerListHeader<ScaleMenuEntry>(section.title),
            for (final entry in scaleMenuEntries.where(
              (entry) => entry.section == section,
            ))
              PickerListItem(entry),
          ],
        ],
        selected: _scale,
        itemExtent: 48,
        headerExtent: 44,
        scrollable: scrollable,
        onChanged: _onScaleChanged,
        itemBuilder: (context, entry, isSelected) => _ScaleKindRow(
          label: entry.label,
          selected: isSelected,
          showSeparator: !lastInSection.contains(entry),
        ),
        headerBuilder: (context, title) {
          final cs = Theme.of(context).colorScheme;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              ScaleListStyle.headerRule(cs),
            ],
          );
        },
      );
    }

    if (isLandscape) {
      // Both columns scroll independently, matching Explore Chords: the left
      // holds the static header and note chips, the right holds the controls.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 6,
            child: FadedScrollView(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [header, const SizedBox(height: 16), toneRow],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: _buildLowerSection(
              isLandscape: true,
              tonicWheel: tonicWheel,
              viewControl: viewControl,
              chordsList: chordsList,
              buildScalePicker: buildScalePicker,
              // Top inset keeps the tonic wheel's floating label clear of the
              // scroll view's clip edge.
              padding: const EdgeInsets.only(left: 12, top: 8),
            ),
          ),
        ],
      );
    }

    // Only the header and note chips stay pinned; everything below scrolls so
    // the layout holds up on shorter screens.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 16),
        toneRow,
        const SizedBox(height: 16),
        Expanded(
          child: _buildLowerSection(
            isLandscape: false,
            tonicWheel: tonicWheel,
            viewControl: viewControl,
            chordsList: chordsList,
            buildScalePicker: buildScalePicker,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  /// Builds the region beneath the note chips. In landscape, where vertical room
  /// is scarce, the tonic wheel, view toggle, and list scroll together as one
  /// unit. In portrait the tonic wheel and view toggle stay pinned and the list
  /// takes its own scroll, so the controls always stay on screen.
  Widget _buildLowerSection({
    required bool isLandscape,
    required Widget tonicWheel,
    required Widget viewControl,
    required Widget chordsList,
    required PickerList<ScaleMenuEntry> Function({required bool scrollable})
    buildScalePicker,
    required EdgeInsetsGeometry padding,
  }) {
    final controls = <Widget>[
      tonicWheel,
      const SizedBox(height: 16),
      viewControl,
      const SizedBox(height: 8),
    ];

    if (isLandscape) {
      final list = _view == _ScaleView.chords
          ? chordsList
          : buildScalePicker(scrollable: false);
      return FadedScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [...controls, list],
        ),
      );
    }

    final list = _view == _ScaleView.chords
        ? FadedScrollView(
            maintainVisualPositionOnResize: true,
            child: chordsList,
          )
        : buildScalePicker(scrollable: true);
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...controls,
          Expanded(child: list),
        ],
      ),
    );
  }

  /// Pre-selects the degree of the seeding chord so opening the explorer lands
  /// on that chord (e.g. a G7 in C major seeds the V7). The chord is the one
  /// passed in via [ScaleExplorerPage.seedPresentation], or the live sounding
  /// chord when none was given. Only seeds when the chord is diatonic to the
  /// seeded scale, i.e. its source matches the seeded mode; otherwise nothing
  /// is selected and the page opens on the bare tonic/mode.
  void _seedSelectionFromSoundingChord() {
    final presentation =
        widget.seedPresentation ?? ref.read(chordPresentationProvider);
    final analysis = presentation?.scaleDegreeAnalysis;
    if (presentation == null || analysis == null) return;

    final seededSource = _kind == ScaleKind.major
        ? ScaleDegreeSource.major
        : ScaleDegreeSource.naturalMinor;
    if (analysis.source != seededSource) return;

    _selectedOrdinal = analysis.degree.index + 1;
    _showSevenths = presentation.identity.quality.isSeventhFamily;
  }

  /// Sentence-case "role, tendency" line for the selected degree (e.g.
  /// "Dominant, pulls toward I"), or null when nothing is selected. Outside the
  /// major and minor families the tendency is dropped and only the role shows.
  String? _selectedFunctionLabel(Scale scale) {
    final ordinal = _selectedOrdinal;
    if (ordinal == null) return null;

    final function = scaleDegreeFunction(scale, ordinal);
    final tendency = function.tendency;
    final text = tendency == null
        ? function.name
        : '${function.name}, $tendency';
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  Set<int> _selectedChordMidi(Scale scale, ScaleHarmony harmony) {
    final ordinal = _selectedOrdinal;
    if (ordinal == null) return const <int>{};

    final degree = harmony.degrees[ordinal - 1];
    return degreeChordMidi(scale, degree, seventh: _showSevenths).toSet();
  }

  void _onDegreeSelect(ScaleDegreeHarmony degree) {
    _preview.cancel();
    setState(() {
      _selectedOrdinal = _selectedOrdinal == degree.ordinal
          ? null
          : degree.ordinal;
    });
  }

  void _onDegreePlay(Scale scale, ScaleDegreeHarmony degree) {
    setState(() => _selectedOrdinal = degree.ordinal);
    final notes = degreeChordMidi(scale, degree, seventh: _showSevenths);
    _preview.startChord(notes);
    ref.read(audioMonitorNotifier.notifier).playRolledPreviewNotes(notes);
  }

  void _onPlayScale(Scale scale) {
    setState(() => _selectedOrdinal = null);
    final notes = scaleRunMidi(scale);
    _preview.startRun(notes);
    ref.read(audioMonitorNotifier.notifier).playSequencePreviewNotes(notes);
  }

  void _onTonicChanged(Tonic tonic) {
    if (tonic == _tonic) return;
    _preview.cancel();
    // The selected degree is mode-relative, so it stays valid as the tonic
    // moves; keep it so scrubbing transposes the selected chord.
    setState(() => _tonic = tonic);
  }

  void _onScaleChanged(ScaleMenuEntry entry) {
    if (entry == _scale) return;
    _preview.cancel();
    setState(() {
      final pitchClass = _tonic.pitchClass;
      // The selected ordinal names a scale-degree position, so keep it only
      // when the new scale has the same number of degrees; otherwise the
      // position no longer maps (e.g. a future non-heptatonic scale).
      if (entry.kind.intervals.length != _scale.kind.intervals.length) {
        _selectedOrdinal = null;
      }
      _scale = entry;
      // The valid spellings differ by mode (e.g. Cb major but not Cb lydian),
      // so rebuild the choices and keep the root pitch class, re-spelled to a
      // tonic this mode actually offers.
      _tonicChoices = tonicChoicesForKind(entry.kind);
      _tonic = _resolveTonic(
        pitchClass,
        exact: _tonic,
        preferFlat: _tonic.isFlat,
      );
    });
  }

  /// Picks a tonic for [pitchClass] from the current [_tonicChoices], keeping
  /// [exact] when it is still offered and otherwise honoring the [preferFlat]
  /// spelling preference for enharmonic pairs.
  Tonic _resolveTonic(
    int pitchClass, {
    Tonic? exact,
    required bool preferFlat,
  }) {
    if (exact != null && _tonicChoices.contains(exact)) return exact;

    final matches = _tonicChoices
        .where((tonic) => tonic.pitchClass == pitchClass)
        .toList();
    if (matches.isEmpty) return _tonicChoices.first;

    for (final tonic in matches) {
      if (preferFlat ? tonic.isFlat : tonic.isSharp) return tonic;
    }
    return matches.first;
  }
}

class _ScaleHeader extends StatelessWidget {
  const _ScaleHeader({
    required this.scale,
    required this.kindLabel,
    required this.noteNameSystem,
    required this.functionLabel,
  });

  final Scale scale;

  /// The selected entry's name, already cased for a heading after the tonic
  /// (e.g. "major" or "Ionian"), so the header matches the picked row rather
  /// than the kind's single conventional label.
  final String kindLabel;

  final NoteNameSystem noteNameSystem;

  /// Role and resolution tendency of the selected degree, or null when none is
  /// selected (the line is still laid out so the header height stays fixed).
  final String? functionLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final baseStyle = textTheme.headlineSmall?.copyWith(height: 1.0);
    final tonicStyle = baseStyle?.copyWith(
      color: cs.onSurface,
      fontWeight: FontWeight.w500,
      fontSize: (baseStyle.fontSize ?? 20) + 6,
    );
    final restStyle = baseStyle?.copyWith(
      color: cs.onSurface.withValues(alpha: 0.74),
    );

    final tonicLabel = noteDisplayLabel(
      scale.tonic.label,
      noteNameSystem: noteNameSystem,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: tonicLabel, style: tonicStyle),
              TextSpan(text: ' $kindLabel', style: restStyle),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          // Forced strut keeps the line height constant whether or not the
          // tonic carries an accidental, so the play button doesn't shift while
          // scrubbing.
          strutStyle: StrutStyle(
            fontSize: tonicStyle?.fontSize,
            height: 1.0,
            forceStrutHeight: true,
          ),
        ),
        const SizedBox(height: 6),
        // Always rendered (a space when empty) so selecting or clearing a
        // degree never changes the header height.
        Text(
          functionLabel ?? ' ',
          style: textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          strutStyle: StrutStyle(
            fontSize: textTheme.bodyLarge?.fontSize,
            forceStrutHeight: true,
          ),
        ),
      ],
    );
  }
}

class _ScaleKindRow extends StatelessWidget {
  const _ScaleKindRow({
    required this.label,
    required this.selected,
    required this.showSeparator,
  });

  final String label;
  final bool selected;
  final bool showSeparator;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? ScaleListStyle.selectedRow(cs) : null,
        border: showSeparator
            ? Border(bottom: ScaleListStyle.separatorSide(cs))
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: textTheme.titleMedium?.copyWith(
            color: ScaleListStyle.rowText(cs, selected: selected),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SeventhsToggle extends StatelessWidget {
  const _SeventhsToggle({
    required this.showSevenths,
    required this.onShowSeventhsChanged,
  });

  final bool showSevenths;
  final ValueChanged<bool> onShowSeventhsChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('7ths', style: textTheme.labelLarge),
        Switch(value: showSevenths, onChanged: onShowSeventhsChanged),
      ],
    );
  }
}

class _ScaleKeyboard extends StatelessWidget {
  const _ScaleKeyboard({
    required this.config,
    required this.highlightedNotes,
    required this.scaleNotes,
    required this.tonicPitchClass,
  });

  final HomeLayoutConfig config;
  final Set<int> highlightedNotes;
  final Set<int> scaleNotes;
  final int tonicPitchClass;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final whiteKeyWidth = PianoGeometry.whiteKeyWidthForViewport(
          viewportWidth: constraints.maxWidth,
          visibleWhiteKeyCount: config.whiteKeyCount,
        );

        var height = whiteKeyWidth * config.whiteKeyAspectRatio;
        if (config.tightenForStatusBar) height -= 4;
        height = height.clamp(90.0, 200.0);

        return ScrollablePianoKeyboard(
          visibleWhiteKeyCount: config.whiteKeyCount,
          height: height,
          highlightedNoteNumbers: highlightedNotes,
          autoCenter: true,
          fullWhiteKeyCount: PianoGeometry.fullKeyboardWhiteKeyCount,
          lowestNoteNumber: PianoGeometry.fullKeyboardLowestMidi,
          scaleNoteNumbers: scaleNotes,
          tonicPitchClass: tonicPitchClass,
          showMiddleCMarker: true,
          middleCLabel: 'C',
          middleCLabelTextScale: config.middleCLabelTextScale,
        );
      },
    );
  }
}
