import 'package:meta/meta.dart';

/// Minimal, cacheable input to chord analysis.
@immutable
class ChordInput {
  /// 12-bit pitch-class mask (bit `i` set means pitch class `i` is present).
  final int pcMask;

  /// Pitch class (0..11) of the lowest sounding note.
  final int bassPc;

  /// Number of sounding notes (voicing density heuristic, counts octave
  /// duplicates).
  final int noteCount;

  const ChordInput({
    required this.pcMask,
    required this.bassPc,
    required this.noteCount,
  });

  /// Stable key suitable for memoization.
  ///
  /// Layout:
  /// - bits 0..11: pcMask
  /// - bits 12..15: bassPc (0..11)
  int get cacheKey => pcMask | (bassPc << 12);

  @override
  String toString() =>
      'ChordInput(mask=0x${pcMask.toRadixString(16)}, bass=$bassPc, n=$noteCount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChordInput &&
          other.pcMask == pcMask &&
          other.bassPc == bassPc &&
          other.noteCount == noteCount;

  @override
  int get hashCode => Object.hash(pcMask, bassPc, noteCount);
}
