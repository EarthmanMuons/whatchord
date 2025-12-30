import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/midi_device.dart';
import '../persistence/midi_preferences.dart';
import '../providers/midi_link_manager.dart';
import '../providers/midi_providers.dart';

enum _LastDeviceMenuAction { forget }

class LastDeviceTile extends ConsumerWidget {
  const LastDeviceTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(midiPreferencesProvider);
    final devicesAsync = ref.watch(availableMidiDevicesProvider);
    final connectedAsync = ref.watch(connectedMidiDeviceProvider);
    final link = ref.watch(midiLinkManagerProvider);

    final connected = connectedAsync.maybeWhen(
      data: (d) => d,
      orElse: () => null,
    );
    final isConnected = connected?.isConnected == true;

    return prefsAsync.when(
      loading: () => const Card(
        child: ListTile(title: Text('Last device'), subtitle: Text('Loading…')),
      ),
      error: (_, _) => const Card(
        child: ListTile(
          title: Text('Last device'),
          subtitle: Text('Unavailable'),
        ),
      ),
      data: (MidiPreferences prefs) {
        final MidiDevice? lastDevice = prefs.getLastDevice();
        final String? lastId = prefs.getLastDeviceId();

        final String title = (lastDevice?.name.trim().isNotEmpty == true)
            ? lastDevice!.name
            : 'Last device';

        final String? subtitle = (lastId != null && lastId.trim().isNotEmpty)
            ? lastId
            : null;

        final bool isLinkBusy =
            link.phase == MidiLinkPhase.connecting ||
            link.phase == MidiLinkPhase.retrying;

        final bool isLastAvailable = devicesAsync.maybeWhen(
          data: (list) => lastId != null && list.any((d) => d.id == lastId),
          orElse: () => false,
        );

        // "Reconnect" shows only when:
        // - not currently connected
        // - we have a lastId
        // - link is not busy
        // - last device appears in the current scan list (optional but UX-friendly)
        final bool canReconnect =
            !isConnected &&
            !isLinkBusy &&
            lastId != null &&
            lastId.trim().isNotEmpty &&
            isLastAvailable;

        return Card(
          child: ListTile(
            leading: const Icon(Icons.piano),
            title: Text(title),
            subtitle: subtitle != null ? Text(subtitle) : null,
            trailing: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (canReconnect)
                  FilledButton.tonal(
                    onPressed: () {
                      ref
                          .read(midiLinkManagerProvider.notifier)
                          .tryAutoReconnect(reason: 'manual');
                    },
                    child: const Text('Reconnect'),
                  ),
                PopupMenuButton<_LastDeviceMenuAction>(
                  tooltip: 'More',
                  onSelected: (action) async {
                    switch (action) {
                      case _LastDeviceMenuAction.forget:
                        await prefs.clearLastDevice();
                        // Optional but recommended: keep link-state clean after forgetting.
                        ref
                            .read(midiLinkManagerProvider.notifier)
                            .resetToIdle();
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _LastDeviceMenuAction.forget,
                      child: Text('Forget'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
