# Temporal Context for Chord Recognition

Status: DRAFT proposal, 2026-07-19. Nothing here is frozen; the evaluation
protocol freezes in Phase 1, and until then every decision in this document is
open to revision.

This is the founding design document for the chord-context initiative: using
recently played chords to improve WhatChord's live chord naming. It follows the
structure that worked for WhatKey (`research/whatkey/`): a design doc first, a
frozen protocol and versioned corpus before any tuning, dated append-only logs,
and paired per-piece statistics as the adoption bar.

## Research question

Can causal temporal context (the chords a player just played) measurably improve
live chord naming toward musician-expected labels, without changing the pure
snapshot analyzer, without destabilizing the real-time display, and without a
perceptible performance cost?

## Why this is plausible, and why it is not obvious

The motivating cases are real: dominants read differently after a ii chord,
suspensions resolve, diminished chords reveal function through motion, rootless
comping voicings are unidentifiable from a single snapshot, and the German sixth
is pitch-class identical to a dominant seventh. All of these are cases where a
musician's expected label depends on surrounding context that the snapshot
analyzer cannot see.

But the repository already contains one strong negative result that shapes this
initiative. The closed-loop probe
(`test/probes/_whatkey_closed_loop_probe_test.dart`, recorded in
`research/whatkey/key-behavior-modes.md`) re-ranked every fixture event under
the key the app would have adopted, versus neutral context, across 3694 events:
identity churn was ~0.4% and no summary metric moved. Key context, the one
temporal signal already wired into ranking through the tonality-gated
tie-breakers, almost never flips a top identity. Two lessons:

1. Temporal context beyond key must earn its place with evidence that it is not
   redundant with the key loop that already exists (history -> WhatKey ->
   adopted tonality -> `AnalysisContext` -> tie-breakers).
2. The snapshot analyzer may simply be right more often than the motivating
   examples suggest, or the right answer may not even be in the candidate list
   (rootless voicings, where the true root is excluded by the no-ghost-roots
   rule). Where the ceiling is determines what is worth building.
3. The probe measured today's coupling, not key context's ceiling. Most
   tie-breakers never consult tonality at all, so the inert result says the
   current rules barely use key, not that key cannot help. Deepening tonality
   coupling in the existing snapshot rules is therefore a lever in its own right
   (lever 0 below), cheaper than any temporal layer and free of product contract
   questions, and Phase 0 must measure its ceiling separately from temporal
   headroom.

So the first deliverable is not a re-ranker. It is a headroom measurement.

## Decomposition: four separable products

"Temporal context" conflates four different products with different risk
profiles, different layers, and different metrics. This initiative treats them
as separate tracks with separate gates.

**Track A: contextual re-ranking.** Prior chords bias which near-tie candidate
wins for the currently sounding notes. Example: after G7, prefer the C-family
reading of an ambiguous voicing. Acts only within the surfaced candidate set;
bounded by the same cost-cap discipline as the existing hard rules. This is the
core track.

**Track B: contextual spelling and notation.** The pitch-class identity is
unchanged; the spelling of the symbol and its members responds to context.
Examples: German sixth vs. Ab7 (Ab C Eb F# in C minor vs. Ab C Eb Gb as a
functioning dominant), sharps for ascending chromatic lines, the line-of-fifths
window heuristic (minimize the fifths-width of the recent pitch set, prefer
diatonic semitones, treat the last semitone of a chromatic line as diatonic).
Presentation-layer only, so lower product risk, and it directly addresses
several motivating examples that Track A cannot (they are enharmonic, not
ranking, problems). Working notes: `contextual-spelling-notes.md`.

**Track C: display stability.** Short hysteresis so the live display does not
flicker through transitional names during finger rolls and voicing changes. The
display path today has zero hysteresis; the only debounce in the system is the
history segmenter's 200 ms commit rule, which does not feed the display. This
track trades perceived latency for stability and needs its own metric (churn),
not accuracy.

**Track D: rootless and ensemble voicings.** Naming E Bb D A as C13 requires a
root that is not sounding, which candidate generation currently forbids
(`chord_analyzer.dart`, no ghost roots). This is a candidate-generation change
plus a bass-weighting change (played bass vs. functional bass), likely surfaced
as an explicit ensemble/comping mode, with temporal root-continuity as
supporting evidence. It is the largest contract change and is gated separately:
this initiative's corpus tags rootless cases from day one so the gate decision
is informed, but no engine work happens until the gate. Working notes:
`rootless-voicings-notes.md`.

