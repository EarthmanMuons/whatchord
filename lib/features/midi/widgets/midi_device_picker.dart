import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/midi_connection.dart';
import '../models/midi_device.dart';
import '../providers/midi_connection_notifier.dart';
import '../services/flutter_midi_service.dart';

/// Modal bottom sheet for scanning and selecting MIDI devices.
class MidiDevicePicker extends ConsumerStatefulWidget {
  const MidiDevicePicker({super.key});

  @override
  ConsumerState<MidiDevicePicker> createState() => _MidiDevicePickerState();
}

class _MidiDevicePickerState extends ConsumerState<MidiDevicePicker> {
  String? _error;

  late final MidiConnectionNotifier _connection;
  late final ProviderSubscription<MidiConnectionState> _connectionSub;

  Timer? _scanStartTimer;

  @override
  void initState() {
    super.initState();
    _connection = ref.read(midiConnectionProvider.notifier);

    // React to connection state changes (errors + success close).
    _connectionSub = ref.listenManual<MidiConnectionState>(
      midiConnectionProvider,
      (prev, next) {
        if (!mounted) return;

        // Surface connection errors in the picker UI.
        if (next.phase == MidiConnectionPhase.error && next.message != null) {
          setState(() => _error = next.message);
          return;
        }

        if (next.phase != MidiConnectionPhase.error && _error != null) {
          setState(() => _error = null);
        }

        // Close on successful connection (deduped).
        final wasConnected = prev?.isConnected == true;
        final isConnectedNow = next.isConnected;

        if (!wasConnected && isConnectedNow && next.device != null) {
          Navigator.of(context).pop<MidiDevice>(next.device!);
        }
      },
    );

    // Start scanning when the picker opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScanning();
    });
  }

  @override
  void dispose() {
    _connectionSub.close();
    _scanStartTimer?.cancel();
    _scanStartTimer = null;

    // Defer provider mutation outside of dispose.
    Future.microtask(() {
      // Do not await; this is a fire-and-forget cleanup.
      unawaited(_stopScanning());
    });

    super.dispose();
  }

  Future<void> _startScanning() async {
    if (!mounted) return;
    setState(() => _error = null);

    // Small delay keeps the UI responsive while the sheet animates in.
    _scanStartTimer?.cancel();
    _scanStartTimer = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted) return;

      try {
        await _connection.startScanning();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString().replaceAll('MidiException: ', '');
        });
      }
    });
  }

  Future<void> _stopScanning() async {
    try {
      await _connection.stopScanning();
    } catch (e) {
      debugPrint('Error stopping scan: $e');
    }
  }

  Future<void> _connectToDevice(MidiDevice device) async {
    // Clear any prior error banner (scan or connect).
    if (mounted) setState(() => _error = null);

    try {
      await ref.read(midiConnectionProvider.notifier).connect(device);
      // Success + failure UI are driven by the notifier listener above.
    } catch (_) {
      // No-op: notifier publishes MidiConnectionPhase.error + message.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final devices = ref.watch(midiControllerProvider.select((s) => s.devices));

    final isScanning = ref.watch(
      midiControllerProvider.select((s) => s.isScanning),
    );

    final connectedDeviceId = ref.watch(
      midiControllerProvider.select((s) => s.connectedDevice?.id),
    );

    final isAttemptingConnection = ref.watch(
      midiConnectionProvider.select((s) => s.isAttemptingConnection),
    );

    // Row-level spinner only for the device being connected in the "connecting" phase.
    final connectingDeviceId = ref.watch(
      midiConnectionProvider.select(
        (s) => s.phase == MidiConnectionPhase.connecting ? s.device?.id : null,
      ),
    );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select MIDI Device',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Error message (scan errors + connect errors)
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Material(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: cs.onErrorContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: cs.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const Divider(height: 1),

          // Device list
          Flexible(
            child: Builder(
              builder: (_) {
                if (devices.isEmpty) {
                  // Empty can mean either "still scanning" or "no devices found".
                  return isScanning
                      ? _buildScanningState()
                      : _buildNoDevicesState();
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final isConnected = connectedDeviceId == device.id;
                    final isCurrentlyConnecting =
                        connectingDeviceId == device.id;

                    return ListTile(
                      leading: Icon(
                        _getDeviceIcon(device.type),
                        color: isConnected ? cs.primary : null,
                      ),
                      title: Text(
                        device.name,
                        style: isConnected
                            ? TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              )
                            : null,
                      ),
                      subtitle: Text(device.type),
                      trailing: isConnected
                          ? Icon(Icons.check_circle, color: cs.primary)
                          : isCurrentlyConnecting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      enabled: !isAttemptingConnection,
                      onTap: (isConnected || isAttemptingConnection)
                          ? null
                          : () => _connectToDevice(device),
                    );
                  },
                );
              },
            ),
          ),

          // Footer with refresh button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  onPressed: isAttemptingConnection ? null : _startScanning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bluetooth_searching,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Scanning for devices...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure your MIDI device is powered on\nand in pairing mode.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDevicesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bluetooth_disabled,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No devices found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap Refresh to scan again.\nIf your device is new, pair it in iOS Settings first.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String type) {
    return switch (type.toLowerCase()) {
      'ble' || 'bluetooth' => Icons.bluetooth,
      'usb' => Icons.usb,
      'network' => Icons.wifi,
      _ => Icons.piano,
    };
  }
}
