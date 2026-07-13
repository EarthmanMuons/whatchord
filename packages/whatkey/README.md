# whatkey

Streaming key (tonal center) detection for
[WhatChord](https://whatchord.earthmanmuons.com/). Pure Dart; consumes chord
evidence from the [whatchord](../whatchord/) engine.

The detector is a compact hidden Markov model run strictly forward in time: it
keeps a posterior over the 24 major and minor keys, updates it from committed
`ChordEvent`s, and abstains when the leading candidates are too close. The
`KeyBehavior` presets trade section-key stability against local-key
responsiveness, and display calibration keeps user-facing confidence honest
without changing the detector's decisions.

The design, evaluation protocol, and experiment record live in the [WhatKey
research directory][research], including the preprint describing the headline
results.

[research]:
  https://github.com/EarthmanMuons/whatchord/tree/main/research/whatkey

This package is consumed by the WhatChord app via the repository's pub workspace
and is not yet published; its public API is still being curated.
