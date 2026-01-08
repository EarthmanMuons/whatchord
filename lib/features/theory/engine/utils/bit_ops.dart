/// Bitwise popcount utility for small integer masks using the standard
/// Kernighan algorithm.
int popCount(int v) {
  var c = 0;
  while (v != 0) {
    v &= v - 1; // clear lowest set bit
    c++;
  }
  return c;
}
