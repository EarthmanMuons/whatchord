import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/midi_settings_page_state.dart';
import '../persistence/midi_preferences_provider.dart';
import '../providers/midi_connection_manager.dart';
import '../providers/midi_providers.dart';

enum _SavedDeviceMenuAction { forget }

class SavedDeviceCard extends ConsumerWidget {
  const SavedDeviceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(midiSettingsPageStateProvider);

    // If there is no last device persisted, do not render the card at all.
    if (!s.hasLast && !s.isConnected) {
      return const SizedBox.shrink();
    }

    // Prefer the *current* connected device name first.
    final connectedName =
        (s.isConnectionBusy || s.isConnected) &&
            (s.connection.device?.name.trim().isNotEmpty == true)
        ? s.connection.device!.name.trim()
        : (s.connected?.name.trim().isNotEmpty == true
              ? s.connected!.name.trim()
              : null);

    // Then fall back to persisted last-device name (if present).
    final last = s.lastDevice;
    final lastName = (last?.name.trim().isNotEmpty == true)
        ? last!.name.trim()
        : null;

    // Final title resolution.
    final title = connectedName ?? lastName ?? 'Saved device';

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
            if (s.isConnectedToLast)
              FilledButton.tonal(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: s.isConnectionBusy
                    ? null
                    : () async {
                        final actions = ref.read(midiConnectionActionsProvider);
                        await actions.disconnect();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Disconnected')),
                          );
                        }
                      },
                child: const Text('Disconnect'),
              )
            else if (!s.isConnected && s.hasLast)
              FilledButton.tonal(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: s.isConnectionBusy
                    ? null
                    : () {
                        ref
                            .read(midiConnectionManagerProvider.notifier)
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
                    await ref.read(midiConnectionActionsProvider).disconnect();

                    // Clear preference (drives saved-device UI / labels)
                    final prefs = ref.read(midiPreferencesProvider.notifier);
                    await prefs.clearLastDevice();

                    // Reset connection UI/phase so we don’t show stale reconnect messaging.
                    ref
                        .read(midiConnectionManagerProvider.notifier)
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
