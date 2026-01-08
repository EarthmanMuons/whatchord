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
    final saved = ref.watch(savedMidiDeviceProvider);

    // Connection semantics from the state machine.
    final isBusy = ref.watch(midiConnectionProvider.select((s) => s.isBusy));
    final isConnected = ref.watch(
      midiConnectionProvider.select((s) => s.isConnected),
    );
    final connectionDeviceName = ref.watch(
      midiConnectionProvider.select((s) => s.device?.name),
    );

    // Transport snapshot (who is connected).
    final connected = ref.watch(connectedMidiDeviceProvider).asData?.value;

    final savedId = ref.watch(savedMidiDeviceIdProvider);

    // If there is no saved device persisted, do not render the card at all
    // (but still show if currently connected, to allow Disconnect).
    if (!hasSaved && !isConnected) {
      return const SizedBox.shrink();
    }

    final isConnectedToSaved =
        isConnected &&
        savedId != null &&
        savedId.trim().isNotEmpty &&
        connected?.id == savedId;

    // Prefer current connected device name first.
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

    // Fall back to persisted saved device name.
    final savedName = (saved?.name.trim().isNotEmpty == true)
        ? saved!.name.trim()
        : null;

    final title = connectedName ?? savedName ?? 'Saved device';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.bluetooth),
        title: Text(title),
        trailing: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
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
                        await ref
                            .read(midiConnectionProvider.notifier)
                            .disconnect();

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
                            .read(midiConnectionProvider.notifier)
                            .tryAutoReconnect(reason: 'manual');
                      },
                child: const Text('Reconnect'),
              ),

            PopupMenuButton<_SavedDeviceMenuAction>(
              tooltip: 'More',
              onSelected: (action) async {
                switch (action) {
                  case _SavedDeviceMenuAction.forget:
                    await ref
                        .read(midiConnectionProvider.notifier)
                        .disconnect();

                    await ref
                        .read(midiPreferencesProvider.notifier)
                        .clearSavedDevice();

                    ref.read(midiConnectionProvider.notifier).resetToIdle();

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
