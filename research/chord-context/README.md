# Chord Context

Using recently played chords, and the key they imply, to improve WhatChord's
live chord naming. The investigation is complete: its findings are validated on
held-out data (log entry 2026-07-20-21), and every front named in the design doc
is shipped, closed, or costed.

## Outcome

The founding hypothesis was that tracking prior chords would improve live
naming. Measured against a strong snapshot-plus-key baseline on two corpora (the
DCML Distant Listening classical corpus and When-in-Rome, plus an Isophonics
pop/rock census), it mostly did not: the temporal cues were inert or harmful
once key context was accounted for. The wins came from two adjacent, simpler
places the measurement surfaced instead.

**Shipped:**

- **The key-functional seventh over its sixth-chord twin** (lever 0): under the
  prevailing key, a minor7 on the supertonic (and the half-diminished cases)
  beats the sixth chord sharing its notes. This one enharmonic family was the
  entire clean-pool naming headroom on both corpora; the rule lifts clean-pool
  identity accuracy ~2 points with zero measured harm, held-out confirmed. (Log
  entries 2026-07-20-01 through -04.)
- **F# as the six-sharp key side** in the WhatKey key space, decided on
  two-corpus evidence after a false start, so the app spells F# major (and its
  chords) the way scores and pop/rock annotators do. (Entries -09 through -11.)

**Closed by measurement:**

- Track A live temporal re-ranking (cues inert/harmful vs the key baseline,
  entry -05); the windowed enharmonic side-chooser (superseded by the F# fix,
  entries -07/-08); the extra-tones "capped-rule" market (a span-view artifact,
  entry -12); and the Track B spelling residual (98% key-detection error, not
  spelling, entry -17). History relabeling has a decisive mechanism but no
  downstream value and only a passive-log surface (entry -15).

**Costed, handed off:**

- **Track D (jazz ensemble/rootless mode):** the shipped engine names 0% of
  rootless comping voicings; an explicit-mode implementation (ghost-root
  templates + diatonic key filter + guide-tone tiebreak) reaches ~82% under the
  app's own key, ~90% with the tiebreak, measured on 13,197 real chords (entries
  -16, -19). A product decision, pursued outside this project.
- **Local-key detection** as a WhatKey lead: the key errors are functionally
  structured (dominant/subdominant/relative confusion), the signature of a
  detector with no cadence model, and the local-key-leaning presets already help
  (entry -18). Belongs to a future WhatKey initiative under its protocol.
- **Augmented-sixth spelling:** scoped, ~0.7% of events, spelling-only, and
  contested for a lead-sheet audience; documenting a design choice, not headroom
  (entry -20).

## Contents

- [Design and plan](temporal-context-chord-recognition.md): the founding
  document; four tracks (contextual re-ranking, contextual spelling, display
  stability, rootless/ensemble gate), product contract, architecture, plan.
- [Protocol](PROTOCOL.md): the frozen evaluation protocol; rulers, ground-truth
  rules, split discipline, metrics, adoption bar.
- [Data](data/): frozen split definitions and the comping suite; conventions in
  `data/README.md`.
- [Contextual spelling notes](contextual-spelling-notes.md) and
  [rootless voicings notes](rootless-voicings-notes.md): design sketches for
  Tracks B and D.
- [m7/6 family notes](m7-sixth-family-notes.md): the musical review behind the
  shipped lever 0 rule, with sources.
- [Log](log/): dated, append-only record of every experiment and decision.

Supporting code is in `tool/chord-context/` (label generation and the
measurement harnesses), run via the `research:chord-context-*` mise tasks.
Derived artifacts stay in `build/chord-context/`; the CC BY-NC-SA DCML fixtures
are build-only and never committed.
