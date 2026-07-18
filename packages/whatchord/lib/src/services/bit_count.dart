/// Bitwise population-count utilities.
library;

/// Returns the number of set bits in a non-negative bit mask.
///
/// Uses Kernighan's algorithm, which visits only set bits.
int popCount(int mask) {
  var count = 0;
  while (mask != 0) {
    mask &= mask - 1;
    count += 1;
  }
  return count;
}
