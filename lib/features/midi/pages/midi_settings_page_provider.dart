import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/midi_connection.dart';
import '../models/midi_device.dart';
import '../persistence/midi_preferences_notifier.dart';
import '../persistence/midi_preferences.dart';
import '../providers/midi_connection_notifier.dart';
import '../providers/midi_device_providers.dart';

@immutable
class MidiSettingsPageState {
  final MidiPreferences prefs;
  final AsyncValue<List<MidiDevice>> devicesAsync;
  final AsyncValue<MidiDevice?> connectedAsync;
  final MidiConnectionState connection;

  const MidiSettingsPageState({
    required this.prefs,
    required this.devicesAsync,
    required this.connectedAsync,
    required this.connection,
  });

  List<MidiDevice> get devices => devicesAsync.asData?.value ?? const [];
  MidiDevice? get connected => connectedAsync.asData?.value;

  MidiDevice? get lastDevice => prefs.savedDevice;
  String? get lastDeviceId => prefs.savedDeviceId;

  bool get hasLast => lastDeviceId != null && lastDeviceId!.trim().isNotEmpty;

  bool get isConnected => connection.isConnected;
  bool get isConnectionBusy => connection.isBusy;

  bool get isConnectedToLast {
    final id = lastDeviceId;
    final c = connected;
    return isConnected && id != null && id.trim().isNotEmpty && c?.id == id;
  }

  bool get isLastAvailable {
    final id = lastDeviceId;
    if (id == null || id.trim().isEmpty) return false;
    return devices.any((d) => d.id == id);
  }

  bool get canReconnect =>
      hasLast && !isConnected && !isConnectionBusy && isLastAvailable;
}

final midiSettingsPageStateProvider = Provider<MidiSettingsPageState>((ref) {
  return MidiSettingsPageState(
    prefs: ref.watch(midiPreferencesProvider),
    devicesAsync: ref.watch(availableMidiDevicesProvider),
    connectedAsync: ref.watch(connectedMidiDeviceProvider),
    connection: ref.watch(midiConnectionNotifierProvider),
  );
});
