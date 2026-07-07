# 2026-07-07: ASAP performed input, and the champion does not transfer

**Goal.** Build the performed-input pipeline the research framing has pointed at
since the beginning: replay real piano performances through the actual Phase 1
capture path, and find out what survives contact with pedal blur and finger
rolls.

**Setup.**

- **Segmentation extracted to pure Dart.** The capture state machine
  (pending-challenger debounce, minimum duration, commit rules) moved from the
  Riverpod notifier into `ChordEventSegmenter` (`lib/features/history/domain/`);
  the notifier is now a thin shell owning wiring, the pending timer, and
  retention. All 14 history tests pass unchanged, so behavior is preserved, and
  offline replay now runs the literal capture code rather than a
  reimplementation.
- **`tool/whatkey_replay_batch.dart`**: JSON-lines of pedal-aware sounding
  snapshots in, committed `ChordEvent`s out, via the app's analyzer, the
  three-note capture gate, and the real segmenter.
- **`tool/whatkey_asap_extract.py`** (mido): parses ASAP performance MIDI with
  sustain-pedal semantics into sounding snapshots, replays them, and labels
  events from ASAP's key-signature annotations. ASAP does not annotate mode
  (signatures only, per its README), so every event carries `localKey: null`
  with `acceptableKeys` = [signature major, relative minor]: the meaningful
  scores here are within-pair adherence, coverage, and raw switch counts. The
  spurious-switch metric is vacuous on this corpus (its rule needs non-null
  truths), and within-pair rates are floors, since real local tonicizations away
  from the signature count as misses.
- **License gate**: ASAP is CC BY-NC-SA 4.0. The extractor refuses to write
  under `research/`, the manifest carries a NONCOMMERCIAL-GATED marker, and
  NOTICE.md names ASAP explicitly. Fixtures live in `build/` only.

```sh
git clone --depth 1 https://github.com/fosfrancesco/asap-dataset.git \
  /private/tmp/asap-dataset
mise research:whatkey-fixtures-asap   # 24 performances, one per piece,
                                      # round-robin across composers
dart run tool/whatkey_harness.dart \
  --fixtures build/whatkey-fixtures/asap-nc-v1 --detector hmm
dart run tool/whatkey_harness.dart \
  --fixtures build/whatkey-fixtures/asap-nc-v1 --detector hybrid
for hl in 5 10 30; do
  dart run tool/whatkey_harness.dart \
    --fixtures build/whatkey-fixtures/asap-nc-v1 --detector hmm \
    --decay-half-life-seconds "$hl" \
    --out "build/whatkey-harness/asap-nc-v1-hmm-hl$hl"
done
```

**Capture realism, first look.** The pipeline is dramatic about how selective
real capture is: a four-minute Beethoven movement produced 33 committed events
from 3,166 sounding-set changes; fast passages debounce away and thin textures
never pass the three-note gate. `asap-nc-v1`: 24 performances, one per piece
across 12 composers, 8,422 events.

**Results** (within-pair = claims landing on the annotated signature's major or
relative minor, over claimed events; switches summed over the set):

| detector                | coverage | within-pair | switches |
| ----------------------- | -------- | ----------- | -------- |
| hmm champion (1 s)      | 0.85     | 48%         | 804      |
| hmm, 5 s emissions      | 0.90     | 56%         | 405      |
| hmm, 10 s emissions     | 0.92     | 60%         | 263      |
| hmm, 30 s emissions     | 0.94     | 65%         | 127      |
| hybrid (prior champion) | 0.85     | 67%         | 169      |

Confidence weighting on vs off (hmm champion): 48% vs 48% within-pair, 804 vs
778 switches. A wash on the corpus that was supposed to be its best case.

**The finding: emission memory does not transfer.** The memoryless emissions
that transformed the HMM on clean score-derived events (entry 12) are its
downfall on performed input: per-event identities from real playing are far
noisier, the posterior chases them, and the detector flaps (804 switches).
Lengthening emission memory recovers it monotonically, and at 30 s, the
configuration that lost decisively on When in Rome, the HMM is at or past hybrid
parity here (65% within-pair at higher coverage with fewer switches). The
optimum sits at opposite ends of the dial on the two corpora.

Two confounds to keep in view when reading that comparison. First, the When in
Rome fixtures are synthesized from score annotations and never pass through the
segmenter, while ASAP events do, so "clean vs performed" is entangled with
"segmenter-bypassed vs segmenter-processed" (score events are roll-free, so the
effect is likely small, but it is unmeasured). Second, the corpora differ in
several correlated ways at once (noise, genre, event rate), and two corpora
cannot identify which one the emission dial tracks; a third corpus that is clean
but non-classical would triangulate it. Relatedly, the capture parameters
themselves (200 ms debounce, minimum duration, three-note gate) are a temporal
filter stacked below emission memory; they were chosen for live UX in Phase 1
and have never been evaluated as detector-input preprocessing. The
stacked-filter question is testable: sweep the segmenter minimum duration
against emission half-life on ASAP, and if longer debounce recovers memoryless
emissions, capture-side filtering substitutes for detector-side smoothing. Any
such tuning must ship in the app's segmenter, not fork the fixture pipeline from
the product.

**Plain-English reading.** On paper-clean chords, trusting each chord
individually and letting the model's own memory do the smoothing was the winning
move. Real playing is smeared: the pedal holds old notes under new ones and
rolls arrive one finger at a time, so individual chords are often misheard, and
a detector that trusts each one chases the mishearings. Giving the ear back its
blur (averaging recent evidence before believing it) fixes that, but that same
blur is what made the detector sluggish on clean input. One knob, two corpora,
opposite answers: the knob is really measuring how much the input can be trusted
per chord, which suggests it should be set by the input's noisiness rather than
fixed. Separately, the recognizer's own confidence signal, which we built for
exactly this noisy setting, measurably changed nothing even here; that idea is
now 0-for-3 and probably not coming back in its current form.

**Decisions.**

- Champion unchanged: adoption remains grounded in the frozen When in Rome
  protocol, and no per-corpus retuning happens silently. The transfer failure is
  recorded as the champion's known limitation on performed input.
- Confidence weighting: third null result (clean corpus, ablation, and now noisy
  performed input). It stays implemented and ablatable, but it is no longer a
  motivating claim.
- ASAP fixtures stay noncommercial-gated in `build/`, per the license.
- `asap-nc-v1` was used whole, as a diagnostic; that is disclosed here. Before
  any ASAP-informed default change, an ASAP development/test split must be
  frozen (by piece, by composer where possible, all performances of a piece on
  one side); the emission-memory dose-response above is characterization, not an
  adoption basis.

**Next.** Reconciling the emission-memory dial is now the top research question,
with candidate shapes: the segmentation/emission stacked-filter sweep (does
capture-side debounce substitute for detector-side smoothing?),
event-count-based decay instead of wall-clock, noise-adaptive emission
temperature, and joint selection across corpora. Supporting work in priority
order: freeze an ASAP split and expand past 24 performances (the pipeline makes
this cheap), transfer mode-resolved local keys onto the ASAP performances that
overlap When in Rome (notably the Beethoven sonatas), and eventually a clean
non-classical corpus (Isophonics or Billboard via a chord-symbol voicing
renderer) to break the noise/genre confound. Then the ablation pass, weight
tuning it motivates, and the one-shot test-split evaluation.
