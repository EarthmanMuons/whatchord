import 'package:flutter/foundation.dart';

enum MidiConnectionStatus { disconnected, connecting, connected, error }

@immutable
class MidiConnectionState {
  final MidiConnectionStatus status;

  /// Optional details (e.g., last error, device name, etc.)
  final String? message;

  const MidiConnectionState({required this.status, this.message});

  bool get isConnected => status == MidiConnectionStatus.connected;

  MidiConnectionState copyWith({
    MidiConnectionStatus? status,
    String? message,
  }) {
    return MidiConnectionState(
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}
