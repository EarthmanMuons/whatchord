import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/midi_link_manager.dart';
import '../providers/midi_providers.dart';
import '../providers/midi_settings_state.dart';

enum _SavedDeviceMenuAction { forget }

class SavedDeviceCard extends ConsumerWidget {
  const SavedDeviceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(midiSettingsStateProvider);

    // If preferences aren’t loaded yet, show a stable skeleton card.
    if (s.prefsAsync.isLoading) {
      return const Card(
        child: ListTile(
          title: Text('Saved device'),
          subtitle: Text('Loading…'),
        ),
      );
    }

    // If prefs failed, show “Unavailable” (don’t crash the settings page).
    if (s.prefsAsync.hasError) {
      return const Card(
        child: ListTile(
          title: Text('Saved device'),
          subtitle: Text('Unavailable'),
        ),
      );
    }

    // If there is no last device persisted, do not render the card at all.
    if (!s.hasLast && !s.isConnected) {
      return const SizedBox.shrink();
    }

    // Prefer the *current* connected device name first.
    final connectedName = s.link.device?.name.trim().isNotEmpty == true
        ? s.link.device!.name.trim()
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
                onPressed: s.isLinkBusy
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
                onPressed: s.isLinkBusy
                    ? null
                    : () {
                        ref
                            .read(midiLinkManagerProvider.notifier)
                            .tryAutoReconnect(reason: 'manual');
                      },
                child: const Text('Reconnect'),
              ),

            PopupMenuButton<_SavedDeviceMenuAction>(
              tooltip: 'More',
              onSelected: (action) async {
                switch (action) {
                  case _SavedDeviceMenuAction.forget:
                    // 1) Make transport truthfully disconnected (drives picker checkmark)
                    await ref.read(midiConnectionActionsProvider).disconnect();

                    // 2) Clear preference (drives saved-device UI / labels)
                    final prefs = await ref.read(
                      midiPreferencesProvider.future,
                    );
                    await prefs.clearLastDevice();

                    // 3) Ensure anything derived from prefs re-reads immediately
                    ref.invalidate(midiPreferencesProvider);

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
