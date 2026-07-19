/// Exception thrown by MIDI operations.
class MidiException implements Exception {
  final String message;
  final Object? cause;

  const MidiException(this.message, [this.cause]);

  @override
  String toString() =>
      'MidiException: $message${cause != null ? ' ($cause)' : ''}';
}
