import 'package:meta/meta.dart';

/// Minimal, cacheable input to chord analysis.
///
/// - [pcMask]: 12-bit pitch-class mask (bit i set means pitch class i present).
/// - [bassPc]: pitch class (0..11) of the lowest sounding MIDI note.
/// - [noteCount]: number of sounding MIDI notes (voicing density heuristic).
@immutable
class ChordInput {
  final int pcMask;
  final int bassPc;
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
  /// - bits 16..23: noteCount (0..255; plenty for MIDI note sets)
  int get cacheKey => pcMask | (bassPc << 12) | (noteCount << 16);

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
