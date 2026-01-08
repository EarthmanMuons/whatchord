import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/core/widgets/widgets.dart';

import '../models/midi_device.dart';
import '../providers/midi_connection_status_provider.dart';
import '../providers/midi_service_providers.dart';
import '../widgets/midi_device_picker.dart';
import '../widgets/midi_status_card.dart';
import '../widgets/saved_device_card.dart';

class MidiSettingsPage extends ConsumerStatefulWidget {
  const MidiSettingsPage({super.key});

  @override
  ConsumerState<MidiSettingsPage> createState() => _MidiSettingsPageState();
}

class _MidiSettingsPageState extends ConsumerState<MidiSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final connection = ref.watch(midiConnectionStatusProvider);
    final isInitializing = ref.watch(midiServiceInitProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MIDI Settings'),
        backgroundColor: cs.surfaceContainerLow,
        foregroundColor: cs.onSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MidiStatusCard(connection: connection),

          const SizedBox(height: 16),
          const SectionHeader(title: 'Device'),

          SavedDeviceCard(),
          const SizedBox(height: 12),

          if (isInitializing)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Initializing MIDI service...'),
                  ],
                ),
              ),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.add_link),
                title: Text(
                  connection.isConnected
                      ? 'Choose different device'
                      : 'Choose device',
                ),
                subtitle: const Text('Scan for and select a MIDI device'),
                trailing: const Icon(Icons.chevron_right),
                onTap: isInitializing
                    ? null
                    : () async {
                        final device = await showModalBottomSheet<MidiDevice>(
                          context: context,
                          showDragHandle: true,
                          builder: (_) => const MidiDevicePicker(),
                        );

                        if (!context.mounted) return;
                        if (device == null) return; // user dismissed the sheet

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Connected to ${device.name}'),
                          ),
                        );
                      },
              ),
            ),
        ],
      ),
    );
  }
}
