// WhatKey paper. Build: typst compile main.typ (or mise research:whatkey-paper).
// All numbers trace to dated entries in research/whatkey/log/ and the
// committed one-shot artifacts in research/whatkey/results/.
//
// Layout: compact two-column archival draft. A formal submission should be
// ported to the target venue's template; set `anonymous` to true to strip
// identifying material for double-blind review drafts.

#import "@preview/lilaq:0.4.0" as lq

#let anonymous = false

// Shared figure palette (Tol vibrant, colorblind- and print-safe): every
// series color in every figure comes from here, never a package default.
#let fig-blue = rgb("#0077bb")
#let fig-orange = rgb("#ee7733")
#let fig-red = rgb("#cc3311")

#set document(
  title: "Streaming Key Estimation with Abstention from Live Chord-Recognition Output",
  author: if anonymous { "Anonymous" } else { "Aaron Bull Schaefer" },
)
#set page(paper: "us-letter", margin: (x: 1.9cm, y: 2.2cm), columns: 2, numbering: "1")
#set columns(gutter: 0.9cm)
#set text(size: 9.5pt)
#set par(justify: true)
#set heading(numbering: "1.1")
#show heading: set text(size: 10.5pt)
#show table: set text(size: 8pt)
#show table.cell.where(y: 0): strong
#set table(stroke: (x, y) => if y == 0 { (bottom: 0.6pt) } else { none })
#show figure.caption: set text(size: 8.5pt)
#set figure(gap: 0.6em)

#place(top + center, scope: "parent", float: true)[
  #text(size: 14.5pt, weight: "bold")[
    Streaming Key Estimation with Abstention \
    from Live Chord-Recognition Output
  ]

  #v(0.4em)
  #if anonymous [
    Anonymous submission
  ] else [
    Aaron Bull Schaefer
    #h(0.3em)
    #text(size: 8.5pt)[#link("https://orcid.org/0009-0007-9030-7469")[
      (ORCID 0009-0007-9030-7469)
    ]]
  ]

  #v(0.2em)
  #text(size: 9pt)[Draft, July 2026. Project name WhatKey.]
  #v(0.6em)
]

*Abstract.* Most key-detection research estimates a global or local key from
a complete score or recording. We study a stricter interactive setting: a
musician plays a MIDI keyboard, a chord recognizer emits a causal stream of
symbolic chord hypotheses, and the key detector must update after each chord
while abstaining when the evidence is insufficient. We define an evaluation
protocol for streaming key estimation with abstention, including selective
accuracy, coverage, stability, modulation lag, and piece-level paired
statistics, and evaluate a family of causal detectors on four corpus-derived
fixture sets. The final system is a filtered hidden Markov model (HMM) over
profile-correlation emissions, with one constrained symbolic cue that
redistributes evidence within same-tonic major/minor pairs. Three results are
central. First, the emission-memory half-life is not merely a smoothing
parameter: it selects the timescale of key structure being reported, and
tonicization-scale and section-scale annotations prefer opposite settings.
Second, same-tonic mode confusions can be reduced without disturbing tonic
selection when symbolic chord-quality evidence is confined to parallel-key
pairs. Third, adaptive temporal alternatives trade stability for faster key
change detection and do not improve the selected section-scale operating
point. On held-out pop-song fixtures, the causal abstaining detector reaches
statistical parity with standard offline music21 key finders that read the
whole song before answering, while providing posterior probabilities,
abstention, and stability measurements.

= Introduction

An interactive music application identifies the chords a musician plays on a
MIDI keyboard in real time. A natural next feature is a key indicator: the
tonal center the player is in right now, inferred from what they have played.
This is key finding, one of the oldest problems in music information
retrieval, but the interactive setting differs from the literature's in three
compounding ways.

First, the detector is *causal and streaming*. It only ever sees the past,
and it must update after each chord, from someone noodling with finger rolls,
pedal blur, and wrong notes. There is no second pass and no lookahead; the
Viterbi decodings that dominate published HMM key-finding are unavailable by
construction.

