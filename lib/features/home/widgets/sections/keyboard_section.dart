import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/input/input.dart';
import 'package:what_chord/features/piano/piano.dart';

import '../../models/home_layout_config.dart';

class KeyboardSection extends ConsumerWidget {
  const KeyboardSection({super.key, required this.config});
  final HomeLayoutConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundingMidiNotes = ref.watch(soundingNotesProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final whiteKeyWidth = width / config.whiteKeyCount;

        var height = whiteKeyWidth * config.whiteKeyAspectRatio;

        // Guardrails to prevent extremes.
        height = height.clamp(90.0, 200.0);

        return ScrollablePianoKeyboard(
          visibleWhiteKeyCount: config.whiteKeyCount,
          height: height,
          soundingMidiNotes: soundingMidiNotes,
          followInput: true,

          // Full 88-key span (white keys A0..C8).
          fullWhiteKeyCount: 52,
          fullFirstMidiNote: 21,

          // Landmark (no octave to avoid C3/C4 convention issues).
          showMiddleCLandmark: true,
          middleCLandmarkText: 'C',
        );
      },
    );
  }
}
