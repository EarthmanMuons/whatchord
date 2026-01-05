import 'package:meta/meta.dart';

/// Interval direction policy for labeling.
/// In chord contexts, "from bass to other note" is usually most meaningful.
enum IntervalLabelDirection {
  /// Label interval from bass -> other (preferred for sounding dyads).
  fromBass,

  /// Label the smaller distance between the two pitch classes (0..6).
  smallestDistance,
}

@immutable
class IntervalLabel {
  /// Semitones in [0..11] according to the chosen direction.
  final int semitones;

  /// Short label (e.g., "m3", "P5", "TT").
  final String short;

  /// Long label (e.g., "minor 3rd", "perfect 5th", "tritone").
  final String long;

  const IntervalLabel({
    required this.semitones,
    required this.short,
    required this.long,
  });

  @override
  String toString() => short;
}

/// Utility to label dyads (exactly two pitch classes).
///
/// Typical usage:
/// - If your chord input has exactly 2 pitch classes, compute interval from bass
///   to the other note and display IntervalLabel.short (and optionally .long).
abstract final class IntervalLabeler {
  static IntervalLabel forPitchClasses({
    required int bassPc,
    required int otherPc,
    IntervalLabelDirection direction = IntervalLabelDirection.fromBass,
  }) {
    final a = bassPc % 12;
    final b = otherPc % 12;

    int semis;
    switch (direction) {
      case IntervalLabelDirection.fromBass:
        semis = (b - a) % 12;
        if (semis < 0) semis += 12;
        break;

      case IntervalLabelDirection.smallestDistance:
        final up = (b - a) % 12;
        final down = (a - b) % 12;
        final u = up < 0 ? up + 12 : up;
        final d = down < 0 ? down + 12 : down;
        semis = (u <= d) ? u : d;
        break;
    }

    return _labelForSemitones(semis);
  }

  /// Labels by semitone count modulo 12.
  static IntervalLabel forSemitones(int semitones) {
    final s = semitones % 12;
    return _labelForSemitones(s < 0 ? s + 12 : s);
  }

  static IntervalLabel _labelForSemitones(int s) {
    // Common naming. Tritone is often clearer than A4/d5 in chord debugging.
    switch (s) {
      case 0:
        return const IntervalLabel(semitones: 0, short: 'P1', long: 'unison');
      case 1:
        return const IntervalLabel(
          semitones: 1,
          short: 'm2',
          long: 'minor 2nd',
        );
      case 2:
        return const IntervalLabel(
          semitones: 2,
          short: 'M2',
          long: 'major 2nd',
        );
      case 3:
        return const IntervalLabel(
          semitones: 3,
          short: 'm3',
          long: 'minor 3rd',
        );
      case 4:
        return const IntervalLabel(
          semitones: 4,
          short: 'M3',
          long: 'major 3rd',
        );
      case 5:
        return const IntervalLabel(
          semitones: 5,
          short: 'P4',
          long: 'perfect 4th',
        );
      case 6:
        return const IntervalLabel(semitones: 6, short: 'TT', long: 'tritone');
      case 7:
        return const IntervalLabel(
          semitones: 7,
          short: 'P5',
          long: 'perfect 5th',
        );
      case 8:
        return const IntervalLabel(
          semitones: 8,
          short: 'm6',
          long: 'minor 6th',
        );
      case 9:
        return const IntervalLabel(
          semitones: 9,
          short: 'M6',
          long: 'major 6th',
        );
      case 10:
        return const IntervalLabel(
          semitones: 10,
          short: 'm7',
          long: 'minor 7th',
        );
      case 11:
        return const IntervalLabel(
          semitones: 11,
          short: 'M7',
          long: 'major 7th',
        );
      default:
        // Unreachable, but keep it safe.
        return IntervalLabel(semitones: s, short: '$s', long: '$s semitones');
    }
  }
}
