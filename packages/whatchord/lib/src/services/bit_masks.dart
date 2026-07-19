/// Bit-mask utilities shared across the analysis and formatting layers.
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

/// The interval positions (0..11) of the set bits in a 12-bit mask,
/// ascending.
List<int> intervalsFromMask(int mask) {
  return [
    for (var interval = 0; interval < 12; interval++)
      if ((mask & (1 << interval)) != 0) interval,
  ];
}