Second, the observations are *uncertain and symbolic at the chord level*. The
input is not ground-truth notes or audio chroma but the output of a chord
recognizer: ranked candidate identities with explanation costs, together with
the voicing, timing, and hold duration of each committed chord. This setting is
less studied than audio or score-based key detection, and it carries unusual
assets (the detector knows each chord's root, quality, and bass) alongside
unusual noise.

Third, *abstention is a first-class outcome*. A modal vamp has no single
right answer, and asserting one confidently is worse than staying quiet. We
therefore measure coverage and accuracy-on-claimed as an inseparable pair,
along with stability, modulation lag, and time-to-first-claim, rather than
accuracy alone.

The contributions are:

+ *A protocol for streaming key estimation with abstention*: metrics in the
  selective-prediction frame, frozen before tuning, with piece-level paired
  statistics for every adoption decision and one-shot held-out evaluation.
+ *An explicit fixture-based data and reproducibility design*: chord streams
  are generated under a fixed neutral context, labels are stripped before
  detector calls, split files and result artifacts are versioned, and
  license-gated corpora are rebuilt locally rather than redistributed.
+ *A causal HMM specification for chord-recognition output*: filtered
  posteriors, profile-correlation emissions, a circle-of-fifths transition
  kernel, posterior-margin abstention, and a mass-preserving same-tonic mode
  cue.
+ *The timescale finding*: the emission-memory dial selects which granularity
  of key structure a causal detector reports. Dose-response curves on two
  annotation cultures run in opposite directions with no interior optimum
  (@fig-dose), the crossover is significant on held-out data in both
  directions, and it reproduces within one corpus on identical performed input
  as a function of annotated segment length (@fig-segment). Accuracy
  comparisons between key detectors are therefore label-timescale dependent.
+ *Measured negative results for added temporal and symbolic complexity*:
  recognizer-confidence weighting, progression rules under the HMM,
  relative-pair tilts, explicit-duration modeling, and Bayesian online
  changepoint detection each have documented outcomes.
+ *A held-out comparison*: the final causal detector reaches at least parity
  with offline whole-piece baselines, with point estimates ahead on every
  comparison, while abstaining and reporting streaming stability metrics.

= Related work

Distributional key finding begins with the Krumhansl-Schmuckler probe-tone
profiles @krumhansl1990 and their revisions @temperley1999, with
corpus-trained profiles improving minor-mode behavior @albrecht2013. These
methods estimate key from pitch-class distributions and remain important
baselines because they are simple, reproducible, and musically interpretable.
The selected detector in this paper keeps that interpretability: its emissions
are profile correlations rather than learned sequence embeddings.

Temporal structure enters key and harmony estimation through Bayesian and
hidden Markov treatments @temperley2007 @raphael2004. The closest published
analogue of our final detector is justkeydding @napoles2019, an HMM over
profile emissions for global and local key. Neural symbolic-harmony systems
also estimate local key as one head of a larger harmonic-analysis task, for
example models using Roman numeral corpora and multitask architectures
@micchi2020 @napoles2021. Those systems demonstrate the value of local-key
estimation, but their usual setting is offline score analysis. Our aim is
narrower and more constrained: causal filtering over chord-recognition events
with abstention and stability metrics.

Real-time tonal tracking has also been studied outside the profile/HMM family.
Chew's Spiral Array and Center of Effect Generator frame key finding as
movement in a geometric tonal space and explicitly address streaming tonal
center estimation @chew2000. Our setting differs in the observation layer:
rather than raw pitch collections, the detector receives symbolic chord
identities and candidate rankings produced by an upstream recognizer. That
makes chord quality a usable signal, but it also means recognizer errors and
candidate uncertainty are part of the input distribution.

Bayesian online changepoint detection @adams2007 maintains a run-length
posterior and is the natural adaptive-memory alternative to a fixed decay.
Recent extensions model within-regime dynamics to suppress false alarms
@tsaknaki2024. We build the constant-hazard version for the 24-key space and
measure where its adaptivity helps and where it conflicts with the selected
section-scale operating point.

Evaluation practice follows the MIREX audio key task's weighted scoring
@mirex for near misses, applied to our own corpora (scores are not comparable
to MIREX leaderboards, which are audio-based on different data). Ground truth
comes from sources spanning two annotation cultures: When in Rome's analyst
local keys and RomanText annotations @wheninrome @tymo2019, the ASAP corpus of
aligned performed piano MIDI @asap2020, and Isophonics song-level keys via the
ChoCo chord corpus @choco2023 @isophonics2009.

= Task and evaluation protocol

*Task.* The input is a causal stream of chord events from the application's
capture path: each event carries ranked chord candidates with explanation
costs, the sounding voicing, the analysis-time tonality context, a
timestamp, and a hold duration. After each event the detector outputs either
a ranked list of (key, confidence) hypotheses or an explicit abstention. It
never sees the future and is never re-run on edited history. The key space
is the 24 major and minor keys over pitch classes; enharmonic spelling is a
presentation concern.

*Metrics.* The top-ranked claim is scored. Accuracy-like metrics are reported
in the selective-prediction frame: coverage (fraction of events with a claim)
and accuracy on claimed events form an inseparable pair, and abstentions are
never errors. Exact accuracy is complemented by the MIREX-weighted score
(fifth 0.5, relative 0.3, parallel 0.2) @mirex.
Temporal behavior is measured by modulation matching and lag (an annotated
key change is matched when the detector claims the new key before the next
change; unmatched changes are censored counts, never averaged into lag),
spurious switches per piece (a switch is spurious only when the annotation
did not change and the new claim is not the annotated key), and
time-to-first-claim. Ambiguity-labeled events (hand-authored fixtures only)
accept abstention or any acceptable key. Selective-prediction behavior is
reported as the coverage-accuracy curve swept over the abstention threshold,
with the selected operating point marked (@fig-sweep).
For probabilistic detectors, we also report top-label posterior reliability:
events are binned by the posterior probability of the leading key and compared
with exact correctness, alongside expected calibration error (ECE), negative
log likelihood, and Brier score. This diagnostic is separate from abstention
behavior: a detector can abstain informatively while still being overconfident
in its posterior probabilities.

*Statistics.* Every adoption decision uses piece-level paired comparisons:
Wilcoxon signed-rank tests with seeded-bootstrap 95% confidence intervals on
the per-piece mean delta. Pooled event accuracy alone is never decisive, a
few long pieces dominate pools.

*Protocol discipline.* The protocol was frozen before detector tuning, with
changes recorded as dated amendments. Development/test splits were frozen
per corpus before the first experiment on it (by piece, and by composer
where the corpus allows); all tuning, ablation, and model selection ran on
development splits; the test splits were evaluated exactly once, with the
result set declared in advance (Section 8). The evaluation harness
structurally strips labels before events reach a detector.

= Data and reproducibility

Evaluation uses *fixtures*: versioned event streams containing the chord
recognizer's candidate rankings, the observed voicings, timing metadata, and a
parallel label stream read only by the scorer. Fixtures are generated under a
fixed neutral analysis context so tonality-gated ranking rules cannot leak
ground truth into the observations. Results are comparable only within a
fixture version, because fixture contents embed a specific version of the
chord-recognition engine.

Four fixture sets span two annotation cultures and three input conditions
(@tab-corpora). The first three have frozen development/test splits. The
ASAP-WiR overlap is evaluation-only: every configuration run against it was
declared in advance because the set exists specifically to test whether the
timescale effect survives on identical performed input.

#place(top, scope: "parent", float: true)[
  #figure(
    table(
      columns: (auto, auto, auto, auto, auto),
      align: (left, left, left, right, right),
      table.header([corpus], [input], [labels], [pieces], [events]),
      [When in Rome @wheninrome], [quantized scores],
        [analyst local keys (tonicization-scale)], [77], [5,207],
      [ASAP @asap2020], [performed piano MIDI],
        [key signatures (section-scale, mode-unknown)], [60], [19,546],
      [Isophonics @isophonics2009 @choco2023], [synthesized voicings],
        [song keys (section-scale, mode-resolved)], [224], [19,062],
      [ASAP-WiR overlap], [performed piano MIDI],
        [analyst local keys (tonicization-scale)], [36], [10,395],
    ),
    caption: [Evaluation corpora. Development/test splits are frozen for the
      first three; the overlap corpus is evaluation-only (every configuration
      run on it was committed in advance).],
  ) <tab-corpora>
]

