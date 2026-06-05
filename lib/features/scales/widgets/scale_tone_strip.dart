import 'package:flutter/material.dart';

import 'package:whatchord/core/core.dart';
import 'package:whatchord/features/theory/theory.dart';

class ScaleToneStrip extends StatelessWidget {
  const ScaleToneStrip({
    super.key,
    required this.harmony,
    required this.noteNameSystem,
    required this.showDegrees,
    required this.playingPitchClasses,
    required this.memberPitchClasses,
  });

  final ScaleHarmony harmony;
  final NoteNameSystem noteNameSystem;
  final bool showDegrees;
  final Set<int> playingPitchClasses;
  final Set<int> memberPitchClasses;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Scale tones',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < harmony.toneNames.length; i++) _buildChip(i),
        ],
      ),
    );
  }

  Widget _buildChip(int index) {
    final noteName = noteDisplayLabel(
      harmony.toneNames[index],
      noteNameSystem: noteNameSystem,
    );
    final degreeLabel = harmony.degrees[index].degreeLabel;
    final pitchClass = harmony.pitchClasses[index];

    final state = playingPitchClasses.contains(pitchClass)
        ? NoteChipState.fill
        : memberPitchClasses.contains(pitchClass)
        ? NoteChipState.outline
        : NoteChipState.plain;

    final noteSemantic = noteSemanticLabel(
      harmony.toneNames[index],
      noteNameSystem: noteNameSystem,
    );

    return NoteChip(
      label: showDegrees ? degreeLabel : noteName,
      alternateLabel: showDegrees ? noteName : degreeLabel,
      semanticLabel: '$noteSemantic, scale degree $degreeLabel',
      state: state,
    );
  }
}
