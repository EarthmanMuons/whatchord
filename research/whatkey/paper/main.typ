// WhatKey paper. Build: typst compile main.typ (or mise research:whatkey-paper).
// All numbers trace to dated entries in research/whatkey/log/ and the
// committed one-shot artifacts in research/whatkey/results/.
//
// Layout: two-column conference draft sized against the ISMIR budget
// (6 pages + references). Submission requires porting to the target
// venue's official LaTeX template; set `anonymous` to true to strip
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

*Abstract.* Key-finding has a thirty-year literature, but nearly all of it
is offline, score-based, and whole-piece. We study a different setting: a
musician plays a MIDI keyboard, a chord recognizer emits a causal stream of
identified chords, and a detector must report the current key after every
chord, with calibrated confidence, and with abstention as a first-class
outcome. We build a family of causal detectors culminating in a filtered
hidden Markov model over profile-correlation emissions and evaluate it
under a frozen protocol on four corpora with held-out test splits. Three
findings. First, the emission-memory dial does not trade accuracy against
noise; it selects which timescale of key structure the detector reports,
and the two annotation cultures (tonicization-scale analyst keys,
section-scale song keys) prefer opposite settings, a crossover significant
on held-out data in both directions and reproduced within a single corpus
on identical performed input. Second, mode errors admit a structural
remedy: a zero-sum evidence tilt inside a parallel key pair cannot disturb
tonic selection, and it halves parallel-mode confusion on every corpus
measured; the analogous relative-pair tilt fails adoption, and a
fifths-pair tilt is impossible, in both cases for reasons the same
conserved-quantity principle predicts. Third, adaptive-memory alternatives
add nothing here: an explicit-duration model is dispositioned by a
dwell-sensitivity probe, and a Bayesian online changepoint detector, built
and measured, improves only the reactive regime the product setting
deliberately rejects. On held-out pop songs the causal, abstaining detector
matches, and on point estimates exceeds, standard offline key-finders that
read the entire song in advance.

= Introduction

An interactive music application identifies the chords a musician plays on a
MIDI keyboard in real time. A natural next feature is a key indicator: the
tonal center the player is in right now, inferred from what they have played.
This is key finding, one of the oldest problems in music informatics, but the
interactive setting differs from the literature's in three compounding ways.

First, the detector is *causal and streaming*. It only ever sees the past,
and it must update after each chord, from someone noodling with finger rolls,
pedal blur, and wrong notes. There is no second pass and no lookahead; the
Viterbi decodings that dominate published HMM key-finding are unavailable by
construction.

