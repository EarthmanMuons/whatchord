import 'package:flutter/material.dart';

import '../presentation/midi_connection_presentation.dart';

import '../providers/midi_connection_notifier.dart';

class MidiStatusCard extends StatelessWidget {
  const MidiStatusCard({super.key, required this.presentation});

  final MidiConnectionPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final titleStyle = theme.textTheme.titleMedium;
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: cs.onSurfaceVariant,
    );

    // Always a list (possibly empty) so the rendering code is simple.
    final subtitleLines = <String>[
      if (presentation.phase == MidiConnectionPhase.retrying &&
          presentation.attempt != null)
        'Attempt ${presentation.attempt}',
      if (presentation.phase == MidiConnectionPhase.retrying &&
          presentation.nextDelay != null)
        'Next retry in ${presentation.nextDelay!.inSeconds}s',
      // If you later want error details etc, add more lines here.
    ];

    // Text() requires a non-null String.
    final detailText = presentation.detail ?? presentation.label;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status', style: titleStyle),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildDotForPhase(presentation, cs),
                const SizedBox(width: 12),
                Expanded(child: Text(detailText)),
              ],
            ),
            if (subtitleLines.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final line in subtitleLines)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(line, style: bodyStyle),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDotForPhase(
    MidiConnectionPresentation presentation,
    ColorScheme cs,
  ) {
    // Keep dot semantics consistent with pill tone mapping:
    // - normal/busy -> secondary
    // - error/unavailable -> error
    // - idle -> muted
    final color = switch (presentation.phase) {
      MidiConnectionPhase.connected => Colors.green.shade600,

      MidiConnectionPhase.connecting ||
      MidiConnectionPhase.retrying => cs.secondary,

      MidiConnectionPhase.bluetoothUnavailable ||
      MidiConnectionPhase.deviceUnavailable ||
      MidiConnectionPhase.error => cs.error,

      MidiConnectionPhase.idle => cs.onSurfaceVariant.withValues(alpha: 0.6),
    };

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
