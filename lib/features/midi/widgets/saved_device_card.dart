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
    if (!s.hasLast) {
      return const SizedBox.shrink();
    }

    final last = s.lastDevice;
    final title = (last?.name.trim().isNotEmpty == true)
        ? last!.name
        : 'Saved device';

    // In release UX, I’d typically avoid showing the raw id prominently.
    // For now, we’ll keep it as subtitle since you already do.
    final subtitle = s.lastDeviceId;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.bluetooth),
        title: Text(title),
        subtitle: (subtitle != null && subtitle.trim().isNotEmpty)
            ? Text(subtitle)
            : null,
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
            else if (!s.isConnected && s.canReconnect)
              FilledButton.tonal(
                onPressed: () {
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
                    final prefs = await ref.read(
                      midiPreferencesProvider.future,
                    );
                    await prefs.clearLastDevice();

                    // Recommended: keep link state clean after forgetting.
                    ref.read(midiLinkManagerProvider.notifier).resetToIdle();

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