The overlap corpus transfers When in Rome analyst keys onto ASAP
performances of the same Beethoven sonata movements through the
performance-to-score downbeat alignment, giving real tonic-and-mode ground
truth on performed input. A small hand-authored pop/jazz suite (12-bar
blues, modal vamps, deliberately ambiguous loops) serves as a per-fixture
behavioral regression battery outside all pooled statistics. Performed
corpora are replayed through the application's actual capture code
(pedal-aware sounding sets, debounce, minimum-duration commit), so
detectors see the events they would see live.

The repository contains the open fixtures, split files, evaluation harness,
paired-comparison script, dated experiment logs, and the one-shot held-out
result artifacts. License-gated corpora are not committed: their extractors
refuse to write inside the research directory and must be rerun locally from
pinned upstream checkouts. This means the paper's reported numbers are
auditable from committed reports and commands, while redistribution remains
bounded by each source corpus's terms.

= Model family and selected detector

The detector family was deliberately interpretable. The profile-correlation
floor maintains a duration-weighted, exponentially decaying pitch-class
histogram and ranks all 24 rotations of a major/minor profile pair
@albrecht2013 by Pearson correlation. Two symbolic additions were also built:
a weighted-evidence layer scoring key-relative chord functions (diatonic
membership, dominant and leading-tone function), and a progression layer
voting on cadential transition patterns. These layers form a three-way hybrid
(correlation base plus small functional and progression blend terms) that beat
the floor on early tonicization-scale development runs (+0.096 exact per
piece, p = 0.003), but later ablations show that the selected section-scale
configuration should remove them.