Retrospective relabeling (a resolution retroactively renaming the previous
chord) is deliberately out of scope for the live display. Several motivating
examples (diminished function, sus resolution, dominant confirmed by fifth
resolution) are inherently retrospective: the information arrives after the
chord ends. Causal context cannot use them for the live label. They map either
to Track B spelling (where key context often substitutes for the resolution,
e.g. the German sixth is preferable to Ab7 in a C minor context before the
resolution arrives) or to a possible future history-view product that relabels
committed events. That product would be additive and low-risk (history is
already a committed record, not a live display) but it is not part of this
initiative's first pass.

## Product contract

Answers to the open questions in the original notes, as testable commitments:

- **Causality.** Context flows forward only, and forward is the product: the
  chords just played inform the label of the chord sounding now, well before the
  current chord is itself captured into history. What is excluded is the reverse
  direction. The live label is computed from context that existed at the chord's
  onset, so a held chord never renames itself because of the temporal layer, and
  later events never rename earlier ones on the live display. (The existing key
  loop can already rename a held chord when adoption lands; that behavior is
  unchanged and out of scope.) This requires care with the segmenter's commit
  lag: the previous chord commits to history only after the current identity
  survives `minChordDuration` (200 ms), so committed history alone is stale at
  onset. The re-ranker therefore consumes a live context view (committed events
  plus the in-flight previous identity from the segmenter) rather than committed
  history alone.
- **Context lifetime.** Chord-to-chord functional cues decay much faster than
  key. Starting point: the previous one to two identities, with a time decay on
  the order of a few seconds, tuned on the corpus. Long silence clears context
  entirely; align the reset with the existing key staleness windows rather than
  inventing a new timescale, unless tuning says otherwise.
- **Sustain pedal.** Unchanged. Pedal-merged notes are one sonority (one
  `ChordInput`); the segmenter's identity-change semantics already define where
  one chord ends and the next begins. Temporal context uses the segmenter's
  boundaries and does not redefine them.
- **Repeated notes and melodic lines.** Out of scope for Track A (the segmenter
  absorbs sub-threshold identities). Relevant to Track B's line-of-fifths
  spelling, which operates on a rolling pitch window, not on chord boundaries.
- **Determinism and layering.** `ChordAnalyzer.analyze()` stays pure and
  snapshot-only. The temporal layer is a wrapper that consumes the analyzer's
  output (`List<ChordCandidate>` with intact costs) plus context, and returns a
  re-ordered list. With empty context its output is bit-identical to the
  snapshot ranking; this is a permanent regression guarantee, tested.
- **Explainability.** Any temporal rule that changes the top candidate must be
  visible through the existing explain channel (`ExplainedCandidate` /
  `RankingDecision.decidedByRule`), so chord-debug can show raw vs. contextual
  results side by side.

## Architecture

**Engine side (`packages/whatchord/lib/src/temporal/`).** A new pure class,
provisionally `ContextualReranker`, beside the segmenter:

```dart
List<ChordCandidate> rerank(
  List<ChordCandidate> candidates, {
  required ChordContext context,   // recent identities + timing, possibly empty
  required Tonality tonality,
  ObservedVoicing? voicing,
})
```

`ChordContext` is a small value object derived from the segmenter's state:
committed recent events plus the in-flight identity, each with onset/duration.
The re-ranker applies bounded cue rules, initially confined to the near-tie
window (`nearTieWindow = 0.25`), following the exact pattern `VoicingEvidence`
established for register evidence: evidence nudges, it does not overrule clear
cost differences. If tuning shows a cue deserves more force, promotion follows
the existing capped hard-rule pattern (`ranking_policy.dart` cost caps), never
uncapped.

**Lever 0: deeper tonality coupling in the existing rules.** Before any temporal
cue, the cheapest intervention is snapshot-side. Only a handful of tie-breakers
consult tonality today, so less key knowledge reaches the ranking than the
architecture allows, and the inert closed-loop result is bounded by that thin
coupling. Strengthening tonality awareness in existing rules, or adding
tonality-gated ones, stays deterministic, changes no product contract, and is
evaluated with the same corpus and adoption bar as everything else. Temporal
cues are then ablated against the post-lever-0 baseline, so temporal context
only gets credit that key coupling cannot claim.

Candidate Track A cues, each independently toggleable for ablation:

