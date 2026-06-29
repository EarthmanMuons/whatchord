/// A fixed, allocation-free CPU workload used to normalize wall-clock time.
///
/// Time on shared CI runners is noisy and hardware-dependent, so absolute
/// numbers are not comparable across runs. Dividing the engine's time by the
/// time this fixed workload takes on the same machine cancels most of that
/// hardware variance: a runner that is 2x slower runs both halves slower, so
/// the ratio stays roughly constant. The work is pure integer mixing (xorshift)
/// so it allocates nothing and reflects raw CPU speed only.
int referenceWork(int iterations) {
  var acc = 0x9e3779b97f4a7c15;
  for (var i = 0; i < iterations; i++) {
    acc ^= acc << 13;
    acc ^= acc >>> 7;
    acc ^= acc << 17;
    acc += i;
  }
  return acc;
}

/// Iteration count for one reference workload. Sized to run for ~0.8 ms: long
/// enough that the 1 us `elapsedMicroseconds` quantization is a ~0.1% floor
/// (negligible against the ~1.4% OS-scheduling jitter that dominates at any size
/// from here up), short enough to sample quickly. Below ~0.2 ms the fixed jitter
/// and quantization start to bite; see the "normalization scale" note in
/// docs/design/chord-ranking-performance.md for the measurements behind this.
const int referenceIterations = 400000;

/// Display multiplier for the normalized time score. The raw `engine /
/// reference` ratio is dimensionless and its magnitude is arbitrary, so we scale
/// it for readability. With the workload sized so the adversarial oracle pass is
/// about one reference workload (ratio ~1.0), x100 puts that headline score near
/// 100 and the common pool near 20: clean two-to-three digit integers, easy to
/// eyeball as percentages, with room to keep shrinking as the engine speeds up.
/// Scaling cannot help the warm (cache-hit) path, which is ~4 orders of
/// magnitude smaller than any sane reference and stays near zero as a "cache is
/// working" sanity line. Purely cosmetic: a uniform factor leaves every relative
/// delta and confidence interval unchanged.
const double referenceDisplayScale = 100.0;
