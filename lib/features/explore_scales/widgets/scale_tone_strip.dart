import 'package:flutter/material.dart';

import 'package:whatchord/features/theory/theory.dart';

enum ScaleToneHighlight { none, member, playing }

class ScaleToneStrip extends StatelessWidget {
  const ScaleToneStrip({
    super.key,
    required this.harmony,
    required this.noteNameSystem,
    required this.playingPitchClasses,
    required this.memberPitchClasses,
  });

  final ScaleHarmony harmony;
  final NoteNameSystem noteNameSystem;
  final Set<int> playingPitchClasses;
  final Set<int> memberPitchClasses;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: 'Scale tones',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < harmony.toneNames.length; i++)
            _ScaleToneChip(
              label: noteDisplayLabel(
                harmony.toneNames[i],
                noteNameSystem: noteNameSystem,
              ),
              semanticLabel: noteSemanticLabel(
                harmony.toneNames[i],
                noteNameSystem: noteNameSystem,
              ),
              highlight: _highlightFor(harmony.pitchClasses[i]),
              colorScheme: cs,
              textStyle: textTheme.titleMedium,
            ),
        ],
      ),
    );
  }

  ScaleToneHighlight _highlightFor(int pitchClass) {
    if (playingPitchClasses.contains(pitchClass)) {
      return ScaleToneHighlight.playing;
    }
    if (memberPitchClasses.contains(pitchClass)) {
      return ScaleToneHighlight.member;
    }
    return ScaleToneHighlight.none;
  }
}

class _ScaleToneChip extends StatelessWidget {
  const _ScaleToneChip({
    required this.label,
    required this.semanticLabel,
    required this.highlight,
    required this.colorScheme,
    required this.textStyle,
  });

  final String label;
  final String semanticLabel;
  final ScaleToneHighlight highlight;
  final ColorScheme colorScheme;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final playing = highlight == ScaleToneHighlight.playing;
    final member = highlight == ScaleToneHighlight.member;

    final labelStyle = textStyle?.copyWith(
      color: playing ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
      fontWeight: playing ? FontWeight.w700 : null,
    );
    final fontSize = labelStyle?.fontSize ?? 16.0;
    final defaultHeight = labelStyle?.height ?? 1.2;
    final extraVertical = ((defaultHeight - 1.0) * fontSize / 2).clamp(
      0.0,
      8.0,
    );

    // Members of the selected chord get a thin blue outline; the filled blue
    // is reserved for active playback.
    final borderColor = playing
        ? colorScheme.primary.withValues(alpha: 0.82)
        : member
        ? colorScheme.primary
        : colorScheme.outlineVariant.withValues(alpha: 0.60);
    final borderWidth = playing
        ? 1.6
        : member
        ? 1.5
        : 1.0;

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: playing
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6 + extraVertical,
        ),
        child: Text(
          label,
          strutStyle: StrutStyle(
            fontSize: fontSize,
            height: 1.0,
            forceStrutHeight: true,
          ),
          style: labelStyle,
        ),
      ),
    );
  }
}