The selected detector is a causal HMM over the 24 major and minor keys. It
keeps a filtered posterior and updates it by the forward algorithm only; no
Viterbi decoding or future context is used. At each event, the update is:

#block(
  width: 100%,
  inset: 4pt,
  stroke: (paint: luma(70%), thickness: 0.4pt),
  radius: 2pt,
)[
  ```text
  for each pitch class p:
    histogram[p] =
      sum over prior events i of:
        duration_i
        * 2^(-age_i / half_life)
        * indicator(p in voicing_i)

  for each candidate key:
    profile_score[key] =
      correlation(histogram, key_profile[key])

  emission = softmax(profile_score / temperature)
  prior =
    transpose(transition) * previous_posterior
  posterior = normalize(emission * prior)
  ```
]

Multiplication in the last pseudocode line is elementwise; the transition
matrix supplies persistence over hidden keys, and the normalized posterior is
the filtered belief after the current event. In words, the profile scores are
converted into an event-level likelihood over keys, the previous belief is
advanced through the transition model to form a prior, and the two are combined
and renormalized.

In the selected configuration, `key_profile` is the Albrecht-Shanahan
major/minor profile set. Each event's contribution to the histogram is
multiplied by its duration, and `half_life = 30 s` means that contribution
halves after 30 seconds. The softmax temperature is 0.25, sharpening the
profile-correlation scores into a more selective likelihood. The transition
matrix assigns 0.9 probability to remaining in the same key; the remaining mass
is distributed over other keys with decay by circle-of-fifths signature
distance. At each event, the detector reports the posterior's top key and its
posterior probability only when the margin between the top two posterior
probabilities is at least 0.3; otherwise it abstains.

Two modeling constraints matter for interpreting the results. First, the HMM's
state persistence and the emission scorer's context window are distinct: the
decayed histogram defines the current observation, while the HMM supplies
temporal persistence over hidden keys. Reintroducing history both as an
emission blend and as state persistence double-counts evidence. Second, the
emission half-life is not merely a noise-smoothing parameter; it determines the
musical timescale represented by each observation. The next section measures
that timescale effect directly.

