# 2026-07-06: Reproduction procedure

**Goal.** Make the WhatKey Phase 2 data preparation path reproducible from a
fresh checkout without relying on scattered command history or memory.

**Setup.** Repository after the `when-in-rome-v1` license gate and frozen split.
External pins remain Contrapunctus benchmark
`b9e011c8cf34c5e76691dcf2c835b8c99ebd9d59` and When-in-Rome submodule
`aa7539f1cf480997a68998405c0783ebf6339c16`.

**What happened.** Added `research/whatkey/REPRODUCING.md` with exact steps for
the external benchmark clone, submodule initialization, pin verification, TAVERN
machine-state score prep, hand-authored fixture regeneration, When-in-Rome
fixture generation, split regeneration, expected fixture/split counts, and
license-boundary checks. Linked it from the WhatKey README reading order.

**Decisions.**

- Keep reproduction instructions in a dedicated WhatKey document rather than
  scattering them across logs, `mise.toml`, and provenance notes.
- Treat generated When-in-Rome fixtures under `build/` as reproducible
  intermediate artifacts until committed fixture packaging and attribution are
  finalized.
- Require split regeneration from the generated fixture manifest, not only from
  the upstream corpus manifest, so the split references actual harness inputs.

**Next.** Use `REPRODUCING.md` as the entry point before building or rerunning
the offline harness, and update it whenever the fixture version, corpus pins, or
data-prep commands change.
