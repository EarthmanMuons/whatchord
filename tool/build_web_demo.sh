#!/usr/bin/env bash
#
# Compiles the pure-Dart chord analysis engine to JavaScript for the website
# chord-identification demo (docs/site/try.html).
#
# The output (docs/site/js/chord-id.js) is a generated artifact. Re-run this
# whenever the theory engine or tool/src/chord_id_engine.dart changes.
#
# Usage: tool/build_web_demo.sh

set -euo pipefail

cd "$(dirname "$0")/.."

entry="tool/web/chord_id_main.dart"
out="docs/site/js/chord-id.js"

mkdir -p "$(dirname "$out")"

echo "Compiling $entry -> $out"
dart compile js "$entry" -o "$out" -O2 --no-source-maps

# dart compile js emits a .deps sidecar we don't want to ship.
rm -f "$out.deps"

size=$(du -h "$out" | cut -f1)
echo "Done. $out ($size)"
