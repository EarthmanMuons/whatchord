import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/midi_preferences_notifier.dart';
import '../providers/midi_connection_notifier.dart';
import '../providers/midi_device_providers.dart';

enum _SavedDeviceMenuAction { forget }

class SavedDeviceCard extends ConsumerWidget {
  const SavedDeviceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSaved = ref.watch(hasSavedMidiDeviceProvider);
    final isConnected = ref.watch(isMidiConnectedProvider);
    final isBusy = ref.watch(isConnectionBusyProvider);
    final isConnectedToSaved = ref.watch(isConnectedToSavedDeviceProvider);

    final connected = ref.watch(connectedMidiDeviceValueProvider);
    final saved = ref.watch(savedMidiDeviceProvider);

    final connectionDeviceName = ref.watch(
      midiConnectionNotifierProvider.select((s) => s.device?.name),
    );

    // If there is no saved device persisted, do not render the card at all.
    if (!hasSaved && !isConnected) {
      return const SizedBox.shrink();
    }

    // Prefer the *current* connected device name first.
    final connectionNameTrimmed =
        (connectionDeviceName?.trim().isNotEmpty == true)
        ? connectionDeviceName!.trim()
        : null;
    final connectedNameTrimmed = (connected?.name.trim().isNotEmpty == true)
        ? connected!.name.trim()
        : null;

    final connectedName =
        (isBusy || isConnected) && connectionNameTrimmed != null
        ? connectionNameTrimmed
        : connectedNameTrimmed;

    // Then fall back to persisted saved device name (if present).
    final savedName = (saved?.name.trim().isNotEmpty == true)
        ? saved!.name.trim()
        : null;

    // Final title resolution.
    final title = connectedName ?? savedName ?? 'Saved device';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.bluetooth),
        title: Text(title),
        trailing: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Primary action:
            // - Connected to last => Disconnect
            // - Not connected and last is available => Reconnect
            // - Otherwise => no primary action (or a disabled label)
            if (isConnectedToSaved)
              FilledButton.tonal(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: isBusy
                    ? null
                    : () async {
                        final connection = ref.read(
                          midiConnectionNotifierProvider.notifier,
                        );
                        await connection.disconnect();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Disconnected')),
                          );
                        }
                      },
                child: const Text('Disconnect'),
              )
            else if (!isConnected && hasSaved)
              FilledButton.tonal(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: isBusy
                    ? null
                    : () {
                        ref
                            .read(midiConnectionNotifierProvider.notifier)
                            .tryAutoReconnect(reason: 'manual');
                      },
                child: const Text('Reconnect'),
              ),

            PopupMenuButton<_SavedDeviceMenuAction>(
              tooltip: 'More',
              onSelected: (action) async {
                switch (action) {
                  case _SavedDeviceMenuAction.forget:
                    // Make transport truthfully disconnected (drives picker checkmark)
                    await ref
                        .read(midiConnectionNotifierProvider.notifier)
                        .disconnect();

                    // Clear preference (drives saved-device UI / labels)
                    final prefs = ref.read(midiPreferencesProvider.notifier);
                    await prefs.clearSavedDevice();

                    // Reset connection UI/phase so we don’t show stale reconnect messaging.
                    ref
                        .read(midiConnectionNotifierProvider.notifier)
                        .resetToIdle();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Saved device forgotten')),
                      );
                    }
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _SavedDeviceMenuAction.forget,
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