1. **Root continuity.** If the previous identity's root appears among near-tie
   candidate roots, prefer it. Doubles as cheap hysteresis for voicing changes
   over a held harmony.
2. **Fifth-motion prior.** Prefer the candidate whose root continues cadential
   motion from the previous root (down a fifth strongest, then down a second /
   up a second).
3. **Dominant expectation.** After a pre-dominant in the prevailing key (ii, IV,
   secondary dominants), boost the dominant-family reading of an ambiguous
   voicing.
4. **Post-dominant resolution.** After a dominant, prefer the tonic-family
   reading a fifth below over remote reinterpretations.
5. **Guide-tone continuity.** Prefer candidates whose 3rd/7th connect by common
   tone or step from the previous identity's guide tones (the causal fragment of
   voice-leading smoothness; also the cue most relevant to the future Track D
   gate).

Every cue must beat the key-aware baseline in ablation, because cues 3 and 4 in
particular risk being redundant with the tonality tie-breakers plus the key
loop. The inert closed-loop result says the key loop alone almost never flips
identities, so any win these cues show over that baseline is genuinely theirs;
but redundancy must be measured, not assumed.

(Outcome 2026-07-20, log entry 2026-07-20-05: measured against the shipped lever
0 baseline, cues 2 through 4 were inert or harmful and are rejected as naming
cues (root continuity is re-scoped to Track C), and the one confirmed positive,
a tonicization extension of the lever 0 twin rule, is significant but too small
(+0.03 points) to justify building the temporal layer alone; it is banked for
whenever that layer exists for another reason. Track A live re-ranking is
concluded for now: lever 0 captured the addressable clean-pool market
snapshot-side.)

**App side (`lib/features/theory/`, `lib/features/history/`).** One new derived
provider between `chordCandidatesProvider` and the presentation providers: watch
the snapshot candidates, the live context view, the tonality, and a settings
flag; emit the re-ranked list. Presentation and display providers switch to it.
This is strictly downstream data flow, no state writes against the dependency
graph, so the `scheduleMicrotask` defer pattern is not needed. The analyzer's
LRU cache is untouched because re-ranking happens after the cached snapshot
pass; temporal state never enters the cache key. The flag ships
debug/settings-gated and default-off until the corpus and device results justify
default-on.

**`ChordEvent` adequacy.** The existing event model is close to sufficient: it
already preserves the ranked near-tie set with intact cost gaps, the raw input,
register, tonality-at-ranking, onset, and duration, and inter-event gaps are
derivable from onset plus duration. Two additions are likely:

- Fixture generation should record more candidates than the live near-tie
  surfacing, so ceiling measurements are not truncated by what the app happens
  to display. Rather than picking a hard count, record the cost-bounded set the
  ranking pass already keeps (everything within `rankingPruneMargin = 2.0` of
  the cheapest, floored at `take`), with a generous cap only as a fixture size
  guard: the cost window is the engine's own definition of "worth ranking",
  where any fixed count is arbitrary. No separate marking of displayed
  alternatives is needed; costs are recorded intact, so near-tie membership is
  derivable. Whether the shipped re-ranker may ever reach below the near-tie
  window into that deeper set is an open question, answered by the Phase 0 gap
  between the near-tie and prune-margin ceilings.
- The live context view needs the in-flight identity, which is segmenter state,
  not an event; expose it from the segmenter rather than widening `ChordEvent`.

## Measurement

### Phase 0 headroom study (before any product code)

Reuse the WhatKey fixtures, which already carry per-event candidate rankings,
voicings, local keys, and Roman-numeral figures. The committed sets
(`when-in-rome-v1`, `pop-jazz-v2`) are the starting point, but the license-gated
sets rebuild locally into `build/` with the existing extractors and should be
included: ASAP (performed MIDI) and especially Isophonics via ChoCo, whose
annotations are lead-sheet chord symbols already, which sidesteps the
Roman-numeral mapping problem entirely (with the caveat that its voicings are
synthesized from labels, not performed). Extend the extractor to also emit the
expected chord identity (root pc, quality, bass) realized from figure plus local
key, then measure, per piece and pooled with per-piece statistics:

- Baseline snapshot top-1 agreement with the expected identity (exact; root and
  quality; root only).
- Oracle ceilings: how often the expected identity is present but not top-1 (a)
  within the near-tie set, (b) within the full recorded prune-margin depth.
  Bucket (a) is the entire addressable market for Track A as a tie-breaker; the
  gap between (a) and (b) is the market for capped-rule promotion; misses
  outside (b) are Track D or generation territory, tagged by failure category
  (rootless, enharmonic, other).
