# 2026-07-06: Protocol pins before building the harness

**Goal.** Review PROTOCOL.md for gaps that would shape the offline harness's
contract, before implementation starts, without freezing the full protocol.

**Setup.** Documentation only; no code. Follows the split freeze and license
gate (entries 04 and 05).

**What happened.** Five rules were pinned because they define the harness API
and are cheap to enforce from day one but expensive to retrofit; three known
unknowns were named as explicitly deferred to freeze.

**Decisions.**

- **Label isolation.** The harness structurally strips fixture `labels` before
  events reach a detector. Detectors consume observation fields only.
- **Top-1, event-weighted scoring.** Every metric scores the top-1 claim; the
  ranked list is diagnostic. Each event counts once regardless of duration.
- **Selective-prediction accuracy.** Coverage (fraction claimed) and accuracy on
  claimed events are reported as an inseparable pair; abstentions reduce
  coverage, they are not errors. Ambiguous-labeled events (null `localKey` with
  `acceptableKeys`) accept abstention or any acceptable key and stay out of
  corpus accuracy pools.
- **Switch definition.** Stability counts switches between consecutive claims
  only; abstain-then-reclaim of the same key is not a switch, so abstaining
  under uncertainty is not charged twice.
- **Harness discipline.** Development split by default; test split needs an
  explicit flag plus a dated log entry per run. The harness validates split pins
  against the fixture manifest and fails on piece mismatches rather than
  skipping. No pooling across fixture versions.

**Deferred to freeze** (named in PROTOCOL.md so they are decisions-in-waiting,
not omissions): modulation-lag censoring and minimum-segment rules; the
global-key operationalization (harness reports final-event and duration-weighted
majority claims until pinned); abstain calibration as a single operating point
vs. a coverage-accuracy curve.

**Next.** Build the harness against these rules: manifest/split loader,
profile-correlation baseline detector, metric scaffolding, then a dated
baseline-run entry with engine commit, fixture version, split, command, and
caveats.
