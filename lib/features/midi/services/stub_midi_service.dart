import 'dart:async';
import 'dart:typed_data';

import '../models/bluetooth_state.dart';
import '../models/midi_constants.dart';
import '../models/midi_device.dart';
import 'midi_service.dart';

/// Stub MIDI service for development and testing.
///
/// Provides simulated devices and MIDI messages without real hardware.
class StubMidiService implements MidiService {
  final _devicesController = StreamController<List<MidiDevice>>.broadcast();
  final _connectedDeviceController = StreamController<MidiDevice?>.broadcast();
  final _midiDataController = StreamController<Uint8List>.broadcast();
  final _bluetoothController = StreamController<BluetoothState>.broadcast();

  MidiDevice? _connectedDevice;
  bool _isScanning = false;
  bool _isInitialized = false;

  Timer? _simulationTimer;

  // Simulated devices
  static final _stubDevices = [
    const MidiDevice(id: 'stub-piano-001', name: 'Virtual Piano', type: 'BLE'),
    const MidiDevice(
      id: 'stub-keyboard-002',
      name: 'Test Keyboard',
      type: 'BLE',
    ),
  ];

  // ============================================================
  // Stream Getters
  // ============================================================

  @override
  Stream<List<MidiDevice>> get availableDevices => _devicesController.stream;

  @override
  Stream<MidiDevice?> get connectedDeviceStream =>
      _connectedDeviceController.stream;

  @override
  Stream<Uint8List> get midiDataStream => _midiDataController.stream;

  @override
  Stream<BluetoothState> get bluetoothState => _bluetoothController.stream;

  // ============================================================
  // State Getters
  // ============================================================

  @override
  MidiDevice? get connectedDevice => _connectedDevice;

  @override
  bool get isScanning => _isScanning;

  // ============================================================
  // Lifecycle
  // ============================================================

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Simulate initialization delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Emit initial Bluetooth state
    _bluetoothController.add(BluetoothState.on);

    _connectedDeviceController.add(_connectedDevice);

    _isInitialized = true;
    return true;
  }

  @override
  Future<void> dispose() async {
    await stopScanning();
    _simulationTimer?.cancel();

    await _devicesController.close();
    await _connectedDeviceController.close();
    await _midiDataController.close();
    await _bluetoothController.close();

    _isInitialized = false;
  }

  // ============================================================
  // Device Discovery
  // ============================================================

  @override
  Future<void> startScanning() async {
    if (!_isInitialized) {
      throw const MidiException('Service not initialized');
    }

    if (_isScanning) return;

    _isScanning = true;

    // Simulate device discovery with delay
    await Future.delayed(const Duration(milliseconds: 500));
    _devicesController.add(_stubDevices);
  }

  @override
  Future<void> stopScanning() async {
    _isScanning = false;
  }

  // ============================================================
  // Connection Management
  // ============================================================

  @override
  Future<void> connect(MidiDevice device) async {
    if (!_isInitialized) {
      throw const MidiException('Service not initialized');
    }

    // Simulate connection delay
    await Future.delayed(const Duration(milliseconds: 800));

    _setConnectedDevice(device.copyWith(isConnected: true));

    // Start simulating MIDI input
    _startMidiSimulation();
  }

  @override
  Future<void> disconnect() async {
    _setConnectedDevice(null);
    _simulationTimer?.cancel();
  }

  @override
  Future<bool> reconnect(String deviceId) async {
    if (!_isInitialized) {
      await initialize();
    }

    MidiDevice? device;
    for (final d in _stubDevices) {
      if (d.id == deviceId) {
        device = d;
        break;
      }
    }
    if (device == null) return false;

    try {
      await connect(device);
      return true;
    } catch (e) {
      return false;
    }
  }

  void _setConnectedDevice(MidiDevice? device) {
    _connectedDevice = device;
    _connectedDeviceController.add(_connectedDevice);
  }

  // ============================================================
  // Simulation Logic
  // ============================================================

  void _startMidiSimulation() {
    // Simulate a C major chord (C4, E4, G4) being played
    _simulationTimer?.cancel();

    var step = 0;

    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_connectedDevice == null) {
        timer.cancel();
        return;
      }

      switch (step % 4) {
        case 0:
          // Play C major chord
          _sendNoteOn(60, 64); // C4
          _sendNoteOn(64, 64); // E4
          _sendNoteOn(67, 64); // G4
          break;

        case 1:
          // Release chord
          _sendNoteOff(60);
          _sendNoteOff(64);
          _sendNoteOff(67);
          break;

        case 2:
          // Play F major chord
          _sendNoteOn(65, 64); // F4
          _sendNoteOn(69, 64); // A4
          _sendNoteOn(72, 64); // C5
          break;

        case 3:
          // Release chord
          _sendNoteOff(65);
          _sendNoteOff(69);
          _sendNoteOff(72);
          break;
      }

      step++;
    });
  }

  void _sendNoteOn(int note, int velocity) {
    _midiDataController.add(Uint8List.fromList([0x90, note, velocity]));
  }

  void _sendNoteOff(int note) {
    _midiDataController.add(Uint8List.fromList([0x80, note, 64]));
  }

  // ============================================================
  // Public Test Helpers
  // ============================================================

  /// Manually trigger a note on event (for testing).
  void simulateNoteOn(int note, {int velocity = 64}) {
    _sendNoteOn(note, velocity);
  }

  /// Manually trigger a note off event (for testing).
  void simulateNoteOff(int note) {
    _sendNoteOff(note);
  }

  /// Manually trigger a sustain pedal event (for testing).
  void simulatePedal(bool down) {
    final value = down ? MidiConstants.maxVelocity : MidiConstants.minVelocity;
    _midiDataController.add(
      Uint8List.fromList([0xB0, MidiConstants.sustainPedalController, value]),
    );
  }
}
