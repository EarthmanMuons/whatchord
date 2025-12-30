import 'package:flutter/material.dart';

import '../models/midi_connection_state.dart';
import '../providers/midi_link_manager.dart';

class MidiStatusCard extends StatelessWidget {
  const MidiStatusCard({
    super.key,
    required this.connectionState,
    required this.link,
  });

  final MidiConnectionState connectionState;
  final MidiLinkState link;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final titleStyle = theme.textTheme.titleMedium;
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: cs.onSurfaceVariant,
    );

    final headline = switch (link.phase) {
      MidiLinkPhase.connected => 'Connected',
      MidiLinkPhase.connecting => 'Connecting…',
      MidiLinkPhase.retrying => 'Reconnecting…',
      MidiLinkPhase.bluetoothUnavailable => 'Bluetooth unavailable',
      MidiLinkPhase.deviceUnavailable => 'Device unavailable',
      MidiLinkPhase.error => 'Error',
      MidiLinkPhase.idle =>
        connectionState.isConnected ? 'Connected' : 'Not connected',
    };

    final detailLines = <String>[
      if (connectionState.isConnected)
        'Device: ${connectionState.message ?? "Unknown"}',
      if (!connectionState.isConnected &&
          link.message?.trim().isNotEmpty == true)
        link.message!.trim(),
      if (link.phase == MidiLinkPhase.retrying && link.attempt > 0)
        'Attempt ${link.attempt}${link.nextDelay != null ? " • Next in ${link.nextDelay!.inSeconds}s" : ""}',
    ];

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
                _buildDotForLink(link, cs),
                const SizedBox(width: 12),
                Expanded(child: Text(headline)),
              ],
            ),
            if (detailLines.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final line in detailLines)
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

  Widget _buildDotForLink(MidiLinkState link, ColorScheme cs) {
    final color = switch (link.phase) {
      MidiLinkPhase.connected => Colors.green,
      MidiLinkPhase.connecting => cs.secondary,
      MidiLinkPhase.retrying => cs.secondary,
      MidiLinkPhase.bluetoothUnavailable => cs.error,
      MidiLinkPhase.deviceUnavailable => cs.onSurfaceVariant,
      MidiLinkPhase.error => cs.error,
      MidiLinkPhase.idle => cs.onSurfaceVariant,
    };

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