#figure(
  lq.diagram(
    width: 7.4cm,
    height: 4.6cm,
    xscale: "log",
    xaxis: (
      ticks: ((1, [1]), (2, [2]), (4, [4]), (8, [8]), (15, [15]), (30, [30]), (60, [60])),
      subticks: none,
    ),
    yaxis: (subticks: none),
    xlabel: [emission half-life (s)],
    ylabel: [exact accuracy on claimed],
    legend: (position: right + horizon, dy: -1.5em),
    lq.plot(
      (1, 2, 4, 8, 15, 30, 60),
      (0.724, 0.736, 0.753, 0.760, 0.758, 0.759, 0.759),
      mark: "s",
      color: fig-blue,
      label: [Isophonics (section)],
    ),
    lq.plot(
      (1, 2, 4, 8, 15, 30, 60),
      (0.590, 0.550, 0.493, 0.476, 0.459, 0.486, 0.483),
      mark: "o",
      color: fig-orange,
      label: [WiR (tonicization), +func.],
    ),
    lq.plot(
      (1, 2, 4, 8, 15, 30, 60),
      (0.538, 0.497, 0.434, 0.382, 0.372, 0.404, 0.401),
      mark: "^",
      color: fig-red,
      label: [WiR (tonicization), pure],
    ),
  ),
  caption: [Emission-memory dose-response on the two development annotation
    scales.
    The curves run in opposite directions with no interior optimum: the
    dial selects the reported timescale. Coverage rises with memory on both
    scales (0.77 to 0.93 on Isophonics); the section-scale plateau spans
    8-60 s.],
) <fig-dose>

= The timescale finding

Key annotations come in two cultures. Analyst local keys (When in Rome) mark
every tonicization, about seven key regions per piece at a few events each.
Song keys and key signatures (Isophonics, ASAP) name the section-level
center and absorb excursions. We call these the *tonicization-scale* and
*section-scale* annotation scales.

Sweeping the emission-memory half-life across 1 to 60 seconds on both
development annotation scales gives the dose-response curves of @fig-dose. On the
tonicization-scale labels, accuracy falls essentially monotonically with memory and
modulation matching halves; on the section-scale labels, accuracy climbs to a broad
plateau from 8 s outward while coverage and stability keep improving
(spurious p90 falls from 7 to 1). The dial is a timescale selector, not a
noise-accuracy tradeoff with a sweet spot.

#figure(
  lq.diagram(
    width: 7.4cm,
    height: 4.4cm,
    xaxis: (ticks: (0, 12, 20, 32), subticks: none),
    yaxis: (subticks: none),
    xlabel: [minimum annotated segment length (measures)],
    ylabel: [exact accuracy on claimed (%)],
    legend: (position: bottom + right),
    lq.plot(
      (0, 12, 20, 32),
      (50, 60, 63, 65),
      mark: "s",
      color: fig-blue,
      label: [30 s memory (selected)],
    ),
    lq.plot(
      (0, 12, 20, 32),
      (60, 62, 62, 62),
      mark: "o",
      color: fig-orange,
      label: [1 s memory (reflex)],
    ),
  ),
  caption: [The crossover within a single corpus on identical performed
    input (ASAP-WiR overlap): filtering to longer analyst key segments, the
    long-memory configuration climbs and overtakes the short-memory one at
    20-measure segments, which stays flat. The same recordings, sliced by
    label granularity, reorder the two configurations.],
) <fig-segment>

Three controls close the alternative explanations. The crossover survives
noise: on the evaluation-only overlap corpus, identical performed
recordings scored against analyst keys prefer short memory (0.59 vs 0.47
exact), matching the clean-score result. It reproduces *within* one corpus
as a function of segment length (@fig-segment). And it holds on held-out
data with significance in both directions (Section 8).

The application conclusion is a choice, not a claim that one timescale is
universally better: a glanceable key indicator should report the section, so
the selected configuration uses 30 s memory and deliberately absorbs brief
tonicizations. The research conclusion is that cross-paper accuracy
comparisons are under-specified without the label timescale: the same detector
moves by tens of points when the annotation scale changes.

*Ablations.* Two full 16-cell factorials (functional blend, progression
blend, duration weighting, recognizer-confidence weighting) ran on each
annotation scale. The functional blend flips sign with the annotation scale:
removing it is a significant paired win at section scale, while at reflex
scale it is load-bearing (+0.061 exact, CI95 [+0.019, +0.108], p = 0.010).
This is direct evidence that the functional rules primarily detect brief
excursions. The progression blend's earlier value was architecture-specific
and washes out under the HMM. Duration weighting helps on both scales (+0.02
to +0.05). Recognizer-confidence weighting is inert in five out of five paired
tests, a useful negative result because exploiting recognizer confidence was a
natural hypothesis for this setting. The selected emissions are therefore pure
profile correlation, and a long-standing behavioral failure (a 12-bar blues
misread as its subdominant) vanished with the deleted rules rather than through
any added mechanism.

