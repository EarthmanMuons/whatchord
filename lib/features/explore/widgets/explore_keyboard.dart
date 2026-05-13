import 'package:flutter/material.dart';

import 'package:whatchord/features/home/home.dart';
import 'package:whatchord/features/piano/piano.dart';

class ExploreKeyboard extends StatelessWidget {
  const ExploreKeyboard({
    super.key,
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
