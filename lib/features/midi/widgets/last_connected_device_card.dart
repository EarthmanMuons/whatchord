import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/midi_connection_notifier.dart';
import '../providers/midi_device_manager.dart';
import '../providers/midi_preferences_notifier.dart';

enum _LastConnectedDeviceMenuAction { forget }

class LastConnectedDeviceCard extends ConsumerWidget {
  const LastConnectedDeviceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasLastConnected = ref.watch(hasLastConnectedMidiDeviceProvider);
    final lastConnected = ref.watch(lastConnectedMidiDeviceProvider);

    // Connection semantics from the state machine.
    final isAttemptingConnection = ref.watch(
      midiConnectionStateProvider.select((s) => s.isAttemptingConnection),
    );
    final isConnected = ref.watch(
      midiConnectionStateProvider.select((s) => s.isConnected),
    );
    final connectionDisplayName = ref.watch(
      midiConnectionStateProvider.select((s) => s.deviceDisplayName),
    );

    // Transport snapshot (who is connected).
    final connected = ref.watch(
      midiDeviceManagerProvider.select((s) => s.connectedDevice),
    );
    final connectedDisplayName = connected?.displayName;

    final lastConnectedIdNormalized = ref.watch(
      lastConnectedMidiDeviceIdProvider.select((id) {
        if (id == null) return null;
        final t = id.trim();
        return t.isEmpty ? null : t;
      }),
    );

    // If there is no last-connected device persisted, do not render the card at all
    // (but still show if currently connected, to allow Disconnect).
    if (lastConnectedIdNormalized == null && !isConnected) {
      return const SizedBox.shrink();
    }

    final isConnectedToLastConnected =
        isConnected &&
        connected != null &&
        connected.id == lastConnectedIdNormalized;

    // Prefer the current connection name while busy/connected; otherwise fall back
    // to the transport snapshot.
    final effectiveConnectedName = (isAttemptingConnection || isConnected)
        ? (connectionDisplayName ?? connectedDisplayName)
        : connectedDisplayName;

    // Fall back to persisted last-connected device name.
    final lastConnectedDisplayName = lastConnected?.displayName;

    final title =
        effectiveConnectedName ??
        lastConnectedDisplayName ??
        'Last connected device';

    final compactButtonStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return Card(
      child: ListTile(
        leading: const Icon(Icons.bluetooth),
        title: Text(title),
        trailing: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (isAttemptingConnection)
              FilledButton.tonal(
                style: compactButtonStyle,
                onPressed: () {
                  ref.read(midiConnectionStateProvider.notifier).cancel();
                },
                child: const Text('Cancel'),
              )
            else if (isConnectedToLastConnected)
              FilledButton.tonal(
                style: compactButtonStyle,
                onPressed: isAttemptingConnection
                    ? null
                    : () async {
                        await ref
                            .read(midiConnectionStateProvider.notifier)
                            .disconnect();
                      },
                child: const Text('Disconnect'),
              )
            else if (!isConnected && hasLastConnected)
              FilledButton.tonal(
                style: compactButtonStyle,
                onPressed: isAttemptingConnection
                    ? null
                    : () {
                        ref
                            .read(midiConnectionStateProvider.notifier)
                            .tryAutoReconnect(reason: 'manual');
                      },
                child: const Text('Reconnect'),
              ),

            PopupMenuButton<_LastConnectedDeviceMenuAction>(
              tooltip: 'More',
              onSelected: (action) async {
                switch (action) {
                  case _LastConnectedDeviceMenuAction.forget:
                    await ref
                        .read(midiConnectionStateProvider.notifier)
                        .disconnect();

                    await ref
                        .read(midiPreferencesProvider.notifier)
                        .clearLastConnectedDevice();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Last connected device forgotten'),
                        ),
                      );
                    }
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _LastConnectedDeviceMenuAction.forget,
                  child: Text('Forget'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