#figure(
  lq.diagram(
    width: 7.4cm,
    height: 4.4cm,
    xaxis: (subticks: none),
    yaxis: (subticks: none),
    xlabel: [coverage (fraction of events claimed)],
    ylabel: [exact accuracy on claimed],
    lq.plot(
      (0.970, 0.962, 0.954, 0.945, 0.937, 0.930, 0.922, 0.912, 0.903, 0.882, 0.856),
      (0.768, 0.769, 0.770, 0.772, 0.773, 0.774, 0.775, 0.777, 0.779, 0.783, 0.785),
      mark: "o",
      color: fig-blue,
    ),
    lq.scatter(
      (0.922,),
      (0.775,),
      mark: "d",
      size: 7pt,
      color: fig-red,
    ),
  ),
  caption: [Selective-prediction behavior: the coverage-accuracy curve of the selected
    configuration on the Isophonics development split, swept over the
    posterior-margin floor (0 to 0.6). The marked point is the selected
    operating point (floor 0.3). The curve rises monotonically as the
    detector grows choosier: abstentions are informative, not random.],
) <fig-sweep>

= Mode disambiguation

On mode-resolved corpora the residual errors sort into MIREX classes:
fifth-neighbor confusions, relative-pair confusions (shared signature), and
parallel-pair confusions (shared tonic). Mode errors, the most user-visible
class since an indicator displays major or minor, were about 10% of claims
on both annotation scales once the timescale trade was filtered out.

The useful constraint is mass preservation within a musically related pair:
when evidence is redistributed only between two hypotheses sharing an
invariant, the cue can help decide between those hypotheses without adding
evidence to unrelated keys.

*Parallel pairs (selected).* Parallel keys share the tonic pitch class, and
practical minor borrows the raised sixth and seventh, so the discriminating
evidence collapses to roughly one pitch class and is easily outvoted in a
12-dimensional correlation. But our observations are symbolic: when the
played chord is rooted on a candidate tonic with a home quality, its major
or minor quality is the most direct mode cue available. Applied as a
log-odds tilt within the parallel pair after the emission softmax, and then
rescaled so the pair's emission sum is unchanged, the cue cannot move tonic
evidence at all. This prevents the failure mode observed for less constrained
tonic-bonus and functional-rule variants, which could fight modulation
tracking. Strength 2 was selected after a 0.25-to-4 sweep with a 2-to-4
plateau: paired exact wins on both annotation scales (Isophonics +0.016,
p = 0.030; When in Rome +0.030, p = 0.029), parallel confusion roughly halved
everywhere measured (4% to 2% of claims on Isophonics), and no stability cost
on the section-scale development set.

