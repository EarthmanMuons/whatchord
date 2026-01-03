import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/midi_device.dart';
import '../persistence/midi_prefs_state.dart';
import '../providers/midi_connection_manager.dart';
import '../providers/midi_prefs_provider.dart';
import '../providers/midi_providers.dart';

@immutable
class MidiSettingsState {
  final MidiPrefsState prefs;
  final AsyncValue<List<MidiDevice>> devicesAsync;
  final AsyncValue<MidiDevice?> connectedAsync;
  final MidiConnectionState connection;

  const MidiSettingsState({
    required this.prefs,
    required this.devicesAsync,
    required this.connectedAsync,
    required this.connection,
  });

  List<MidiDevice> get devices => devicesAsync.asData?.value ?? const [];

  MidiDevice? get connected => connectedAsync.asData?.value;

  bool get isConnected => connected?.isConnected == true;

  MidiDevice? get lastDevice => prefs.lastDevice;
  String? get lastDeviceId => prefs.lastDeviceId;

  bool get hasLast => lastDeviceId != null && lastDeviceId!.trim().isNotEmpty;

  bool get isConnectionBusy =>
      connection.phase == MidiConnectionPhase.connecting ||
      connection.phase == MidiConnectionPhase.retrying;

  bool get isConnectedToLast =>
      isConnected && hasLast && connected!.id == lastDeviceId;

  bool get isLastAvailable =>
      hasLast && devices.any((d) => d.id == lastDeviceId);

  bool get canReconnect =>
      hasLast && !isConnected && !isConnectionBusy && isLastAvailable;
}

final midiSettingsStateProvider = Provider<MidiSettingsState>((ref) {
  return MidiSettingsState(
    prefs: ref.watch(midiPrefsProvider),
    devicesAsync: ref.watch(availableMidiDevicesProvider),
    connectedAsync: ref.watch(connectedMidiDeviceProvider),
    connection: ref.watch(midiConnectionManagerProvider),
  );
});
