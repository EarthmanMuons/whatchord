/// Converts a collection of notes into a pitch-class bitmask (bits 0..11).
///
/// Example: C (0) + E (4) + G (7) => mask with bits 0,4,7 set.
///
/// Contract:
/// - Input may be unsorted.
/// - Duplicates are fine.
/// - Result is stable and equality-friendly (int).
int pcMaskFromNotes(Iterable<int> notes) {
  var mask = 0;
  for (final n in notes) {
    mask |= 1 << (n % 12);
  }
  return mask;
}

int pcMaskFromMidiNotes(Iterable<int> midis) => pcMaskFromNotes(midis);
int pcMaskFromPcs(Iterable<int> pcs) => pcMaskFromNotes(pcs);
