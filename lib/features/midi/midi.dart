// ignore: dangling_library_doc_comments
///
/// MIDI-over-Bluetooth infrastructure.
///
/// ## Architecture Layers
///
/// 1. **Transport** ([MidiDeviceManager]):
///    - BLE central management, scanning, device discovery
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
/// - [midiConnectionProvider] for connection state
/// - [midiSoundingNotesProvider] for active notes
/// - [MidiSettingsPage] for user-facing controls
///
export 'models/bluetooth_state.dart';
export 'models/midi_connection.dart';
export 'models/midi_message.dart';
export 'models/midi_note_state.dart';
export 'models/midi_protocol.dart';

export 'providers/app_midi_lifecycle_provider.dart';
export 'providers/midi_connection_notifier.dart';
export 'providers/midi_connection_status_provider.dart';
export 'providers/midi_device_manager.dart';
export 'providers/midi_keep_awake_provider.dart';
export 'providers/midi_message_providers.dart';
export 'providers/midi_note_state_notifier.dart';

export 'pages/midi_settings_page.dart';

export 'widgets/midi_device_picker.dart';
export 'widgets/midi_status_card.dart';
export 'widgets/midi_status_pill.dart';
export 'widgets/saved_device_card.dart';
export 'widgets/wakelock_controller.dart';