*Relative pairs (measured negative).* The same pattern generalizes with the
key signature as the conserved quantity. But the evidence is structurally
weaker: the rival's tonic chord is ordinary diatonic harmony (the vi chord),
not rare mode mixture, so isolated chord quality fires constantly for the
wrong twin. Two sharpened cues were built and swept: a bass-gated tilt
(fires only when the chord's root is also its bass) and a cadential-bigram
tilt (a dominant-quality chord resolving down a fifth onto a home-quality
chord). The cadence cue is inert, echoing the progression ablation. The
bass cue works mechanically (relative confusion 6% to 4% of claims) but
misses paired significance on the primary scale (+0.007, p = 0.055), trends
negative on the other (-0.009, p = 0.056), and doubles spurious p90; unlike
the parallel tilt's broad plateau it turns harmful at strength 2, the
signature of a weak signal. Not adopted; retained in code as a measured
negative.

*Fifth pairs (not adopted).* Fifth neighbors conserve neither
tonic nor signature, and every key has two of them, so there is no pair to
redistribute within; discriminating a key from its dominant *is* the
modulation problem, and any chord-quality nudge between fifth neighbors is
the already-refuted tonic bonus reborn. Empirically the residual fifth
errors also lack an exploitable shape, splitting nearly evenly between the
dominant and subdominant sides (57/43 and 56/44 on the two mode-resolved
corpora).

The pattern explains an adoption, a failure, and a non-adoption: the tilt's
value tracks the strength and exclusivity of the invariant it preserves
(tonic: strong; signature: weak; none: unavailable).

= Adaptive temporal models

*Explicit-duration modeling (HSMM).* The HMM's
self-transition implies geometric key-dwell times; an HSMM's contribution is
a richer dwell family. Before building one we measured whether the system
responds to the dwell parameter it would refine: sweeping self-transition
from 0.7 to 0.98 (implied mean dwell roughly 3 to 50 events) moves every
metric along the coverage-accuracy curve rather than off it (Isophonics
exact within 0.008, spurious p90 pinned at 1). This probe does not prove that
explicit-duration modeling is never useful for key estimation, but it shows
little headroom for the selected operating point.

*Bayesian online changepoint detection, built and measured.* The probe
addresses the changepoint prior (constant-hazard BOCPD implies the same
geometric dwell) but not BOCPD's distinct contribution, the run-length-adaptive
evidence window: pooling evidence back to the inferred section start instead
of through a fixed 30 s decay. We built the constant-hazard detector for the
24-key space @adams2007 with emission conventions identical to the selected
HMM (including the mode tilt), so differences isolate the window
(@tab-bocpd).

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, center, center, center, center),
    table.header([config (Isophonics dev)], [cov], [exact], [modulations],
      [spur med/p90]),
    [HMM, selected], [0.92], [0.775], [94/192], [0/1],
    [BOCPD, hazard 1/200], [0.88], [0.715], [161/192], [5/14],
    [BOCPD, temperature 0.5], [0.89], [0.765], [135/192], [2/7],
    [BOCPD, temperature 1.0], [0.90], [0.769], [115/192], [0/4],
  ),
  caption: [BOCPD versus the selected HMM on the section-scale development
    set. The adaptive window improves modulation detection but no tuning
    recovers the selected stability point.],
) <tab-bocpd>

The adaptive window delivers its promise: modulation matching jumps by 70%,
because evidence resets at inferred section starts. But the same reactivity
breaks section-scale stability, and no tuning recovers the selected
operating point: softening the per-event evidence walks BOCPD back along the
frontier without reaching the HMM (best cell: exact wash, p = 0.51, spurious
p90 still 4 versus 1). One finding worth keeping: at matched reactivity
BOCPD dominates the HMM's fast settings (0.765 exact at 135 modulations
versus 0.736 at 141 for the HMM at a 2 s half-life), so adaptive windowing
has value in the reactive regime; it was not selected for the section-scale
regime studied here.
The false alarms are within-section harmonic movement violating the
independent-given-key assumption, the failure mode that autoregressive BOCPD
extensions @tsaknaki2024 target for continuous series; those Gaussian
remedies have no analog for categorical chord emissions, and our domain's
version of within-regime dependence modeling (the progression layer) is
measured inert.

= Held-out evaluation

The test splits were evaluated exactly once, with the result set declared
before any run: the selected configuration on all three splits, the
reflex reference on the two mode-resolved splits, the music21 baselines on
Isophonics with paired and matched-coverage comparisons, and a descriptive
mode-confusion breakdown. The complete artifacts are committed with the
project.

#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto),
    align: (left, right, center, center, center, center),
    table.header([held-out split], [pieces], [cov], [exact], [modulations],
      [spur med/p90]),
    [Isophonics], [41], [0.88], [0.732], [10/22], [0/3],
    [When in Rome], [18], [0.81], [0.587], [39/115], [0/1],
    [ASAP (acceptable-keys)], [10], [0.83], [0.683], [-], [0/0],
  ),
  caption: [The selected configuration on the three held-out splits.],
) <tab-test>

Generalization is clean (@tab-test): Isophonics dips modestly from
development (0.775 to 0.732), When in Rome comes in far above it (0.434 to
0.587, easier held-out pieces), and stability holds everywhere; the
differences run in both directions, not the uniform degradation a
tuned-to-development configuration would show.

*The crossover holds with significance in both directions.* On the
tonicization-scale split the reflex configuration beats the selected one (0.649 vs
0.587 exact, paired +0.062, CI95 [+0.004, +0.121], p = 0.047); on the
section-scale split the selected configuration wins by a wide margin (0.732 vs
0.556, paired +0.175, CI95 [+0.040, +0.315], p = 0.039), with the reflex
configuration paying spurious 5/11 versus 0/3.

