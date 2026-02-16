import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:whatchord/core/core.dart';

import '../models/midi_device.dart';
import '../providers/midi_connection_notifier.dart';
import '../providers/midi_connection_status_provider.dart';
import '../widgets/last_connected_device_card.dart';
import '../widgets/midi_device_picker.dart';
import '../widgets/midi_status_card.dart';

class MidiSettingsPage extends ConsumerWidget {
  const MidiSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final status = ref.watch(midiConnectionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MIDI Settings'),
        backgroundColor: cs.surfaceContainerLow,
        foregroundColor: cs.onSurface,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MidiStatusCard(status: status),

            if (status.canOpenSettings) ...[
              const SizedBox(height: 8),
              Card(
                child: Semantics(
                  onTapHint: 'Open system settings',
                  child: ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Open system settings for WhatChord'),
                    onTap: () async {
                      await openAppSettings();
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            const SectionHeader(title: 'Device'),

            const LastConnectedDeviceCard(),
            const SizedBox(height: 12),

            Card(
              child: Semantics(
                onTapHint: 'Open MIDI device picker',
                child: ListTile(
                  leading: const Icon(Icons.add_link),
                  title: Text(
                    status.isConnected
                        ? 'Choose different device'
                        : 'Choose device',
                  ),
                  subtitle: const Text(
                    'Scan for Bluetooth devices or select a wired MIDI device',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await showAdaptiveMidiDevicePicker(context).whenComplete(
                      () {
                        unawaited(
                          ref
                              .read(midiConnectionStateProvider.notifier)
                              .stopScanning(),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<MidiDevice?> showAdaptiveMidiDevicePicker(BuildContext context) {
  Color resolvePanelColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.bottomSheetTheme.modalBackgroundColor ??
        theme.bottomSheetTheme.backgroundColor ??
        theme.colorScheme.surfaceContainerLow;
  }

  final shortestSide = MediaQuery.sizeOf(context).shortestSide;
  final isCompact = shortestSide < 600;

  if (isCompact) {
    return showModalBottomSheet<MidiDevice>(
      context: context,
      showDragHandle: true,
      backgroundColor: resolvePanelColor(context),
      builder: (_) => const MidiDevicePicker(),
    );
  }

  final maxDialogHeight = MediaQuery.sizeOf(context).height * 0.82;

  return showDialog<MidiDevice>(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: maxDialogHeight,
          ),
          child: Material(
            color: resolvePanelColor(context),
            child: const MidiDevicePicker(),
          ),
        ),
      );
    },
  );
}
