/// Build-time flag for MIDI debug logging.
///
/// Enable with:
/// `--dart-define=MIDI_DEBUG=true`
const bool midiDebug = bool.fromEnvironment('MIDI_DEBUG');
