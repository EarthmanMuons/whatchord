import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/midi/midi.dart';

class NoteChip extends ConsumerWidget {
  const NoteChip({super.key, required this.note});
  final ActiveNote note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final isPedalDown = ref.watch(isPedalDownProvider);

    final bgColor = cs.surfaceContainerLow;
    final fgColor = cs.onSurface;

    // Visual feedback for sustain state:
    // - Slightly darker borders when pedal is down
    // - Even darker/thicker borders for sustained notes
    final borderColor = note.isSustained
        ? cs.outlineVariant.withValues(alpha: 0.92)
        : cs.outlineVariant.withValues(alpha: isPedalDown ? 0.78 : 0.60);

    final borderWidth = note.isSustained ? 1.6 : 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        note.label,
        style: theme.textTheme.titleMedium?.copyWith(color: fgColor),
      ),
    );
  }
}
