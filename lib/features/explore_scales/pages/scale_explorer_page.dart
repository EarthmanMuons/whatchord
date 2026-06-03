import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/core.dart';
import 'package:whatchord/features/audio/audio.dart';
import 'package:whatchord/features/home/home.dart';
import 'package:whatchord/features/piano/piano.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../providers/scale_preferences_notifier.dart';
import '../services/scale_preview_animation_controller.dart';
import '../services/scale_voicing.dart';
import '../widgets/scale_degree_chord_list.dart';
import '../widgets/scale_explorer_top_bar.dart';
import '../widgets/scale_kind_picker_sheet.dart';
import '../widgets/scale_tone_strip.dart';

const _canonicalTonics = <Tonic>[
  Tonic.c,
  Tonic.dFlat,
  Tonic.d,
  Tonic.eFlat,
  Tonic.e,
  Tonic.f,
  Tonic.gFlat,
  Tonic.g,
  Tonic.aFlat,
  Tonic.a,
  Tonic.bFlat,
  Tonic.b,
];

class ScaleExplorerPage extends ConsumerStatefulWidget {
  const ScaleExplorerPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const ScaleExplorerPage());
  }

  @override
  ConsumerState<ScaleExplorerPage> createState() => _ScaleExplorerPageState();
}

class _ScaleExplorerPageState extends ConsumerState<ScaleExplorerPage> {
  late final List<Tonic> _tonicChoices;
  late Tonic _tonic;
  late ScaleKind _kind;
  bool _showSevenths = false;
  int? _selectedOrdinal;

  late final ScalePreviewAnimationController _preview;
  ScalePreviewState _previewState = ScalePreviewState.idle;

  @override
  void initState() {
    super.initState();
    final tonality = ref.read(selectedTonalityProvider);
    // One spelling per pitch class, key-aware where it maps to a known tonic so
    // the seeded tonic keeps its spelling (e.g. F# in a sharp key).
    _tonicChoices = [
      for (var pc = 0; pc < 12; pc++)
        Tonic.tryFromLabel(pcToName(pc, tonality: tonality)) ??
            _canonicalTonics[pc],
    ];
    _tonic = _tonicChoices[tonality.tonic.pitchClass];
    _kind = tonality.isMajor ? ScaleKind.major : ScaleKind.aeolian;
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
    final markedNotes = <int>{
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
                        markedNotes: markedNotes,
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
          child: _ScaleHeader(scale: scale, noteNameSystem: noteNameSystem),
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

    final scaleButton = Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: _openScalePicker,
        icon: const Icon(Icons.tune, size: 18),
        label: Text(scale.kind.label),
      ),
    );

    final chordsHeader = _ChordsHeader(
      showSevenths: _showSevenths,
      onShowSeventhsChanged: (value) => setState(() => _showSevenths = value),
    );

    final chordList = ScaleDegreeChordList(
      harmony: harmony,
      tonality: Tonality(scale.tonic, TonalityMode.major),
      notation: notation,
      noteNameSystem: noteNameSystem,
      showSevenths: _showSevenths,
      selectedOrdinal: _selectedOrdinal,
      onDegreeTap: _onDegreeSelect,
      onDegreePlay: (degree) => _onDegreePlay(scale, degree),
    );

    if (isLandscape) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: 16),
                  toneRow,
                  const SizedBox(height: 16),
                  tonicWheel,
                  const SizedBox(height: 12),
                  scaleButton,
                ],
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                chordsHeader,
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 12),
                    child: chordList,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 16),
        toneRow,
        const SizedBox(height: 16),
        tonicWheel,
        const SizedBox(height: 12),
        scaleButton,
        const SizedBox(height: 20),
        chordsHeader,
        Expanded(child: SingleChildScrollView(child: chordList)),
      ],
    );
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
    setState(() {
      _tonic = tonic;
      _selectedOrdinal = null;
    });
  }

  void _onKindChanged(ScaleKind kind) {
    if (kind == _kind) return;
    _preview.cancel();
    setState(() {
      _kind = kind;
      _selectedOrdinal = null;
    });
  }

  void _openScalePicker() {
    unawaited(
      openScaleKindPicker(context, selected: _kind, onSelected: _onKindChanged),
    );
  }
}

class _ScaleHeader extends StatelessWidget {
  const _ScaleHeader({required this.scale, required this.noteNameSystem});

  final Scale scale;
  final NoteNameSystem noteNameSystem;

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

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: tonicLabel, style: tonicStyle),
          TextSpan(
            text: ' ${scale.kind.label.toLowerCase()}',
            style: restStyle,
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      // Forced strut keeps the line height constant whether or not the tonic
      // carries an accidental, so the play button doesn't shift while scrubbing.
      strutStyle: StrutStyle(
        fontSize: tonicStyle?.fontSize,
        height: 1.0,
        forceStrutHeight: true,
      ),
    );
  }
}

class _ChordsHeader extends StatelessWidget {
  const _ChordsHeader({
    required this.showSevenths,
    required this.onShowSeventhsChanged,
  });

  final bool showSevenths;
  final ValueChanged<bool> onShowSeventhsChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text('Diatonic chords', style: textTheme.titleMedium),
          ),
          Text('7ths', style: textTheme.labelLarge),
          Switch(value: showSevenths, onChanged: onShowSeventhsChanged),
        ],
      ),
    );
  }
}

class _ScaleKeyboard extends StatelessWidget {
  const _ScaleKeyboard({
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
        if (config.tightenForStatusBar) height -= 4;
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
