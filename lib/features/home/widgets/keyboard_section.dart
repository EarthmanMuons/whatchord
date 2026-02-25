import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/input/input.dart';
import 'package:whatchord/features/piano/piano.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../models/home_layout_config.dart';

class KeyboardSection extends ConsumerWidget {
  const KeyboardSection({super.key, required this.config});
  final HomeLayoutConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundingNoteNumbers = ref.watch(soundingNoteNumbersProvider);
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final whiteKeyWidth = PianoGeometry.whiteKeyWidthForViewport(
          viewportWidth: width,
          visibleWhiteKeyCount: config.whiteKeyCount,
        );

        var height = whiteKeyWidth * config.whiteKeyAspectRatio;

        // Guardrails to prevent extremes.
        height = height.clamp(90.0, 200.0);

        return ScrollablePianoKeyboard(
          visibleWhiteKeyCount: config.whiteKeyCount,
          height: height,

          // Highlight keys for notes that are sounding.
          highlightedNoteNumbers: soundingNoteNumbers,
          autoCenter: true,

          // Full 88-key span (white keys A0..C8).
          fullWhiteKeyCount: PianoGeometry.fullKeyboardWhiteKeyCount,
          lowestNoteNumber: PianoGeometry.fullKeyboardLowestMidi,

          markedNoteNumbers: markedNoteNumbers,

          // Middle C marker (no octave to avoid C3/C4 convention issues).
          showMiddleCMarker: true,
          middleCLabel: 'C',
          middleCLabelTextScale: config.middleCLabelTextScale,
        );
      },
    );
  }
}