Second, the observations are *uncertain and symbolic at the chord level*. The
input is not ground-truth notes or audio chroma but the output of a chord
recognizer: ranked candidate identities with explanation costs, together with
the voicing, timing, and hold duration of each committed chord. This is a
setting almost absent from the literature, and it carries unusual assets (the
detector knows each chord's root, quality, and bass) alongside unusual noise.

Third, *abstention is a first-class outcome*. A modal vamp has no single
right answer, and asserting one confidently is worse than staying quiet. We
therefore measure coverage and accuracy-on-claimed as an inseparable pair,
along with stability, modulation lag, and time-to-first-claim, rather than
accuracy alone.

The contributions are:

+ *A protocol for streaming key estimation with abstention* (Section 3):
  metrics in the selective-prediction frame, frozen before tuning, with
  piece-level paired statistics for every adoption decision and one-shot
  held-out evaluation.
+ *The timescale finding* (Section 5): the emission-memory dial selects
  which granularity of key structure a causal detector reports. Dose-response
  curves on two annotation cultures run in opposite directions with no
  interior optimum (@fig-dose), the crossover is significant on held-out data
  in both directions, and it reproduces within one corpus on identical
  performed input as a function of annotated segment length (@fig-segment).
  Accuracy comparisons between key detectors are therefore ruler-relative:
  the label timescale is part of the task definition, not a nuisance
  variable.
+ *A conserved-quantity principle for mode disambiguation* (Section 6):
  evidence tilts confined to a key pair that shares a musical invariant
  cannot leak into the inference the invariant protects. The parallel-pair
  tilt (shared tonic) ships and halves the most user-visible error class; the
  relative-pair tilt (shared signature) is measurably too weak; the
  fifths-pair tilt conserves nothing and reduces to an already-refuted
  mechanism.
+ *Measured negatives for adaptive temporal models* (Section 7): a
  dwell-sensitivity probe showing explicit-duration modeling has nothing to
  act on, and a full Bayesian online changepoint detector whose adaptive
  window wins only the reactive regime, quantifying exactly what adaptivity
  buys and where.
+ *A held-out certification* (Section 8): the final causal detector reaches
  at least parity with offline whole-piece baselines, with the point estimate
  ahead on every comparison, while abstaining honestly and carrying
  calibrated confidence.

= Related work

Distributional key finding begins with the Krumhansl-Schmuckler probe-tone
profiles @krumhansl1990 and their revisions @temperley1999, with
corpus-trained profiles improving minor-mode behavior @albrecht2013. Temporal
structure enters through Bayesian and hidden Markov treatments
@temperley2007 @raphael2004, and the closest published analogue of our final
detector is justkeydding @napoles2019, an HMM over profile emissions for
global and local key. All of these are offline: they read a complete piece
and typically decode with Viterbi. Our detector is the same model family
operated under a strictly harder contract, filtered (forward-algorithm)
posteriors only, abstention, and streaming stability metrics.

Bayesian online changepoint detection @adams2007 maintains a run-length
posterior and is the natural adaptive-memory alternative to a fixed decay;
recent extensions model within-regime dynamics to suppress false alarms
@tsaknaki2024. Section 7 builds the constant-hazard version for the 24-key
space and measures precisely where its adaptivity helps.

Evaluation practice follows the MIREX audio key task's weighted scoring
@mirex for near misses, applied to our own corpora (scores are not
comparable to MIREX leaderboards, which are audio-based on different data).
Ground truth comes from four sources spanning two annotation cultures:
When in Rome's analyst local keys @wheninrome, the ASAP corpus of aligned
performed piano MIDI @asap2020, and Isophonics song-level keys via the ChoCo
chord corpus @choco2023 @isophonics2009.

= Task, protocol, and data

*Task.* The input is a causal stream of chord events from the application's
capture path: each event carries ranked chord candidates with explanation
costs, the sounding voicing, the analysis-time tonality context, a
timestamp, and a hold duration. After each event the detector outputs either
a ranked list of (key, confidence) hypotheses or an explicit abstention. It
never sees the future and is never re-run on edited history. The key space
is the 24 major and minor keys over pitch classes; enharmonic spelling is a
presentation concern.

*Metrics.* The top-ranked claim is scored. Accuracy-like metrics are
reported in the selective-prediction frame: coverage (fraction of events
with a claim) and accuracy on claimed events form an inseparable pair, and
abstentions are never errors. Exact accuracy is complemented by the
MIREX-weighted score (fifth 0.5, relative 0.3, parallel 0.2) @mirex.
Temporal behavior is measured by modulation matching and lag (an annotated
key change is matched when the detector claims the new key before the next
change; unmatched changes are censored counts, never averaged into lag),
spurious switches per piece (a switch is spurious only when the annotation
did not change and the new claim is not the annotated key), and
time-to-first-claim. Ambiguity-labeled events (hand-authored fixtures only)
accept abstention or any acceptable key. Abstain calibration is reported as
the coverage-accuracy curve swept over the confidence threshold, with the
shipped operating point marked (@fig-sweep).

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

*Corpora.* Fixtures are versioned datasets that embed the chord engine's
candidate rankings, generated under a fixed neutral analysis context so
tonality-gated ranking rules cannot leak ground truth into observations.
Four corpora span two annotation cultures and three input conditions
(@tab-corpora).

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

= The detector family

*Profile correlation* is the floor: a duration-weighted, exponentially
decaying pitch-class histogram ranked against all 24 rotations of a
major/minor profile pair @albrecht2013 by Pearson correlation, abstaining
below a correlation-margin floor. *Weighted evidence* scores musician-style
rules per chord (diatonic membership, dominant and leading-tone function).
*Progression* votes on cadential transition patterns. A three-way *hybrid*
(correlation base plus small functional and progression blend terms) beat
the floor with paired significance (+0.096 exact per piece, p = 0.003).

The final architecture is a *causal HMM*: a filtered posterior over the 24
keys, updated by the forward algorithm (never Viterbi), with emissions
obtained as a softmax (temperature 0.25) of per-key scores and a transition
kernel with self-transition 0.9 whose off-diagonal mass decays with
circle-of-fifths signature distance. The claim is the posterior's top key;
confidence is its actual posterior probability; abstention triggers when the
posterior margin between the top two keys falls below 0.3 (the marked point
on @fig-sweep). Two design rules proved decisive. Emissions must be
*memoryless in the model's own terms* (the decayed histogram defines what
one observation means; the HMM supplies persistence), or history is
double-counted. And the emission scorer's decay half-life is not a smoothing
constant but the dial studied next.

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
  caption: [Emission-memory dose-response on the two development rulers.
    The curves run in opposite directions with no interior optimum: the
    dial selects the reported timescale. Coverage rises with memory on both
    rulers (0.77 to 0.93 on Isophonics); the section-scale plateau spans
    8-60 s.],
) <fig-dose>