- A key-oracle ceiling: how often the expected identity would win under full
  knowledge of the annotated local key, with ranking made maximally
  key-sensitive. Diagnostic only (annotated keys never condition an evaluated
  system); its purpose is to separate "headroom exists but the rules barely
  consult tonality" (a lever 0 fix) from "key knowledge would not help", which
  the inert closed-loop probe cannot distinguish.
- The same breakdown restricted to transitions where context could plausibly
  help (event preceded by a dominant, a pre-dominant, a sus chord), versus all
  events, to estimate cue-specific headroom.

The label-mapping problem is real and must be settled here: Roman-numeral
annotations are functional labels, and some have no lead-sheet equivalent
(cadential six-four, augmented sixths) or map to several acceptable symbols. The
contrapunctus benchmark study already built category mappings and failure
taxonomies; reuse them, and define acceptable-answer sets per event rather than
forcing a single expected symbol. The scoring script, as with WhatKey, is the
normative definition of every metric.

**Gate:** each track proceeds only where Phase 0 shows headroom. If near-tie
oracle headroom is as thin as the closed-loop churn result hints it might be,
Track A shrinks or dies cheaply, and the initiative reweights toward B (which
has clear known cases) and the Track D gate decision.

(Revised 2026-07-19: Phase 0 ran as pre-protocol, dev-only scouting; see log
entry 2026-07-19-01. The protocol freeze below now precedes all lever 0 and cue
work, and the headroom numbers are re-established under the frozen protocol as
its first experiment before informing any adoption decision.)

### Phase 1 protocol freeze

Clone the WhatKey discipline before any tuning:

- `PROTOCOL.md` frozen and amended-only; scoring code normative.
- Ground truth defined per corpus, with no naming interpreter treated as an
  oracle. Roman-numeral corpora: the annotation is the analyst's figure plus
  key; the realization step (music21) is a parser that must pass the
  sounding-set cross-check to score, backed by a stratified hand-audit of the
  realization and quality mapping with a recorded error rate, and
  acceptable-answer sets for contestable categories. DCML corpora: the
  annotation standard's own decomposed columns (chord_type, root, bass_note,
  chord_tones) are the expected identity, no interpreter involved. Symbol
  corpora (Isophonics via ChoCo): human chord labels in Harte syntax, scored in
  Harte space against WhatChord's `HarteChordFormatter` output with the semantic
  normalization from the chord-oracle work, music21-free. Disagreement between
  rulers is itself a tracked diagnostic.
- Fixture sets versioned with manifests (engine commit, generator arguments,
  corpus pins, licenses); committed sets immutable; neutral analysis context for
  recorded rankings so annotated keys never leak into candidates. When the
  evaluation needs a key for context-dependent cues, it uses the key the app's
  own detector infers (the closed-loop arrangement the probe already
  implements), never the annotation.
- Dev/test splits by piece and composer, frozen and committed before the first
  experiment, and for every new corpus frozen from metadata alone before its
  content is inspected or fixtures are generated. When-in-Rome, Isophonics, and
  ASAP inherit the WhatKey frozen splits; the DCML distant-listening split was
  frozen 2026-07-19 (`data/splits/dcml-distant-listening-v1.json`,
  metadata-only, with the When-in-Rome overlap and the schema-validation
  sub-corpus excluded). Test splits spent sparingly with dated log entries.
- Adoption bar: paired per-piece Wilcoxon win with CI95 on the dev split, no
  stability regression, latency within budget. Pooled event accuracy alone is
  not acceptable.
- `log/` with the WhatKey entry template (Goal / Setup / What happened /
  Plain-English reading / Decisions / Next), append-only, negatives included.
- Corpus additions this initiative needs beyond WhatKey's: (a) frame-accurate
  replay fixtures, synthesized from the chart sources with demo-style
  arpeggiated onsets and roll jitter, because stability and transition churn are
  frame-level phenomena invisible in committed-event fixtures; (b) a
  hand-authored jazz comping suite (shell and rootless voicings with labeled
  intent) to give Track D's gate and the guide-tone cue real data, since
  When-in-Rome is classical and skews triadic; (c) the DCMLab Distant Listening
  Corpus, investigated 2026-07-19 (log entry 2026-07-19-02): usable and strong,
  with the annotation standard's own decomposed chord identities (chord_type,
  root, bass_note, chord_tones) and pre-extracted note tables, so no naming
  interpreter is involved; CC BY-NC-SA 4.0, so fixtures stay
  build-only/untracked, pinned to the v3.1 tag; split frozen from metadata alone
  before any content inspection (`data/splits/dcml-distant-listening-v1.json`).
  Needs a dedicated extractor.

