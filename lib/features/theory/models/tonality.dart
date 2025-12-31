import 'package:flutter/foundation.dart';

enum TonalityMode { major, minor }

@immutable
class Tonality {
  final String tonic; // e.g. "C", "F#", "Bb"
  final TonalityMode mode;

  const Tonality(this.tonic, this.mode);

  bool get isMajor => mode == TonalityMode.major;
  bool get isMinor => mode == TonalityMode.minor;

  String get label => isMajor ? tonic : tonic.toLowerCase();

  String get displayName => isMajor ? '$tonic major' : '$tonic minor';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tonality &&
          runtimeType == other.runtimeType &&
          tonic == other.tonic &&
          mode == other.mode;

  @override
  int get hashCode => Object.hash(tonic, mode);

  @override
  String toString() => displayName;
}
