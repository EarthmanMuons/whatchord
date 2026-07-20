# 2026-07-20: Local-key error structure (WhatKey lead)

**Goal.** Entry 2026-07-20-17 found the Track B spelling residual is 98%
key-detection error. This entry asks the follow-up: does that error have a
structure pointing at an addressable WhatKey improvement?

**Framing (load-bearing).** This scores per-event LOCAL-key agreement against
the annotated local keys. WhatKey is optimized and FROZEN for SECTION-key
stability, a different and easier target; local-key tracking is a declared
separate project (`research/whatkey/log/2026-07-08-04`). Nothing here is a
WhatKey result under its protocol, and no change is proposed. This is a
characterization run on the chord-context DCML ruler to decide whether a
local-key project is worth opening under the WhatKey protocol.

**Setup.** `tool/chord-context/key_error_diagnostic.dart` runs the shipped
`HmmKeyDetector` over the DCML development split and buckets each claimed
event's inferred key by relation to the annotated local key (exact, relative,
parallel, dominant/subdominant, other), flags mismatches that match a nearby
annotated key as tracking lag, and reports across the three behavior presets,
since balanced and reactive are the local-key-leaning settings.

```sh
for mode in stable balanced reactive; do
  dart run tool/chord-context/key_error_diagnostic.dart \
    --fixtures build/chord-context/fixtures/dcml-distant-listening-v1-span \
    --labels build/chord-context/labels/dcml-distant-listening-v1-span.labels.json \
    --split-file research/chord-context/data/splits/dcml-distant-listening-v1.json \
    --split development --behavior $mode --out build/chord-context/key-diag/$mode
done
```

**What happened.**

| preset   | coverage | exact-on-claimed | fn-adjacent errors | other | lag share |
| -------- | -------- | ---------------- | ------------------ | ----- | --------- |
| stable   | 91.0%    | 61.1%            | 26.8%              | 12.1% | 16%       |
| balanced | 87.8%    | 65.2%            | 23.6%              | 11.2% | 20%       |
| reactive | 82.9%    | 65.7%            | 22.7%              | 11.5% | 17%       |

Two clear signals:

1. **The modes behave as the local-key literature says.** Shortening emission
   memory raises local-key exactness (+4.6 points stable to reactive) at a
   coverage cost (abstention 9% to 17%), the classic selective-prediction
   tradeoff. Balanced already recovers most of the gain at less coverage cost.
   This reproduces `research/whatkey/log/2026-07-08-04` on an independent
   corpus.
2. **The dominant structure of the error is functional adjacency, not noise.**
   Under stable, of the ~39% non-exact claims, roughly two-thirds are
   functionally adjacent keys: dominant +5th (7.9%), subdominant -5th (7.5%),
   relative (8.6%), parallel (2.7%). Only 12% are unrelated ("other"), and only
   ~16% of all mismatches are pure tracking lag. So the detector is not mostly
   lost or merely late; it is mostly choosing a key a fifth away or the
   relative, which is exactly what a tonicized V or IV, or a passing modulation,
   looks like to a fifths-decay transition prior with no cadence model.

**Plain-English reading.** When the key detector is wrong about the local key,
it is usually wrong in a musically specific way: it hears a tonicization of the
dominant or subdominant, or the relative major/minor, and follows it as if the
piece had modulated. That is the signature of a detector that weights recent
pitch content but has no model of cadential arrival to tell a real key change
from a temporary one. It is a real, nameable weakness, and it is precisely the
kind of thing a local-key project would target, but confirming and fixing it is
WhatKey work under WhatKey's protocol and rulers, not a chord-context change.

**Decisions.**

- There IS an indication worth acting on, recorded as a lead for a future
  WhatKey local-key initiative, not adopted here: the largest structured error
  is dominant/subdominant/relative confusion (~24-27% of claims), the
  tonicization-vs-modulation problem. A cadence- or progression-aware transition
  model (WhatKey already prototyped progression features; see its detectors) is
  the natural candidate, and the fifths-decay/self-transition priors are the
  natural knobs.
- The mode axis is a shipped, zero-cost lever for anyone who wants better
  local-key tracking today: balanced already buys +4 points of local-key
  exactness. This is not new grounds to change the shipped default (chosen for
  section-key stability; naming is preset-indifferent per entry -03), but it is
  the honest current answer to "can we track local key better."
- Any real work here must run under the frozen WhatKey protocol
  (`research/whatkey/PROTOCOL.md`) on its rulers (When-in-Rome, ASAP), with this
  DCML characterization as motivation only. The chord-context initiative does
  not own key detection.

**Next.**

- If pursued, open a WhatKey local-key entry citing this characterization and
  `research/whatkey/log/2026-07-08-04`, and test a cadence-aware transition
  prior against the section-key baseline on the WhatKey rulers.
- Otherwise this closes the chord-context initiative's investigation: every
  front is shipped, closed, or costed, and the one cross-cutting lead (local-key
  detection) is handed to WhatKey with its error structure characterized.
