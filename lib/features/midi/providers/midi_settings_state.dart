import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/midi_device.dart';
import '../persistence/midi_preferences.dart';
import '../providers/midi_providers.dart';
import '../providers/midi_link_manager.dart';

@immutable
class MidiSettingsState {
  final AsyncValue<MidiPreferences> prefsAsync;
  final AsyncValue<List<MidiDevice>> devicesAsync;
  final AsyncValue<MidiDevice?> connectedAsync;
  final MidiLinkState link;

  const MidiSettingsState({
    required this.prefsAsync,
    required this.devicesAsync,
    required this.connectedAsync,
    required this.link,
  });

  MidiPreferences? get prefs => prefsAsync.asData?.value;

  List<MidiDevice> get devices => devicesAsync.asData?.value ?? const [];

  MidiDevice? get connected => connectedAsync.asData?.value;

  bool get isConnected => connected?.isConnected == true;

  MidiDevice? get lastDevice => prefs?.getLastDevice();
  String? get lastDeviceId => prefs?.getLastDeviceId();

  bool get hasLast => lastDeviceId != null && lastDeviceId!.trim().isNotEmpty;

  bool get isLinkBusy =>
      link.phase == MidiLinkPhase.connecting ||
      link.phase == MidiLinkPhase.retrying;

  bool get isConnectedToLast =>
      isConnected && hasLast && connected!.id == lastDeviceId;

  bool get isLastAvailable =>
      hasLast && devices.any((d) => d.id == lastDeviceId);

  bool get canReconnect =>
      hasLast && !isConnected && !isLinkBusy && isLastAvailable;
}

final midiSettingsStateProvider = Provider<MidiSettingsState>((ref) {
  return MidiSettingsState(
    prefsAsync: ref.watch(midiPreferencesProvider),
    devicesAsync: ref.watch(availableMidiDevicesProvider),
    connectedAsync: ref.watch(connectedMidiDeviceProvider),
    link: ref.watch(midiLinkManagerProvider),
  );
});
