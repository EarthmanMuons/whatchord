import 'package:flutter/foundation.dart';

/// Represents a MIDI device that can be connected to.
@immutable
class MidiDevice {
  /// Unique identifier for the device (Bluetooth MAC address or UUID).
  final String id;

  /// Human-readable name of the device.
  final String name;

  /// Device type (e.g., 'BLE', 'USB', 'Network').
  final String type;

  /// Whether this device is currently connected.
  final bool isConnected;

  const MidiDevice({
    required this.id,
    required this.name,
    required this.type,
    this.isConnected = false,
  });

  /// Creates a copy with modified fields.
  MidiDevice copyWith({
    String? id,
    String? name,
    String? type,
    bool? isConnected,
  }) {
    return MidiDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MidiDevice &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          isConnected == other.isConnected;

  @override
  int get hashCode => Object.hash(id, name, type, isConnected);

  @override
  String toString() => 'MidiDevice($name, $type, connected: $isConnected)';

  /// Serialization for persistence.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'isConnected': isConnected,
  };

  /// Deserialization from persistence.
  factory MidiDevice.fromJson(Map<String, dynamic> json) {
    return MidiDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      isConnected: json['isConnected'] as bool? ?? false,
    );
  }
}
