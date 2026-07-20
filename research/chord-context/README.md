# Chord Context

Using recently played chords to improve WhatChord's live chord naming. The
evaluation protocol froze 2026-07-19; measurement infrastructure is being built
against it.

- [Design and plan](temporal-context-chord-recognition.md): the founding
  document; four tracks (contextual re-ranking, contextual spelling, display
  stability, rootless/ensemble gate), product contract, architecture, phased
  plan.
- [Protocol](PROTOCOL.md): the frozen evaluation protocol; rulers, ground-truth
  rules, split discipline, metrics, adoption bar.
- [Data](data/): frozen split definitions; conventions in `data/README.md`.
- [Contextual spelling notes](contextual-spelling-notes.md): augmented-sixth
  test cases and the line-of-fifths window heuristic (Track B).
- [Rootless voicings notes](rootless-voicings-notes.md): the ensemble-mode
  design sketch behind the Track D gate.
- [Log](log/): dated, append-only record of experiments and decisions.

Supporting code lives in `tool/chord-context/` (expected-identity label
generation and the headroom harness), run via the `research:chord-context-*`
mise tasks. Derived artifacts stay in `build/chord-context/` until a protocol
freeze decides what gets committed.
