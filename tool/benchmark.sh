#!/usr/bin/env bash
# Run the chord engine performance baseline.
#
# Enables the VM service (for deterministic allocation measurement) and the
# counters compile-time define (for algorithmic operation counts), then replays
# the reviewed-oracle corpus through the engine. Writes benchmark/last_run.json
# and prints a summary.
#
# Usage: tool/benchmark.sh [--out=path/to/result.json] [--show-baseline]
set -euo pipefail

cd "$(dirname "$0")/.."

for arg in "$@"; do
  case "$arg" in
    -h|--help|--show-baseline)
      exec dart run benchmark/analyze_benchmark.dart "$@"
      ;;
  esac
done

exec dart run \
  --enable-vm-service \
  --define=whatchord.counters=true \
  benchmark/analyze_benchmark.dart "$@"
