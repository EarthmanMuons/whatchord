import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bluetooth_state.dart';
import '../models/midi_device.dart';
import '../models/midi_message.dart';
import '../persistence/midi_preferences.dart';
import '../services/flutter_midi_service.dart';
import '../services/midi_service.dart';
import '../services/stub_midi_service.dart';

// ============================================================
// MIDI Mode (Stub vs Real)
// ============================================================

enum MidiMode { stub, real }

extension MidiModeExtension on MidiMode {
  String get persistenceKey => name;

  static MidiMode fromString(String value) {
    return MidiMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => MidiMode.stub,
    );
  }
}

/// Provider for MIDI mode preference (stub vs real).
final midiModeProvider = NotifierProvider<MidiModeNotifier, MidiMode>(
  MidiModeNotifier.new,
);

class MidiModeNotifier extends Notifier<MidiMode> {
  @override
  MidiMode build() {
    // Load persisted mode asynchronously
    final prefsAsync = ref.watch(midiPreferencesProvider);

    return prefsAsync.when(
      data: (prefs) {
        final modeStr = prefs.getMidiMode();
        return MidiModeExtension.fromString(modeStr);
      },
      loading: () => MidiMode.stub, // Default while loading
      error: (_, _) => MidiMode.stub, // Fallback on error
    );
  }

  Future<void> setMode(MidiMode mode) async {
    final prefs = await ref.read(midiPreferencesProvider.future);
    await prefs.setMidiMode(mode.persistenceKey);
    state = mode;
  }

  void toggle() {
    final newMode = state == MidiMode.stub ? MidiMode.real : MidiMode.stub;
    setMode(newMode);
  }
}

// ============================================================
// Preferences
// ============================================================

/// Provider for MIDI preferences.
final midiPreferencesProvider = FutureProvider<MidiPreferences>((ref) async {
  return MidiPreferences.create();
});

// ============================================================
// MIDI Service
// ============================================================

/// Provider for the active MIDI service (stub or real).
final midiServiceProvider = Provider<MidiService>((ref) {
  final mode = ref.watch(midiModeProvider);

  final service = switch (mode) {
    MidiMode.stub => StubMidiService(),
    MidiMode.real => FlutterMidiService(),
  };

  // Ensure disposal
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

// ============================================================
// MIDI Service Lifecycle (Initialization)
// ============================================================

/// Provider that manages MIDI service initialization.
final midiServiceInitProvider = FutureProvider<bool>((ref) async {
  // Ensure persistence coordinator is installed early.
  ref.watch(midiPersistenceCoordinatorProvider);

  final service = ref.watch(midiServiceProvider);

  try {
    final initialized = await service.initialize();

    if (initialized) {
      final prefs = await ref.read(midiPreferencesProvider.future);
      final autoReconnect = prefs.getAutoReconnect();

      if (autoReconnect) {
        final lastDeviceId = prefs.getLastDeviceId();
        if (lastDeviceId != null) {
          unawaited(service.reconnect(lastDeviceId));
        }
      }
    }

    return initialized;
  } catch (e) {
    print('MIDI initialization failed: $e');
    return false;
  }
});

// ============================================================
// Available Devices Stream
// ============================================================

/// Stream of available MIDI devices.
final availableMidiDevicesProvider = StreamProvider<List<MidiDevice>>((ref) {
  final service = ref.watch(midiServiceProvider);
  return service.availableDevices;
});

// ============================================================
// MIDI Data Stream
// ============================================================

/// Stream of raw MIDI data packets.
final midiDataStreamProvider = StreamProvider<Uint8List>((ref) {
  final service = ref.watch(midiServiceProvider);
  return service.midiDataStream;
});

/// Stream of parsed MIDI messages.
final midiMessageStreamProvider = StreamProvider<MidiMessage?>((ref) {
  final dataStream = ref.watch(midiDataStreamProvider);

  return dataStream.when(
    data: (bytes) => Stream.value(MidiParser.parse(bytes)),
    loading: () => const Stream.empty(),
    error: (_, _) => const Stream.empty(),
  );
});

// ============================================================
// Bluetooth State Stream
// ============================================================

/// Stream of Bluetooth adapter state.
final bluetoothStateStreamProvider = StreamProvider<BluetoothState>((ref) {
  final service = ref.watch(midiServiceProvider);
  return service.bluetoothState;
});

// ============================================================
// Connected Device
// ============================================================

/// Provider for the currently connected MIDI device.
final connectedMidiDeviceProvider = StreamProvider<MidiDevice?>((ref) {
  final service = ref.watch(midiServiceProvider);
  return service.connectedDeviceStream;
});

/// Keeps persisted "last device" in sync with the actual connected device stream.
final midiPersistenceCoordinatorProvider = Provider<void>((ref) {
  final prefsAsync = ref.watch(midiPreferencesProvider);
  if (!prefsAsync.hasValue) return;

  final prefs = prefsAsync.requireValue;

  String? lastPersistedDeviceId;

  ref.listen<AsyncValue<MidiDevice?>>(connectedMidiDeviceProvider, (
    prev,
    next,
  ) async {
    // Only persist on a successful data emission
    final device = next.when(
      data: (d) => d,
      loading: () => null,
      error: (_, _) => null,
    );

    // Persist only when actually connected
    if (device == null || !device.isConnected) return;

    // Dedupe on device id (most practical)
    if (device.id == lastPersistedDeviceId) return;
    lastPersistedDeviceId = device.id;

    await prefs.setLastDevice(device);
  });
});

// ============================================================
// Connection Actions
// ============================================================

/// Provider for MIDI connection actions.
final midiConnectionActionsProvider = Provider<MidiConnectionActions>((ref) {
  return MidiConnectionActions(ref);
});

class MidiConnectionActions {
  final Ref _ref;

  const MidiConnectionActions(this._ref);

  MidiService get _service => _ref.read(midiServiceProvider);

  /// Ensure service is initialized before performing action.
  Future<void> _ensureInitialized() async {
    final initialized = await _ref.read(midiServiceInitProvider.future);
    if (!initialized) {
      throw const MidiException('Failed to initialize MIDI service');
    }
  }

  /// Start scanning for devices.
  Future<void> startScanning() async {
    await _ensureInitialized();
    await _service.startScanning();
  }

  /// Stop scanning for devices.
  Future<void> stopScanning() async {
    await _service.stopScanning();
  }

  /// Connect to a device and save it as the last connected device.
  Future<void> connect(MidiDevice device) async {
    await _ensureInitialized();
    await _service.connect(device);
  }

  /// Disconnect from the current device.
  Future<void> disconnect() async {
    await _service.disconnect();
  }

  /// Manually trigger a reconnection attempt.
  Future<bool> reconnect() async {
    await _ensureInitialized();
    final prefs = await _ref.read(midiPreferencesProvider.future);
    final lastDeviceId = prefs.getLastDeviceId();
    if (lastDeviceId == null) return false;

    return _service.reconnect(lastDeviceId);
  }
}
