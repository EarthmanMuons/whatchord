# whatchord_theory

The pure Dart chord identification and harmony analysis engine behind
[WhatChord](https://whatchord.earthmanmuons.com/). No Flutter dependencies.

`ChordAnalyzer.analyze()` takes a `ChordInput` (set of pitch classes) plus an
`AnalysisContext` and returns ranked `ChordCandidate` results, using ranking
heuristics that encode musician-expected naming conventions. Supporting services
cover note spelling, chord quality intervals, scale harmonization, and scale
degree classification. Formatters render identities as chord symbols, spoken
names, long-form academic names, and Harte notation. The construction services
answer the inverse question: given a selected `ChordSpec` (root, quality,
extensions), derive a canonical example voicing and the compatible options.

This package is consumed by the WhatChord app via a path dependency and is not
yet published; its public API is still being curated as part of the extraction
from the app codebase.