*External comparison.* @tab-baselines compares against music21's offline
whole-piece analyzers on the held-out songs.

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, center, center, center),
    table.header([system], [coverage], [exact], [MIREX]),
    [this work (causal, abstaining)], [0.88], [0.732], [0.782],
    [Temperley-Kostka-Payne], [1.00], [0.637], [0.740],
    [Krumhansl-Schmuckler], [1.00], [0.624], [0.726],
    [Aarden-Essen], [1.00], [0.558], [0.690],
  ),
  caption: [Held-out Isophonics test split: the causal, abstaining detector
    against offline whole-piece baselines.],
) <tab-baselines>

The causal detector's point estimate leads every offline analyzer,
including at matched coverage (Krumhansl-Schmuckler restricted to our
claimed events: 0.63). The paired test is a wash (+0.108, CI95 [-0.008,
+0.228], p = 0.25), so the defensible claim is *at least parity under a
more constrained setting*: the baselines read each entire song before
answering; this detector never sees the future, abstains on the ambiguous
12%, and reports posterior probabilities and streaming stability
metrics offline systems do not have.

Mode confusion on held-out songs (descriptive): exact 72%, fifth 7%,
relative 5%, parallel 2%, other 14%. The parallel row matches the mode
tilt's development effect exactly.

= Limitations

The label timescale is a construct of the annotation culture, and our
central finding is precisely that results are relative to it; we mitigate
by reporting both annotation scales, but neither scale is "the truth."
Residual error contains genuine ambiguity (relative twins share every pitch
class; analysts disagree on mode-mixture passages and on "on the dominant"
versus "in the dominant"), so ceilings are below 1.0 and unknown. The
recognizer sits inside the loop: fixtures embed its rankings, and detector
results are only comparable within a fixture version. Corpus licensing
constrains redistribution (two corpora are noncommercial- or research-gated;
we commit derived facts, splits, and evaluation artifacts, not the gated
fixtures). Test splits are small (10 to 41 pieces), which the paired
statistics respect but cannot cure. And the strongest published neural
local-key systems are offline and score-hungry; we compare only against
baselines that can be run reproducibly on our fixtures.

The posterior probabilities should not yet be read as empirically calibrated
confidence. A development-set reliability diagnostic on the selected Isophonics
configuration shows overconfidence: on claimed exact-labeled events, mean top
posterior is 0.929 while exact accuracy is 0.772 (ECE 0.157). This does not
affect ranking, abstention, or the paired accuracy claims, but a user-facing
confidence display should receive a separate calibration pass.

= Conclusion

This paper defines and evaluates streaming key estimation with abstention from
live chord-recognition output. Under a frozen protocol with paired statistics
and a one-shot held-out evaluation, a causal HMM over profile-correlation
emissions, augmented by one mass-preserving same-tonic mode cue, reports
section-level keys on live-style chord streams at statistical parity with
offline whole-piece baselines. The route to that detector was largely
measurement-guided simplification: functional and progression rules were useful
for tonicization-scale tracking but harmful or unnecessary for the selected
section-scale setting; recognizer-confidence weighting was inert; and adaptive
temporal models traded stability for reactivity. The central methodological
lesson is that key-detection accuracy is label-timescale dependent. A detector
can appear better or worse depending on whether the reference labels ask for
brief tonicizations or section-level key, so the annotation scale is part of
the task definition rather than a detail of the dataset.

#if not anonymous [
  #v(0.6em)
  #line(length: 100%, stroke: 0.5pt)
  #text(size: 8pt)[
    Reproducibility: the protocol, dated experiment log, corpus pins, split
    definitions, harness, and the committed one-shot artifacts live in the
    WhatChord repository under
    #link("https://github.com/EarthmanMuons/whatchord/tree/main/research/whatkey")[
      github.com/EarthmanMuons/whatchord/tree/main/research/whatkey
    ].
    Every number in this paper traces to a dated log entry and a report that
    embeds its own generating command.
  ]
]

#bibliography("refs.yml", style: "ieee")
