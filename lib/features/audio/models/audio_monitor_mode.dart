/// Where the audio monitor routes notes when it is sounding.
///
/// The on/off state is the mute control, not a mode: muting bypasses playback
/// entirely. These modes only choose the output when not muted, and are
/// mutually exclusive so the internal synth and an external MIDI device never
/// play at once (which avoids any sync issues between them).
enum AudioMonitorMode {
  /// Notes play through the built-in soundfont synth.
  internal,

  /// Preview notes are sent to the connected MIDI device's own sound engine.
  ///
  /// Live input notes are never echoed back out (the source keyboard already
  /// sounds them); only app-generated previews are sent.
  midiOut;

  static AudioMonitorMode fromName(String? name) {
    for (final mode in AudioMonitorMode.values) {
      if (mode.name == name) return mode;
    }
    return AudioMonitorMode.internal;
  }
}
