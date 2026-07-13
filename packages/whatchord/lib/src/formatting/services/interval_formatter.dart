import 'package:meta/meta.dart';

/// Interval direction policy for labeling.
enum IntervalLabelDirection {
  /// Label interval from bass/low -> upper/high (preferred for sounding dyads).
  fromBass,

  /// Label the smaller chromatic distance class between the two pitch classes (0..6).
  ///
  /// For MIDI labeling, if the "up" direction is chosen as smallest (or tied),
  /// the returned label preserves octave information (compound interval).
  smallestDistance,
}

@immutable
class IntervalLabel {
  /// Semitone distance (>= 0).
  ///
  /// - Pitch class labeling: [0..11]
  /// - MIDI labeling: any non-negative value (e.g., 12 = octave)
  final int semitones;

  /// Short label (e.g., "m3", "P5", "P8", "m9", "M13").
  final String short;

  /// Long label (e.g., "Minor 3rd", "Perfect 5th", "Perfect octave", "Minor 9th").
  final String long;

  const IntervalLabel({
    required this.semitones,
    required this.short,
    required this.long,
  });

  @override
  String toString() => short;
}

/// Utility to label dyads (exactly two notes / pitch classes).
abstract final class IntervalFormatter {
  static IntervalLabel forPitchClasses({
    required int bassPc,
    required int otherPc,
    IntervalLabelDirection direction = IntervalLabelDirection.fromBass,
  }) {
    final a = _mod12(bassPc);
    final b = _mod12(otherPc);

    final upClass = _mod12(b - a); // 0..11
    final s = (direction == IntervalLabelDirection.fromBass)
        ? upClass
        : _smallestClass(upClass);

    return _labelMod12(s);
  }

  static IntervalLabel forMidiNotes({
    required int bassMidi,
    required int upperMidi,
    IntervalLabelDirection direction = IntervalLabelDirection.fromBass,
  }) {
    // Normalize ordering for safety; callers should already be passing low/high.
    final low = bassMidi <= upperMidi ? bassMidi : upperMidi;
    final high = bassMidi <= upperMidi ? upperMidi : bassMidi;

    final up = high - low; // >= 0
    if (direction == IntervalLabelDirection.fromBass) {
      return _labelWithOctaves(up);
    }

    final upClass = up % 12; // 0..11
    final downClass = (12 - upClass) % 12; // 0..11

    // Choose smallest class; preserve octave info only when "up" is chosen or tied.
    if (upClass <= downClass) {
      return _labelWithOctaves(up);
    }
    return _labelWithOctaves(downClass);
  }

  /// Labels by semitone count modulo 12.
  static IntervalLabel forSemitones(int semitones) {
    return _labelMod12(_mod12(semitones));
  }

  // -----------------------------
  // Core math helpers
  // -----------------------------

  static int _mod12(int n) => ((n % 12) + 12) % 12;

  /// Returns the smaller chromatic distance class (0..6) for an upward class (0..11).
  static int _smallestClass(int upClass) {
    final downClass = (12 - upClass) % 12;
    return (upClass <= downClass) ? upClass : downClass;
  }

  static String _sentenceCase(String s) {
    if (s.isEmpty) return s;
    final first = s[0].toUpperCase();
    return (s.length == 1) ? first : '$first${s.substring(1)}';
  }

  // -----------------------------
  // Base labels (mod 12)
  // -----------------------------

  static const List<IntervalLabel> _mod12Labels = [
    IntervalLabel(semitones: 0, short: 'P1', long: 'Unison'),
    IntervalLabel(semitones: 1, short: 'm2', long: 'Minor 2nd'),
    IntervalLabel(semitones: 2, short: 'M2', long: 'Major 2nd'),
    IntervalLabel(semitones: 3, short: 'm3', long: 'Minor 3rd'),
    IntervalLabel(semitones: 4, short: 'M3', long: 'Major 3rd'),
    IntervalLabel(semitones: 5, short: 'P4', long: 'Perfect 4th'),
    IntervalLabel(semitones: 6, short: 'TT', long: 'Tritone'),
    IntervalLabel(semitones: 7, short: 'P5', long: 'Perfect 5th'),
    IntervalLabel(semitones: 8, short: 'm6', long: 'Minor 6th'),
    IntervalLabel(semitones: 9, short: 'M6', long: 'Major 6th'),
    IntervalLabel(semitones: 10, short: 'm7', long: 'Minor 7th'),
    IntervalLabel(semitones: 11, short: 'M7', long: 'Major 7th'),
  ];

  static IntervalLabel _labelMod12(int s) {
    // s must be 0..11
    return _mod12Labels[s];
  }

  // -----------------------------
  // Compound / octave-aware labeling
  // -----------------------------

  static IntervalLabel _labelWithOctaves(int semitones) {
    final s = semitones.abs();
    final octaves = s ~/ 12;
    final within = s % 12;

    // Exact octave special-case: prefer "Perfect octave" over "Perfect 8th"
    if (within == 0 && octaves == 1) {
      return const IntervalLabel(
        semitones: 12,
        short: 'P8',
        long: 'Perfect octave',
      );
    }

    final base = _labelMod12(within);
    final baseNumber = _baseNumberFromShort(base.short);
    final number = baseNumber + (7 * octaves);
    final ordinal = _ordinal(number);

    final short = _compoundShort(base.short, number);

    // Long label rules:
    // - TT: keep "Tritone" and optionally annotate compound ordinal.
    // - within==0 and octaves>1: "Perfect 15th", etc.
    // - others: "Minor 10th", "Perfect 12th", etc.
    final long = _compoundLong(
      base.short,
      ordinal,
      within: within,
      octaves: octaves,
    );

    return IntervalLabel(semitones: s, short: short, long: _sentenceCase(long));
  }

  static String _compoundShort(String baseShort, int number) {
    if (baseShort == 'TT') {
      // TT, TT11, TT18, etc.
      return (number == 4) ? 'TT' : 'TT$number';
    }

    // 'm3' -> 'm10', 'P5' -> 'P12', etc.
    final qualityChar = baseShort[0]; // P/m/M
    return '$qualityChar$number';
  }

  static String _compoundLong(
    String baseShort,
    String ordinal, {
    required int within,
    required int octaves,
  }) {
    if (within == 0 && octaves > 1) {
      // Prefer "Perfect 15th", "Perfect 22nd", etc. over any
      // unison-derived wording, and avoid leaking "Unison" into compounds.
      return 'perfect $ordinal';
    }

    if (baseShort == 'TT') {
      return (octaves == 0 && within == 6) ? 'tritone' : 'tritone ($ordinal)';
    }

    final quality = _qualityLong(baseShort);
    return '$quality $ordinal';
  }

  static int _baseNumberFromShort(String short) {
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
        // Treat tritone as 4 for compound numbering consistency.
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
        return 1;
    }
  }

  static String _qualityLong(String short) {
    if (short == 'TT') return 'tritone';
    switch (short.isNotEmpty ? short[0] : '') {
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
