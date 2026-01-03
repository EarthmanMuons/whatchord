abstract class MidiConstants {
  /// MIDI note range: 0-127 (middle C = 60)
  static const int minNote = 0;
  static const int maxNote = 127;
  static const int middleC = 60;

  /// Control Change (CC) numbers
  static const int sustainPedalController = 64;
  static const int sustainPedalThreshold = 64; // >= 64 is "down"

  /// Velocity range: 0-127 (0 in NoteOn = NoteOff)
  static const int minVelocity = 0;
  static const int maxVelocity = 127;
}
