// ignore: dangling_library_doc_comments
///
/// MIDI-over-Bluetooth infrastructure.
///
/// ## Architecture Layers
///
/// 1. **Transport** ([MidiDeviceManager]):
///    - Bluetooth central management, scanning, device discovery
///    - Low-level connect/disconnect operations
///
/// 2. **Connection Workflow** ([MidiConnectionNotifier]):
///    - Retry logic, auto-reconnect, backoff
///    - User-facing connection state machine
///
/// 3. **Presentation** ([MidiConnectionStatus]):
///    - UI-friendly status labels and details
///    - Computed from connection state
///
/// 4. **Message Parsing** ([MidiParser], [MidiNoteStateNotifier]):
///    - Raw MIDI byte stream → domain events
///    - Note on/off tracking, sustain pedal handling
///
/// ## Usage
///
/// Most app code should interact with:
/// - [midiConnectionStateProvider] for connection state
/// - [midiSoundingNoteNumbersProvider] for sounding note numbers
/// - [MidiSettingsPage] for user-facing controls
///
export 'models/midi_connection.dart';
export 'models/midi_connection_status.dart';

export 'providers/app_midi_lifecycle_provider.dart';
export 'providers/midi_connection_notifier.dart';
export 'providers/midi_connection_status_provider.dart';
export 'providers/midi_note_state_notifier.dart';
export 'providers/midi_preferences_notifier.dart';

export 'pages/midi_settings_page.dart';

export 'widgets/midi_status_icon.dart';
export 'widgets/wakelock_controller.dart';
