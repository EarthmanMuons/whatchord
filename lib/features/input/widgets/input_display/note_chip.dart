import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sounding_note.dart';
import '../../providers/pedal_state_provider.dart';
import 'input_display_sizing.dart';

class NoteChip extends ConsumerWidget {
  const NoteChip({super.key, required this.note});
  final SoundingNote note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sizeScale = InputDisplaySizing.noteScale(context);
    final verticalScale = InputDisplaySizing.noteVerticalScale(context);

    final isPedalDown = ref.watch(
      inputPedalStateProvider.select((s) => s.isDown),
    );

    final bgColor = cs.surfaceContainerLow;
    final fgColor = cs.onSurface;

    // Visual feedback for sustain state:
    // - Slightly darker borders when pedal is down
    // - Even darker/thicker borders for sustained notes
    final borderColor = note.isSustained
        ? cs.outlineVariant.withValues(alpha: 0.92)
        : cs.outlineVariant.withValues(alpha: isPedalDown ? 0.78 : 0.60);

    final borderWidth = note.isSustained ? 1.6 : 1.0;
    final labelStyle = theme.textTheme.titleMedium?.copyWith(color: fgColor);
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
      label: 'Note ${note.label}',
      value: note.isSustained ? 'Sustained' : 'Pressed',
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10 * sizeScale),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 10 * sizeScale,
            vertical: (6 * verticalScale) + extraVertical,
          ),
          child: Text(note.label, strutStyle: labelStrut, style: labelStyle),
        ),
      ),
    );
  }
}