= The timescale finding

Key annotations come in two cultures. Analyst local keys (When in Rome) mark
every tonicization, about seven key regions per piece at a few events each.
Song keys and key signatures (Isophonics, ASAP) name the section-level
center and absorb excursions. We call these the *tonicization-scale* and
*section-scale* rulers.

Sweeping the emission-memory half-life across 1 to 60 seconds on both
development rulers gives the dose-response curves of @fig-dose. On the
tonicization ruler, accuracy falls essentially monotonically with memory and
modulation matching halves; on the section ruler, accuracy climbs to a broad
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
      label: [30 s memory (shipped)],
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

The product conclusion is a choice, not a victory: an app's calm key
indicator should report the section, so the shipped configuration uses 30 s
memory and absorbs tonicizations deliberately. The research conclusion is
that *cross-paper accuracy comparisons are meaningless without matching the
label timescale*, since the same detector moves by tens of points when the
ruler changes.

*Ablations.* Two full 16-cell factorials (functional blend, progression
blend, duration weighting, recognizer-confidence weighting) ran on each
ruler. The functional blend flips sign with the ruler: removing it is a
significant paired win at section scale, while at reflex scale it is
decisively load-bearing (+0.061 exact, CI95 [+0.019, +0.108], p = 0.010),
the single cleanest exhibit that functional rules are excursion detectors.
The progression blend's earlier value was architecture-specific and washes
out under the HMM. Duration weighting helps on both rulers (+0.02 to
+0.05). Recognizer-confidence weighting is inert in five out of five
paired tests, a negative worth reporting since exploiting recognizer
confidence was the setting's most novel-looking asset. The shipped
emissions are therefore pure profile correlation, and a long-standing
behavioral failure (a 12-bar blues misread as its subdominant) vanished
with the deleted rules rather than through any added mechanism.

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
  caption: [Abstain calibration: the coverage-accuracy curve of the shipped
    configuration on the Isophonics development split, swept over the
    posterior-margin floor (0 to 0.6). The marked point is the shipped
    operating point (floor 0.3). The curve rises monotonically as the
    detector grows choosier: abstentions are informative, not random.],
) <fig-sweep>

= Mode disambiguation and a conserved-quantity principle

On mode-resolved corpora the residual errors sort into MIREX classes:
fifth-neighbor confusions, relative-pair confusions (shared signature), and
parallel-pair confusions (shared tonic). Mode errors, the most user-visible
class since an indicator displays major or minor, were about 10% of claims
on both rulers once the timescale trade was filtered out.

