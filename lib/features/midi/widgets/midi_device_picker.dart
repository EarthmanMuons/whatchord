import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/midi_connection.dart';
import '../models/midi_device.dart';
import '../providers/midi_connection_notifier.dart';
import '../providers/midi_device_manager.dart';

/// Modal bottom sheet for scanning and selecting MIDI devices.
class MidiDevicePicker extends ConsumerStatefulWidget {
  const MidiDevicePicker({super.key});

  @override
  ConsumerState<MidiDevicePicker> createState() => _MidiDevicePickerState();
}

class _MidiDevicePickerState extends ConsumerState<MidiDevicePicker> {
  String? _error;

  late final MidiConnectionNotifier _connectionNotifier;
  late final ProviderSubscription<MidiConnectionState> _connectionSub;

  Timer? _scanStartTimer;

  @override
  void initState() {
    super.initState();
    _connectionNotifier = ref.read(midiConnectionStateProvider.notifier);

    // React to connection state changes (errors + success close).
    _connectionSub = ref.listenManual<MidiConnectionState>(
      midiConnectionStateProvider,
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
        await _connectionNotifier.startScanning();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString().replaceAll('MidiException: ', '');
        });
      }
    });
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _error = null);

    try {
      // Hard refresh by default (restart scan) to recover from stalled scans.
      await _connectionNotifier.refreshDevices(restartScan: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('MidiException: ', '');
      });
    }
  }

  Future<void> _connectToDevice(MidiDevice device) async {
    // Clear any prior error banner (scan or connect).
    if (mounted) setState(() => _error = null);

    try {
      await ref.read(midiConnectionStateProvider.notifier).connect(device);
      // Success + failure UI are driven by the notifier listener above.
    } catch (_) {
      // No-op: notifier publishes MidiConnectionPhase.error + message.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final devices = ref.watch(
      midiDeviceManagerProvider.select((s) => s.devices),
    );

    final isScanning = ref.watch(
      midiDeviceManagerProvider.select((s) => s.isScanning),
    );

    final connectedDeviceId = ref.watch(
      midiDeviceManagerProvider.select((s) => s.connectedDevice?.id),
    );

    final visibleDevices = devices
        .where(
          (d) =>
              d.transport != MidiTransportType.network ||
              d.id == connectedDeviceId,
        )
        .toList();

    final isAttemptingConnection = ref.watch(
      midiConnectionStateProvider.select((s) => s.isAttemptingConnection),
    );

    // Row-level spinner only for the device being connected in the "connecting" phase.
    final connectingDeviceId = ref.watch(
      midiConnectionStateProvider.select(
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
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),

          // Error message (scan errors + connect errors)
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _error == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Material(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: cs.onErrorContainer,
                            ),
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
          ),

          const Divider(height: 1),

          // Device list
          Flexible(
            child: Builder(
              builder: (_) {
                if (visibleDevices.isEmpty) {
                  // Empty can mean either "still scanning" or "no devices found".
                  return isScanning
                      ? _buildScanningState()
                      : _buildNoDevicesState();
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: visibleDevices.length,
                  itemBuilder: (context, index) {
                    final device = visibleDevices[index];
                    final isConnected = connectedDeviceId == device.id;
                    final isCurrentlyConnecting =
                        connectingDeviceId == device.id;

                    return ListTile(
                      leading: Icon(
                        _iconForTransport(device.transport),
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
                      subtitle: Text(device.transport.label),
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
                  onPressed: isAttemptingConnection ? null : _refresh,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningState() {
    return _buildEmptyState(
      icon: Icons.bluetooth_searching,
      title: 'Scanning for devices...',
      message: 'Make sure your MIDI device is powered on\nand in pairing mode.',
    );
  }

  Widget _buildNoDevicesState() {
    return _buildEmptyState(
      icon: Icons.bluetooth_disabled,
      title: 'No devices found',
      message:
          'Tap Refresh to scan again.\nIf your device is new, pair it in your system settings first.',
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = (constraints.maxHeight * 0.18).clamp(16.0, 48.0);

        return SingleChildScrollView(
          // Allow the sheet to stay small without throwing overflow.
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            // When there IS room, this keeps the content centered vertically.
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.all(pad),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 64, color: cs.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _iconForTransport(MidiTransportType transport) {
    return switch (transport) {
      MidiTransportType.ble => Icons.bluetooth,
      MidiTransportType.usb => Icons.usb,
      MidiTransportType.network => Icons.wifi,
      MidiTransportType.unknown => Icons.piano,
    };
  }
}
