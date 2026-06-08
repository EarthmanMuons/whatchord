import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/input/input.dart';
import 'package:whatchord/features/piano/piano.dart';

import '../models/home_layout_config.dart';

class KeyboardSection extends ConsumerWidget {
  const KeyboardSection({super.key, required this.config});
  final HomeLayoutConfig config;

  /// Resolved keyboard height for a given viewport width. Shared so the lookup
  /// pad can occupy the exact same footprint when it swaps in.
  static double heightForWidth(double width, HomeLayoutConfig config) {
    final whiteKeyWidth = PianoGeometry.whiteKeyWidthForViewport(
      viewportWidth: width,
      visibleWhiteKeyCount: config.whiteKeyCount,
    );

    var height = whiteKeyWidth * config.whiteKeyAspectRatio;
    if (config.tightenForStatusBar) height -= 4;

    // Guardrails to prevent extremes.
    return height.clamp(90.0, 200.0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Live notes only: the pad covers the keyboard in lookup mode, so it must
    // not react to (and re-center on) the lookup voicing.
    final soundingNoteNumbers = ref.watch(liveSoundingNoteNumbersProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = heightForWidth(constraints.maxWidth, config);

        return ScrollablePianoKeyboard(
          visibleWhiteKeyCount: config.whiteKeyCount,
          height: height,

          // Highlight keys for notes that are sounding.
          highlightedNoteNumbers: soundingNoteNumbers,
          autoCenter: true,

          // Full 88-key span (white keys A0..C8).
          fullWhiteKeyCount: PianoGeometry.fullKeyboardWhiteKeyCount,
          lowestNoteNumber: PianoGeometry.fullKeyboardLowestMidi,

          // Middle C marker (no octave to avoid C3/C4 convention issues).
          showMiddleCMarker: true,
          middleCLabel: 'C',
          middleCLabelTextScale: config.middleCLabelTextScale,
        );
      },
    );
  }
}