The remedy pattern: *a zero-sum evidence tilt confined to a key pair that
shares a musical invariant cannot leak into the inference the invariant
protects.*

*Parallel pairs (shipped).* Parallel keys share the tonic pitch class, and
practical minor borrows the raised sixth and seventh, so the discriminating
evidence collapses to roughly one pitch class and is easily outvoted in a
12-dimensional correlation. But our observations are symbolic: when the
played chord is rooted on a candidate tonic with a home quality, its major
or minor quality is the most direct mode cue available. Applied as a
log-odds tilt *within* the parallel pair, preserving the pair's emission
sum, the cue cannot move tonic evidence at all, so the mechanisms that got
its parent rules deleted (a tonic bonus that fought modulation tracking; a
functional blend that chased excursions) are structurally impossible.
Adopted at strength 2 after a 0.25-to-4 sweep with a 2-to-4 plateau: paired
exact wins on both rulers (Isophonics +0.016, p = 0.030; When in Rome
+0.030, p = 0.029), the first ingredient in the project to win on both
timescales (as the invariant predicts, the tilt is timescale-neutral), with
parallel confusion roughly halved everywhere measured (4% to 2% of claims
on Isophonics) and no behavioral or product-ruler stability cost.

*Relative pairs (measured negative).* The same pattern generalizes with the
key signature as the conserved quantity. But the evidence is structurally
weaker: the rival's tonic chord is ordinary diatonic harmony (the vi chord),
not rare mode mixture, so isolated chord quality fires constantly for the
wrong twin. Two sharpened cues were built and swept: a bass-gated tilt
(fires only when the chord's root is also its bass) and a cadential-bigram
tilt (a dominant-quality chord resolving down a fifth onto a home-quality
chord). The cadence cue is inert, echoing the progression ablation. The
bass cue works mechanically (relative confusion 6% to 4% of claims) but
misses paired significance on the primary ruler (+0.007, p = 0.055), trends
negative on the other (-0.009, p = 0.056), and doubles spurious p90; unlike
the parallel tilt's broad plateau it turns harmful at strength 2, the
signature of a weak signal. Not adopted; retained in code as a measured
negative.

*Fifth pairs (structurally ruled out).* Fifth neighbors conserve neither
tonic nor signature, and every key has two of them, so there is no pair to
redistribute within; discriminating a key from its dominant *is* the
modulation problem, and any chord-quality nudge between fifth neighbors is
the already-refuted tonic bonus reborn. Empirically the residual fifth
errors also lack an exploitable shape, splitting nearly evenly between the
dominant and subdominant sides (57/43 and 56/44 on the two mode-resolved
corpora).

One principle thus explains an adoption, a failure, and an impossibility:
the tilt's value tracks the strength of the conserved quantity (tonic:
strong; signature: weak; none: impossible).

= Adaptive temporal models: two measured negatives

*Explicit-duration modeling (HSMM), dispositioned by a probe.* The HMM's
self-transition implies geometric key-dwell times; an HSMM's contribution is
a richer dwell family. Before building one we measured whether the system
responds to the dwell parameter it would refine: sweeping self-transition
from 0.7 to 0.98 (implied mean dwell roughly 3 to 50 events) moves every
metric along the coverage-accuracy curve rather than off it (Isophonics
exact within 0.008, spurious p90 pinned at 1). A system this indifferent to
the dwell dial gives a richer dwell family nothing to act on.

