import 'package:meta/meta.dart';

/// Interval direction policy for labeling.
/// In chord contexts, "from bass to other note" is usually most meaningful.
enum IntervalLabelDirection {
  /// Label interval from bass -> other (preferred for sounding dyads).
  fromBass,

  /// Label the smaller distance between the two pitch classes (0..6).
  ///
  /// Note: when using MIDI distance, this still returns the closest
  /// chromatic distance class, but will preserve octave info when the
  /// closest distance is the "up" direction (see forMidiNotes docs).
  smallestDistance,
}

@immutable
class IntervalLabel {
  /// Semitone distance (>= 0).
  ///
  /// - For pitch-class labeling: typically [0..11]
  /// - For MIDI labeling: can be any non-negative value (e.g., 12 = octave)
  final int semitones;

  /// Short label (e.g., "m3", "P5", "P8", "m9", "M13").
  final String short;

  /// Long label (e.g., "minor 3rd", "perfect 5th", "perfect octave", "minor 9th").
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
abstract final class IntervalFormatter {
  /// Labels an interval using pitch classes only (mod 12).
  ///
  /// This preserves your existing behavior: no octave awareness.
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

    return _labelForSemitonesMod12(semis);
  }

  /// Labels an interval using MIDI note numbers, preserving octaves.
  ///
  /// Typical dyad usage:
  /// - bassMidi = lowest sounding MIDI note
  /// - otherMidi = highest sounding MIDI note
  ///
  /// Behavior:
  /// - fromBass: labels the upward distance (other - bass), including octaves
  /// - smallestDistance: chooses the smaller chromatic distance class between the two notes
  ///   but *still* returns a musically sensible compound label when "up" is the chosen
  ///   direction and spans one or more octaves.
  static IntervalLabel forMidiNotes({
    required int bassMidi,
    required int otherMidi,
    IntervalLabelDirection direction = IntervalLabelDirection.fromBass,
  }) {
    // Normalize ordering for safety.
    final low = bassMidi <= otherMidi ? bassMidi : otherMidi;
    final high = bassMidi <= otherMidi ? otherMidi : bassMidi;

    final up = high - low; // >= 0
    if (direction == IntervalLabelDirection.fromBass) {
      return _labelForSemitonesWithOctaves(up);
    }

    // smallestDistance: pick the smaller "up within octave" vs "down within octave"
    // distance class, but still represent the chosen direction as an upward interval.
    final upClass = up % 12; // 0..11
    final downClass = (12 - upClass) % 12; // also 0..11

    // If upClass is <= downClass, keep the true upward distance (with octaves).
    // Otherwise, prefer the downward class as the smaller distance; represent it
    // as an upward interval of that class (0..6) without forcing extra octaves.
    if (upClass <= downClass) {
      return _labelForSemitonesWithOctaves(up);
    } else {
      return _labelForSemitonesWithOctaves(downClass);
    }
  }

  /// Labels by semitone count modulo 12 (existing behavior).
  static IntervalLabel forSemitones(int semitones) {
    final s = semitones % 12;
    return _labelForSemitonesMod12(s < 0 ? s + 12 : s);
  }

  static IntervalLabel _labelForSemitonesMod12(int s) {
    // Your existing naming. Tritone is often clearer than A4/d5 in chord debugging.
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

  static IntervalLabel _labelForSemitonesWithOctaves(int semitones) {
    final s = semitones < 0 ? -semitones : semitones;
    final octaves = s ~/ 12;
    final within = s % 12;

    // Base label (P1..M7 / TT) for the within-octave class.
    final base = _labelForSemitonesMod12(within);

    // Map the base label to a diatonic interval number within [1..7] (or 4 for TT).
    final baseNumber = _baseIntervalNumberFromShort(base.short);

    // Compound interval number: each octave adds 7 scale degrees.
    // - unison (1) + 7 = octave (8)
    // - 2 + 7 = 9th, etc.
    final number = baseNumber + (7 * octaves);

    // Build short label:
    // - Keep your "TT" convention, but append the compound number when needed.
    final short = (base.short == 'TT')
        ? (number == baseNumber ? 'TT' : 'TT$number')
        : '${base.short[0]}$number'; // 'm3' -> 'm10', 'P5' -> 'P12', etc.

    // Build long label.
    final qualityLong = _qualityLongFromShort(base.short);
    final ordinal = _ordinal(number);

    // Special-case a few very common names.
    if (within == 0 && octaves == 1) {
      return IntervalLabel(semitones: s, short: 'P8', long: 'perfect octave');
    }
    if (within == 0 && octaves > 1) {
      return IntervalLabel(
        semitones: s,
        short: 'P$number',
        long: 'perfect $ordinal',
      );
    }

    if (base.short == 'TT') {
      // Preserve octave info while keeping "tritone" terminology.
      final long = (number == baseNumber) ? 'tritone' : 'tritone ($ordinal)';
      return IntervalLabel(semitones: s, short: short, long: long);
    }

    return IntervalLabel(
      semitones: s,
      short: short,
      long: '$qualityLong $ordinal',
    );
  }

  static int _baseIntervalNumberFromShort(String short) {
    // Based on your existing set:
    // P1, m2, M2, m3, M3, P4, TT, P5, m6, M6, m7, M7
    switch (short) {
      case 'P1':
        return 1;
      case 'm2':
      case 'M2':
        return 2;
      case 'm3':
      case 'M3':
        return 3;
      case 'P4':
        return 4;
      case 'TT':
        // Ambiguous (A4/d5), but 4 keeps compound numbering consistent (11th for 18 semis).
        return 4;
      case 'P5':
        return 5;
      case 'm6':
      case 'M6':
        return 6;
      case 'm7':
      case 'M7':
        return 7;
      default:
        // Fallback: treat unknown as unison-like.
        return 1;
    }
  }

  static String _qualityLongFromShort(String short) {
    // First character is enough for your set except TT.
    if (short == 'TT') return 'tritone';
    final q = short.isNotEmpty ? short[0] : '';
    switch (q) {
      case 'P':
        return 'perfect';
      case 'm':
        return 'minor';
      case 'M':
        return 'major';
      default:
        return '';
    }
  }

  static String _ordinal(int n) {
    // 1st, 2nd, 3rd, 4th... with 11/12/13 as special-case "th".
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }
}
