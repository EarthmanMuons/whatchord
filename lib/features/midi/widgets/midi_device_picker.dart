import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/midi_device.dart';
import '../providers/midi_providers.dart';
import '../services/midi_service.dart';

/// Modal bottom sheet for scanning and selecting MIDI devices.
class MidiDevicePicker extends ConsumerStatefulWidget {
  const MidiDevicePicker({super.key});

  @override
  ConsumerState<MidiDevicePicker> createState() => _MidiDevicePickerState();
}

class _MidiDevicePickerState extends ConsumerState<MidiDevicePicker> {
  bool _isConnecting = false;
  String? _error;
  late final MidiConnectionActions _actions;
  Timer? _scanStartTimer;

  @override
  void initState() {
    super.initState();
    _actions = ref.read(midiConnectionActionsProvider);

    // Start scanning when the picker opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScanning();
    });
  }

  @override
  void dispose() {
    // If we scheduled a delayed scan start, cancel it.
    _scanStartTimer?.cancel();

    // Stop scanning when the picker closes
    _stopScanning();
    super.dispose();
  }

  Future<void> _startScanning() async {
    setState(() => _error = null);

    try {
      // Wait a moment for initialization to complete, but make it cancelable.
      _scanStartTimer?.cancel();
      _scanStartTimer = Timer(const Duration(milliseconds: 300), () async {
        if (!mounted) return;
        try {
          await _actions.startScanning();
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _error = e.toString().replaceAll('MidiException: ', '');
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('MidiException: ', '');
        });
      }
    }
  }

  Future<void> _stopScanning() async {
    try {
      await _actions.stopScanning();
    } catch (e) {
      debugPrint('Error stopping scan: $e');
    }
  }

  Future<void> _connectToDevice(MidiDevice device) async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    final actions = ref.read(midiConnectionActionsProvider);

    try {
      await actions.connect(device);

      if (mounted) {
        // Success - close the picker
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connected to ${device.name}')));
      }
    } on MidiException catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _error = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _error = 'Connection failed: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final devicesAsync = ref.watch(availableMidiDevicesProvider);
    final connectedDevice = ref
        .watch(connectedMidiDeviceProvider)
        .asData
        ?.value;

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

          // Error message
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
            child: devicesAsync.when(
              data: (devices) {
                if (devices.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final isConnected = connectedDevice?.id == device.id;
                    final isCurrentlyConnecting = _isConnecting && !isConnected;

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
                      enabled: !_isConnecting,
                      onTap: isConnected
                          ? null
                          : () => _connectToDevice(device),
                    );
                  },
                );
              },
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error.toString()),
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
                  onPressed: _isConnecting ? null : _startScanning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('Error', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
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
