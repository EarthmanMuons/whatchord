# 2026-07-19: Phase 0 headroom study on When-in-Rome

**Status (revised same day, before commit).** This is pre-protocol scouting, not
adoption evidence. It ran on the development split only (the when-in-rome-v1
test split is unspent), but before any evaluation protocol was frozen, with
metrics and ground-truth rules defined ad hoc in the tooling. Ground-truth
caveats: music21 acts as the RomanText parser (the annotation itself is the
analyst's figure plus key), and the clean pool requires realized pitches to
equal the sounding set, which cross-checks the realization; but root and quality
still come from the realization, the interval-mask quality mapping is unaudited,
category tags key off music21 commonName prose, and events were scored against a
single expected identity rather than the acceptable-answer sets the design doc
calls for. The findings below set scope for the protocol; every number must be
re-established under the frozen protocol before informing an adoption decision.

**Goal.** Measure the headroom the chord-context initiative is chasing before
building anything (Phase 0 of `../temporal-context-chord-recognition.md`): on
annotated corpus events, how often is the musician-expected identity already
top-1, how often is it merely losing a near-tie (the Track A tie-breaker
market), how often is it outside the near-tie window but generated (the
capped-rule market), and how often is it not generated at all (Track D or
generation territory)? Also measure the key-oracle: does ranking under the
annotated local key recover anything today?

**Setup.** Engine commit `4b709a17` (lib code unchanged; the two tools below are
new in this change). Fixture set `when-in-rome-v1` (committed), split file
`research/whatkey/data/splits/when-in-rome-v1.json`, development split only (59
pieces; the test split stays unspent). music21 10.1.0 realizes each event's
RomanText figure in its annotated local key; expected qualities map from
root-relative interval sets to `ChordQuality` enum names. The harness
re-analyzes each event's sounding notes at `take: 10000` under the neutral
fixture context (`C:maj`) and the annotated key, with voicing evidence, and
buckets the best-ranked matching candidate by cost gap: top1, near-tie (within
0.25), prune margin (within 2.0), generated, absent. Events with fewer than
three sounding notes are excluded (the app's history gate).

```sh
mise research:chord-context-labels-wir
mise research:chord-context-headroom-wir-dev
```

Reports land in `build/chord-context/headroom/wir-dev/` (report.json embeds the
configuration; report.txt is the summary table).

**What happened.** 3694 dev-split events, categorized by how the sounding set at
the annotation onset relates to the realized annotation:

- `ok` (sounding == annotation pcs): 1594 (43.2%)
- `mismatch` (annotation tones missing): 990 (26.8%)
- `rootless` (annotated root not sounding): 643 (17.4%)
- `symmetric-root`: 230 (6.2%), `extra-tones` (annotation pcs plus extras): 119
  (3.2%), `explicit-or-incomplete`: 73 (2.0%), `functional-label` (augmented
  sixths): 44 (1.2%), `unmapped-quality`: 1

All 286 distinct figures realized; nothing was unrealizable.

Clean pool (`ok`, n=1594), root+quality level, cumulative:

| context   | top1  | near-tie ceiling | prune | generated |
| --------- | ----- | ---------------- | ----- | --------- |
| neutral   | 97.9% | 100.0%           | 100%  | 100%      |
| annotated | 97.8% | 100.0%           | 100%  | 100%      |

Per-piece means match (98.8% top1 neutral, 98.7% annotated, 56 pieces with clean
events). Every clean-pool miss sits inside the near-tie window.

The 34 misses are a single family: seventh-chord inversions named as
root-position sixth chords on the same pitch classes.

- `ii65`-type (minor7 first inversion, e.g. Dm7/F in C) named as major6 on the
  bass (F6): 13 cases (`ii65`, `ii6/5`, `iv65`, `vi65`, `iv42`).
- `iiø65`-type (half-diminished first inversion, e.g. Dø7/F in C minor) named as
  minor6 on the bass (Fm6): 21 cases (`iiø65`, `iiø42`, `iiø43`, `viiø65`,
  `viiø42`).

Transition-conditioned (clean pool, neutral, root+quality): after a dominant
99.5% top1, after a predominant 99.5%, after other figures 95.2% (n=600), first
events 100%. The "other" cell is where the m7/6 family concentrates.

Extra-tones pool (n=119): top1 30.3%, near-tie adds nothing, prune ceiling
77.3%, generated 94.1%; at root-only level 59.7% / 68.9% / 100%. Mismatch pool
(n=990, weak ground truth since the annotated chord is not fully sounding): top1
14.8% root+quality, 46.8% root-only.

**Plain-English reading.** On cleanly sounding chords the snapshot analyzer
already names 98 in 100 the way the analyst labels them, and for the remaining 2
the expected reading is always sitting right next to the chosen one in cost,
close enough that a tie-breaker may pick it. So the entire re-ranking
opportunity on clean classical events is about two points, and all of it is one
ambiguity: when a seventh chord appears in inversion (Dm7 with F in the bass),
WhatChord prefers to name the bass note as the root (F6). Both names are
defensible on a lead sheet; the analyst's functional label is the contextual
reading. Knowing the key does not fix this today: ranking under the annotated
key changed almost nothing, which extends the earlier WhatKey closed-loop
finding (the feedback path was inert) from key detection over to chord accuracy.
Where extra non-chord tones sound at the same time, the expected name usually
exists in the ranking but sits well outside the near-tie window, so only a
stronger, capped intervention could choose it. The 17% of events where the
annotated root is not sounding at all is mostly an artifact of sampling
arpeggiated classical textures at an instant, not jazz-style rootless comping,
so it says little about the Track D gate.

**Decisions.**

- The Track A / lever 0 target case is the m7-inversion vs. sixth-chord pair
  (`ii65` and `iiø65` families). It is 100% of the clean-pool headroom, it is
  tonality-legible (a predominant-function reading in the prevailing key), and
  it is already near-tie, so both a sharper tonality tie-breaker (lever 0) and
  prior-chord cues (Track A) can be evaluated against it directly.
- The key-oracle result confirms lever 0's premise: key knowledge is available
  and the expected reading is surfaced, but today's rules do not connect them.
  Any lever 0 rule must be checked against Explore-mode and isolated-voicing
  expectations before adoption, because the bass-rooted sixth-chord name is the
  correct isolated reading; this is a context-conditional preference, not a
  global one.
- The extra-tones pool, not the clean pool, is where capped-rule promotion would
  matter; defer until the m7/6 family is settled.
- The `rootless` category on this corpus is a windowing artifact and must not be
  cited as Track D gate evidence; the gate needs the hand-authored comping
  suite.
- pop-jazz-v2 is excluded from headroom scoring: its hand-authored figures use
  lead-sheet shorthand (blues `I7` means a dominant), not RomanText semantics,
  so realization would produce wrong ground truth. Charts need explicit
  expected-identity labels before that suite can participate.
- Phase 0 artifacts stay in `build/` (regenerable from committed fixtures and
  pinned music21); nothing is frozen yet.

**Next.** (Reordered same day after review: protocol first.)

- Freeze the evaluation protocol before any lever 0 or cue work: ground-truth
  rules per corpus (realization as a validated parser with an audited mapping,
  acceptable-answer sets for contestable categories), a music21-independent
  ruler scored against human chord symbols in Harte space, per-corpus split
  freezes before fixture inspection, metrics, and the adoption bar.
- Re-run this headroom study as the first experiment under the frozen protocol;
  only then design the lever 0 tonality tie-breaker against the m7/6 inversion
  family.
- Musical review of the 34 miss cases (report.json `misses`): confirm the
  analyst reading is the display we want in context, and decide what the display
  should do mid-progression versus in isolation.
- Author expected-identity labels for the pop-jazz charts and the planned
  comping suite so a behavioral non-classical ruler exists.