*Bayesian online changepoint detection, built and measured.* The probe
dispositions the changepoint prior (constant-hazard BOCPD implies the same
geometric dwell) but not BOCPD's real contribution, the run-length-adaptive
evidence window: pooling evidence back to the inferred section start instead
of through a fixed 30 s decay. We built the constant-hazard detector for the
24-key space @adams2007 with emission conventions identical to the shipped
HMM (including the mode tilt), so differences isolate the window
(@tab-bocpd).

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, center, center, center, center),
    table.header([config (Isophonics dev)], [cov], [exact], [modulations],
      [spur med/p90]),
    [HMM, shipped], [0.92], [0.775], [94/192], [0/1],
    [BOCPD, hazard 1/200], [0.88], [0.715], [161/192], [5/14],
    [BOCPD, temperature 0.5], [0.89], [0.765], [135/192], [2/7],
    [BOCPD, temperature 1.0], [0.90], [0.769], [115/192], [0/4],
  ),
  caption: [BOCPD versus the shipped HMM on the section-scale development
    ruler. The adaptive window delivers modulation catching but no tuning
    recovers the calm operating point.],
) <tab-bocpd>

The adaptive window delivers its promise, modulation matching jumps by 70%,
because evidence resets at inferred section starts. But the same reactivity
breaks the section ruler's stability, and no tuning recovers the calm
operating point: softening the per-event evidence walks BOCPD back along the
frontier without reaching the HMM (best cell: exact wash, p = 0.51, spurious
p90 still 4 versus 1). One finding worth keeping: at matched reactivity
BOCPD dominates the HMM's fast settings (0.765 exact at 135 modulations
versus 0.736 at 141 for the HMM at a 2 s half-life), so adaptive windowing
is real value *in the reactive regime*; the calm regime does not need it.
The false alarms are within-section harmonic movement violating the
independent-given-key assumption, the failure mode that autoregressive BOCPD
extensions @tsaknaki2024 target for continuous series; those Gaussian
remedies have no analog for categorical chord emissions, and our domain's
version of within-regime dependence modeling (the progression layer) is
measured inert.

= Held-out evaluation

The test splits were evaluated exactly once, with the result set declared
before any run: the frozen configuration on all three splits, the
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
  caption: [The frozen configuration on the three held-out splits.],
) <tab-test>

Generalization is clean (@tab-test): Isophonics dips modestly from
development (0.775 to 0.732), When in Rome comes in far above it (0.434 to
0.587, easier held-out pieces), and stability holds everywhere; the
differences run in both directions, not the uniform degradation a
tuned-to-development configuration would show.

*The crossover holds with significance in both directions.* On the
tonicization ruler the reflex configuration beats the shipped one (0.649 vs
0.587 exact, paired +0.062, CI95 [+0.004, +0.121], p = 0.047); on the
section ruler the shipped configuration wins by a wide margin (0.732 vs
0.556, paired +0.175, CI95 [+0.040, +0.315], p = 0.039), with the reflex
configuration paying spurious 5/11 versus 0/3.

*External comparison.* @tab-baselines compares against music21's offline
whole-piece analyzers on the held-out songs.

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, center, center, center),
    table.header([system], [coverage], [exact], [MIREX]),
    [ours (causal, abstaining)], [0.88], [0.732], [0.782],
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
strictly harder setting*: the baselines read each entire song before
answering; ours never sees the future, abstains honestly on the ambiguous
12%, and carries calibrated posterior confidence and streaming stability
metrics offline systems do not have.

Mode confusion on held-out songs (descriptive): exact 72%, fifth 7%,
relative 5%, parallel 2%, other 14%. The parallel row matches the mode
tilt's development effect exactly.

= Limitations

The label timescale is a construct of the annotation culture, and our
central finding is precisely that results are relative to it; we mitigate
by reporting both rulers everywhere, but neither ruler is "the truth."
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

= Conclusion

Under a frozen protocol with paired statistics and a spent one-shot test
split, a causal, abstaining HMM over pure profile-correlation emissions,
with one structurally safe symbolic-evidence tilt, reports section-level
keys on live chord streams at accuracy that matches or exceeds offline
whole-piece baselines. The route there was mostly subtraction guided by
measurement: two factorials deleted the clever rules, a conserved-quantity
principle rescued the one rule worth keeping, and the fashionable adaptive
models were built or probed and measured out. What remains is a small,
legible detector whose every ingredient has a documented domain where it
helps, hurts, or does nothing, on both of the rulers a key can be measured
by.

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
