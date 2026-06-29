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

/// Iteration count for one reference unit. Sized to run for a few milliseconds
/// so timing is stable without dominating the benchmark. The absolute value is
/// arbitrary; only its stability across runs matters.
const int referenceIterations = 4000000;
