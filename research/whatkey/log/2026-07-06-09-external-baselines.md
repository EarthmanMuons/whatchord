# 2026-07-06: External baselines and a profile A/B on the development split

**Goal.** Anchor our numbers against external reference implementations on the
same fixtures, per the protocol's Baselines section, and take a first look at
profile-pair choice inside our own detector.

**Setup.**

- `tool/whatkey/external_baseline.py` rebuilds each fixture's event stream as a
  music21 score (chords with fixture durations) and runs music21 10.1.0's
  whole-piece key analyzers; the resulting claims files are scored by
  `tool/whatkey/harness.dart --claims-file`, so external baselines run through
  exactly the same metric code as our detectors. Offline and non-abstaining: one
  global key per piece, scored as a constant claim on every event.
- Fixtures `when-in-rome-v1` (engine `aed5ea8b`, corpus `aa7539f1`), development
  split (59 pieces, 3694 events). Command:
  `mise research:whatkey-baselines-dev`.
- justkeydding intentionally excluded from the maintained executable baselines:
  the PyPI package (1.12.3) is a pure wheel, but it depends on `madmom>=0.16.1`.
  `madmom` publishes only an sdist for the current macOS/Python path and its
  2018 `setup.py` imports `Cython.Build` and `numpy` before build metadata can
  be evaluated. Under modern PEP 517 build isolation,
  `pip install justkeydding==1.12.3` therefore fails while asking `madmom` for
  build requirements with `ModuleNotFoundError: No module named 'Cython'`.
  Preinstalling `Cython` and `numpy` and using `--no-build-isolation` can build
  `madmom`, but the runtime is still stale on the repo's Python 3.12 toolchain:
  current `setuptools` no longer provides `pkg_resources` by default, and after
  pinning `setuptools<81`, `madmom` fails on
  `from collections import MutableSequence`. justkeydding imports its audio
  input module, and therefore `madmom`, unconditionally through
  `justkeydding.inputs`, so even symbolic or `--sequence` use hits the stale
  dependency. A future one-off comparison could use a pinned legacy
  Python/container or patched install, but that is not reproducible enough for
  the baseline suite we expect to rerun.

**Results** (development split; accuracy is exact / MIREX on claimed events,
mean per piece; global is final-claim MIREX).

External, offline, coverage 1.00 by construction:

| detector                     | exact | MIREX | global |
| ---------------------------- | ----- | ----- | ------ |
| music21 krumhanslschmuckler  | 0.37  | 0.52  | 0.62   |
| music21 aardenessen          | 0.41  | 0.55  | 0.67   |
| music21 temperleykostkapayne | 0.49  | 0.62  | 0.78   |

Ours, causal and abstaining (defaults: duration-weighted, 30 s decay,
marginFloor 0.05):

| profiles             | coverage | exact | MIREX | global (final/majority) |
| -------------------- | -------- | ----- | ----- | ----------------------- |
| krumhanslKessler     | 0.69     | 0.33  | 0.48  | 0.57 / 0.59             |
| albrechtShanahan     | 0.67     | 0.45  | 0.59  | 0.68 / 0.69             |
| temperleyKostkaPayne | 0.70     | 0.50  | 0.61  | 0.74 / 0.78             |
| temperley (1999)     | 0.69     | 0.53  | 0.62  | 0.73 / 0.80             |

**Reading.**

- Our causal, abstaining detector beats the offline KrumhanslSchmuckler and
  Aarden-Essen anchors on accuracy-on-claimed and global key, despite never
  seeing the future. "Our 2a beats our nothing" is now "our 2a beats two
  published offline baselines on the same data".
- music21's TemperleyKostkaPayne is the strongest external anchor, and the same
  profile family wins inside our detector too: both Temperley pairs outperform
  our Albrecht-Shanahan default on this corpus, and Krumhansl-Kessler is clearly
  worst, consistent with the literature.
- Comparisons across different coverages are not apples-to-apples: the external
  baselines claim on every event (coverage 1.00), ours abstain on the hardest
  ~30%. The honest headline is that constant-per-piece TKP gets 0.49 exact on
  all events while our streaming AS gets 0.45 on the events it claims; the
  local-key tracking margin over a no-tracking baseline is thin, which
  quantifies how much room the functional detectors (2d/2e) have.

**Decisions.**

- The default profile pair stays `albrechtShanahan` for now: the A/B numbers
  above are unpaired means, and default selection should get the paired
  per-piece treatment (Wilcoxon, CI95) the protocol prescribes before it
  changes. Recorded here as a strong candidate change.
- External claims are scored through the harness (`--claims-file`), never
  through a second scoring implementation.
- Maintained executable baselines must install and run on the current project
  toolchain without patched legacy dependency stacks. music21 remains the
  executable external anchor; justkeydding remains useful as a
  profile-provenance source (see the 2026-07-06 profile-provenance entry) but is
  not part of the rerunnable baseline set.

**Next.** The weighted evidence model (2d): the profile floor is now fully
anchored, and the thin margin over no-tracking baselines is the gap 2d needs to
widen, especially on modulation tracking.
