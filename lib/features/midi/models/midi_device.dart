import 'package:flutter/foundation.dart';

/// The transport used by a MIDI device.
enum MidiTransportType {
  ble,
  usb,
  network,
  unknown;

  static MidiTransportType fromString(String raw) {
    final normalized = raw.trim().toLowerCase();
    return switch (normalized) {
      'ble' || 'bluetooth' || 'native' => MidiTransportType.ble,
      'usb' => MidiTransportType.usb,
      'network' => MidiTransportType.network,
      _ => MidiTransportType.unknown,
    };
  }

  String get label => switch (this) {
    MidiTransportType.ble => 'Bluetooth',
    MidiTransportType.usb => 'USB',
    MidiTransportType.network => 'Network',
    MidiTransportType.unknown => 'Unknown',
  };
}

/// Represents a MIDI device that can be connected to.
@immutable
class MidiDevice {
  /// Unique identifier for the device (Bluetooth MAC address or UUID).
  final String id;

  /// Human-readable name of the device.
  final String name;

  /// Transport type (e.g., Bluetooth, USB, Network).
  final MidiTransportType transport;

  /// Whether this device is currently connected.
  final bool isConnected;

  const MidiDevice({
    required this.id,
    required this.name,
    required this.transport,
    this.isConnected = false,
  });

  /// Name suitable for UI display.
  ///
  /// Returns null if the name is blank after trimming.
  String? get displayName {
    final trimmed = name.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Creates a copy with modified fields.
  MidiDevice copyWith({
    String? id,
    String? name,
    MidiTransportType? transport,
    bool? isConnected,
  }) {
    return MidiDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      transport: transport ?? this.transport,
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
          transport == other.transport &&
          isConnected == other.isConnected;

  @override
  int get hashCode => Object.hash(id, name, transport, isConnected);

  @override
  String toString() => 'MidiDevice($name, $transport, connected: $isConnected)';

  /// Serialization for persistence.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'transport': transport.name,
    'isConnected': isConnected,
  };

  /// Deserialization from persistence.
  factory MidiDevice.fromJson(Map<String, dynamic> json) {
    final transportRaw =
        (json['transport'] ?? json['type']) as String? ?? 'unknown';

    return MidiDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      transport: MidiTransportType.fromString(transportRaw),
      isConnected: json['isConnected'] as bool? ?? false,
    );
  }
}
