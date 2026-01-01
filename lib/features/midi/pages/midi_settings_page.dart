import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/core/widgets/widgets.dart';

import '../providers/midi_providers.dart';
import '../providers/midi_ui_status.dart';
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
    final ui = ref.watch(midiUiStatusProvider);
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
          MidiStatusCard(ui: ui),

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
                  ui.isConnected ? 'Choose different device' : 'Choose device',
                ),
                subtitle: const Text('Scan for and select a MIDI device'),
                trailing: const Icon(Icons.chevron_right),
                onTap: isInitializing
                    ? null
                    : () {
                        showModalBottomSheet(
                          context: context,
                          showDragHandle: true,
                          builder: (_) => const MidiDevicePicker(),
                        );
                      },
              ),
            ),

          if (kDebugMode) ...[
            const SizedBox(height: 16),
            const SectionHeader(title: 'Advanced (debug)'),
            const SizedBox(height: 8),

            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: const Text('Clear all MIDI data'),
                subtitle: const Text(
                  'Clears MIDI preferences, last device, and reconnect settings.',
                ),
                onTap: () async {
                  final prefs = await ref.read(midiPreferencesProvider.future);
                  await prefs.clearAllMidiData();

                  // Also stop any ongoing scan and disconnect to ensure a clean slate.
                  final actions = ref.read(midiConnectionActionsProvider);
                  await actions.stopScanning();
                  await actions.disconnect();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('MIDI data cleared')),
                    );
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
