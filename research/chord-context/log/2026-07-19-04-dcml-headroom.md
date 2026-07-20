# 2026-07-19: DCML headroom, the first frozen-protocol result

**Goal.** Produce the first headroom measurement under the frozen protocol
(entry 2026-07-19-03) on the DCML development split, and test whether the
pre-protocol When-in-Rome scouting findings (entry 2026-07-19-01) replicate on a
much larger corpus whose ground truth involves no naming interpreter.

**Setup.** Engine commit `4b709a17` (lib code unchanged; the extractor and
harness runs below are tool-side only). Corpus: DCML distant listening pinned
tag `v3.1` (split `data/splits/dcml-distant-listening-v1.json`, its pins
validated against the fixture manifest by the harness), data from the Zenodo
v3.1 datapackage TSVs. Fixtures: `dcml-distant-listening-v1-span` (span view:
notes aggregated over each label's quarterbeat span), generated build-only for
the full split; the harness gates to the development split (935 pieces).
Expected identities derive from the annotation standard's decomposed columns by
line-of-fifths arithmetic only. Ground-truth guards in the extractor: rows with
a non-empty `changes` field or whose `chord_tones` disagree with `chord_type`
(22,682 of 235,949 events across the full split) are categorized
explicit-or-incomplete, since the decomposed identity there describes the
functional chord, not the literal sonority; `Ger/It/Fr` are functional-label;
`o7`/`+` symmetric-root. Only 3 rows in the whole corpus were unrealizable
(Scarlatti labels with empty decomposed columns). A verification pass on the
first extraction caught a mode-parsing bug (the `*_is_minor` columns are
`0`/`1`, not `True`/`False`, so every local key had read as major, shifting
degrees III/VI/VII in minor-global pieces): the tell was zero minor-key misses.
The extractor now parses both forms and cross-checks the boolean against the
global key name's case; fixtures were regenerated and all numbers here are from
the corrected pipeline.

```sh
mise research:chord-context-prepare-dcml
mise research:chord-context-fixtures-dcml
mise research:chord-context-headroom-dcml-dev
```

Reports land in `build/chord-context/headroom/dcml-dev/`.

**Normativity note.** Per the freeze's handover rule, this entry records the
landing of the scoring code for the metrics it implements: agreement at
root+quality and root-only levels, the oracle ceilings, and the key-oracle
diagnostic (`tool/chord-context/headroom.dart`, labels via
`tool/chord-context/dcml_extract.py` and `labels_common.py`). Not yet
implemented: the exact strictness level (bass), acceptable-answer sets (those
categories are excluded, not scored), and paired A/B statistics (nothing is
being compared yet; this is a single-system measurement).

**What happened.** 182,732 development-split events. Categories: ok 29.9%,
extra-tones 22.3%, mismatch 18.9%, explicit-or-incomplete 12.6%, below-min-notes
8.8%, symmetric-root 3.6%, rootless 3.2%, functional-label 0.6%, unlabeled 0.1%.

Clean pool (`ok`, n=54,570), root+quality, cumulative:

| context   | top1  | near-tie ceiling | prune | generated |
| --------- | ----- | ---------------- | ----- | --------- |
| neutral   | 97.5% | 100.0%           | 100%  | 100%      |
| annotated | 97.5% | 100.0%           | 100%  | 100%      |

Per-piece means: 97.2% top1 under both contexts (923 pieces with clean events).
Every clean-pool miss is inside the near-tie window, exactly as on When-in-Rome.

The 1,344 misses (793 in major local keys, 551 in minor) are one family,
cross-corpus confirmation of the scouting taxonomy: 881
halfDiminished7-in-inversion named minor6 on the bass (`ii%65`, `ii%43`, `ii%2`,
`vii%43`, ...), 461 minor7-in-inversion named major6 (`ii65`, `iv65`, `vi65`,
...), plus 2 related dominant7Sharp5-vs-augmented readings. Nothing else.
Structure of the misses: the chosen sixth-chord root sits on degree IV of the
local key in 55% of cases (the ii65-vs-IV6 pair in both modes), and 63% of miss
events move directly to a dominant-function chord next, textbook predominant
behavior; what precedes is spread across tonic (35%), dominant (33%), and
predominant (27%) function.

Transitions (clean pool, neutral, root+quality): after dominant 98.8% top1
(n=24,804), after predominant 96.0% (n=9,141), after other 96.7% (n=20,355). The
family concentrates after predominants and "other" chords, consistent with
ii65-family chords beginning predominant spans.

Extra-tones pool (n=40,834): top1 39.6%, near-tie ceiling 45.0%, prune 71.8%,
generated 84.3%; root-only 59.8% / 72.9% / 99.5% / 100%. Unlike the clean pool,
the near-tie window adds real mass here (+5.4 points), and the annotated key
nudges top1 (+0.7). Mismatch pool (n=34,614, weak ground truth): 50.1% top1 at
root+quality, 72.7% root-only.

**Plain-English reading.** On a corpus 33 times larger than the scouting ruler,
annotated by different analysts under a different standard, with ground truth
that never passes through any third-party naming code, the same picture emerges:
the snapshot analyzer names about 49 of every 50 cleanly sounding chords the way
the analyst does, the expected reading for the rest is always sitting within
tie-breaking distance, and every single such miss is the same ambiguity: a
seventh chord in inversion named as a sixth chord on its bass note. Knowing the
key still does not fix it, which means the fix is a rule that connects key or
progression context to this specific choice, not more key information. Where
spans contain passing tones, the expected name usually exists but is priced too
far away for a tie-breaker; that pool is the market for a stronger, capped
intervention.

**Decisions.**

- The m7/6 inversion family is confirmed as the sole clean-pool target for lever
  0 and Track A, now with a dev-split population large enough for paired
  per-piece statistics (1,344 events across hundreds of pieces).
- Span view is the v1 fixture semantics for DCML; the instant view remains
  available in the extractor (`--view instant`) for the span-vs-instant
  comparison when a question needs it.
- The explicit-or-incomplete guard (changes present, or tones inconsistent with
  type) stays: suspensions are real Track A material eventually, but their
  decomposed labels do not describe the sounding sonority, so scoring them as
  identity ground truth would be wrong.
- When-in-Rome frozen results remain blocked behind the realization audit and
  acceptable-answer sets (entry -03 preconditions); this DCML result needed
  neither, which is why it is the first frozen result.

**Next.**

- Musical review of the m7/6 family: decide the display-correct behavior in and
  out of context (the bass-rooted sixth-chord name is the correct isolated
  reading; the inversion reading is the contextual one).
- Design the lever 0 tonality tie-breaker against this family and evaluate with
  paired per-piece statistics on this ruler and When-in-Rome dev.
- Implement the exact strictness level and acceptable-answer sets; run the
  When-in-Rome audit so that ruler can produce frozen results.
- Extend the harness comparison machinery (Wilcoxon, CI95) before the first A/B
  adoption decision, per the protocol's statistics section.