Metrics, normatively defined in scoring code:

- Accuracy: expected-identity agreement at the three strictness levels, per
  piece.
- Stability: renames per committed event and frame-level flip rate during
  transitions, from replay fixtures.
- Ceilings: the Phase 0 oracle metrics, recomputed per fixture version.
- Invariance: empty-context output identical to snapshot output.
- Performance: re-rank latency and analyze-call count (must be unchanged).

### Phase 2 offline re-ranker and ablations

Implement `ContextualReranker` and the cue set in the package, pure Dart with
unit tests. Build the harness under `tool/chord-context/` (mise tasks
`research:chord-context-*`): replay fixtures through segmenter plus re-ranker,
one cue toggled at a time, then the tuned ensemble. Adopt only cues with paired
significant wins over the key-aware baseline; record negatives in the log. Track
B runs its own parallel evaluation here: line-of-fifths member spelling and
augmented-sixth recognition scored against the corpus's spelled pitches
(When-in-Rome provides real spellings, an unusually good ground truth for this).

### Phase 3 app integration

Wire the provider chain behind the settings flag, chord-debug showing raw vs.
contextual side by side. Device verification: analyze-call count unchanged,
re-rank cost measured (budget: well under a millisecond, expected microseconds
for a <=10 candidate re-rank), no frame jank on note storms. Then a default-on
decision with a CHANGELOG entry, or a decision to keep it opt-in.

### Phase 4 and beyond

Track C hysteresis (if churn metrics from Phase 2 say the contextual layer needs
it), the history-relabeling product, and the Track D ensemble-mode gate each get
their own decision point with corpus evidence in hand, rather than riding along
implicitly.

## Performance plan

- Re-ranking is O(cues x candidates) over at most `take` candidates, pure
  functions, no I/O, no allocation-heavy paths. The normative budget lives in
  `PROTOCOL.md`: `tool/benchmark.sh --check` stays green, a benchmark entry for
  the layer adds at most 5% to the snapshot baseline's cold normalized time
  (judged with the harness's combined-uncertainty rule), and on-device profiling
  in Phase 3 shows no dropped frames on note storms.
- No new `analyze()` calls and no cache-key changes; the snapshot LRU keeps its
  hit behavior exactly.
- One added provider in the rebuild graph per note change; no listeners that
  write upstream.
- The frame-replay harness doubles as a performance harness: worst-case context
  plus candidate shapes replayed at speed.

## Risks

- **Ground-truth mapping ambiguity.** Functional annotations vs. lead-sheet
  conventions can make "expected identity" contestable. Mitigation:
  acceptable-answer sets, category tagging, and the contrapunctus mappings;
  where mapping stays contested, exclude and count, never guess.
- **Redundancy with the key loop.** The most intuitive cues may already be
  covered by tonality tie-breakers. Mitigation: key-aware baseline in every
  ablation; the inert probe result makes attribution clean.
- **Corpus skew.** Classical fixtures may show little headroom while the real
  wins live in jazz comping, which the corpus underrepresents until the new
  suite exists. Mitigation: build the jazz suite in Phase 1 and report per
  corpus, never pooled across genres.
- **Display trust.** Same notes, different name is surprising in a real-time
  display. Mitigation: the causality contract (no mid-hold renames from this
  layer), bounded near-tie bias so only genuinely ambiguous voicings are
  affected, and the explain channel showing which cue fired.
- **Scope creep into Track D.** Rootless support keeps surfacing because it is
  the most vivid example, but it is a generation-contract change. Mitigation:
  the explicit gate, fed by tagged corpus data, and nothing else.

## Immediate next steps

1. Review and revise this document. The augmented-sixth and fifths-window notes
   are written up in `contextual-spelling-notes.md`, and the rootless sketch in
   `rootless-voicings-notes.md`; retire the corresponding scratchpad sections
   once those are confirmed to capture everything.
2. Phase 0: extend the fixture extractor with expected-identity labels and write
   the headroom script; record the results as the initiative's first log
   entries.
3. Freeze `PROTOCOL.md` and splits only after Phase 0 says which tracks are
   live.
