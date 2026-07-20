# 2026-07-20: Held-out audit (one-shot)

**Goal.** Confirm the initiative's shipped findings on the test splits, which no
tuning ever touched. This is the single sanctioned test-split spend for this
result set (PROTOCOL.md, Splits); expectations were declared before the run and
are recorded here verbatim.

**Declared expectations (before running).**

- DCML test identity: inferred-key clean-pool top-1 ~98.5%, annotated ~98.8%
  (dev 98.46 / 98.82); the m7/6 family resolved, absent from the annotated
  residual.
- DCML test spelling: inferred tones ~98.6%, annotated ~99.4% (dev 98.64 /
  99.41).
- When-in-Rome test identity: annotated clean-pool top-1 in the high 90s, no
  m7/6 family in the residual.

**Setup.** Shipped engine (lever 0 m7/6 rule in whatchord; F# six-sharp key side
in whatkey KeySpace). Fixtures and labels as used throughout; the `--split test`
flag selects the held-out pieces (DCML 320 pieces / 13,060 clean events;
When-in-Rome 18 pieces / 730 clean events). One run each, no reruns.

```sh
dart run tool/chord-context/spelling_eval.dart --split test \
  --fixtures build/chord-context/fixtures/dcml-distant-listening-v1-span \
  --labels build/chord-context/labels/dcml-distant-listening-v1-span.labels.json \
  --split-file research/chord-context/data/splits/dcml-distant-listening-v1.json \
  --out build/chord-context/holdout/dcml-test-spelling
dart run tool/chord-context/headroom.dart --split test \
  --fixtures build/chord-context/fixtures/dcml-distant-listening-v1-span \
  --labels build/chord-context/labels/dcml-distant-listening-v1-span.labels.json \
  --split-file research/chord-context/data/splits/dcml-distant-listening-v1.json \
  --out build/chord-context/holdout/dcml-test-headroom
dart run tool/chord-context/headroom.dart --split test \
  --fixtures research/whatkey/data/fixtures/when-in-rome-v1 \
  --labels build/chord-context/labels/when-in-rome-v1.labels.json \
  --split-file research/whatkey/data/splits/when-in-rome-v1.json \
  --out build/chord-context/holdout/wir-test-headroom
```

**What happened.** Every declared expectation met or exceeded.

Spelling-harness metrics (identical populations dev and test):

| metric                  | dev    | test   |
| ----------------------- | ------ | ------ |
| DCML inferred identity  | 98.46% | 98.81% |
| DCML annotated identity | 98.82% | 99.29% |
| DCML inferred tones     | 98.64% | 98.75% |
| DCML annotated tones    | 99.41% | 99.36% |

- **Lever 0 generalizes.** The headroom harness's annotated-key clean-pool
  top-1, where the rule fires, is 99.3% (DCML test) and 99.5% (When-in-Rome
  test), both ~2 points above their neutral arms (98.2% / 97.5%), the same gap
  the rule produces on dev. The near-tie ceiling is 100.0% on both test splits:
  every clean-pool miss is still a near-tie, the structural invariant the whole
  initiative rests on.
- **The miss taxonomy is unchanged on held-out data.** The 229 DCML test
  neutral-arm clean misses are 100% the same family (172 halfDiminished7, 57
  minor7); zero new failure modes appeared on 320 unseen pieces.
- **The F# key side and speller generalize.** DCML test spelling reproduces dev
  within noise (inferred tones 98.75% vs 98.64%; annotated 99.36% vs 99.41%).

**Plain-English reading.** Nothing tuned to the development pieces fell apart on
the held-out ones. The chord-naming rule we added does the same thing on 338
pieces the project never looked at as it did on the ones it was built from, and
the spelling is the same. There are no hidden surprises; the initiative's
conclusions hold on fresh data.

**Decisions.**

- The test splits are now spent for this result set and must not be reused for
  further tuning (PROTOCOL.md). Any future change reopens with new development
  work and a fresh one-shot audit.
- The shipped changes (lever 0, F# key side) are confirmed to generalize; no
  regression or new failure family on held-out data.
- The initiative's measurement work is complete: every front shipped, closed, or
  costed, and now validated on held-out data.

**Next.**

- Finalize the initiative README to reflect the outcome; no further measurement
  planned.
