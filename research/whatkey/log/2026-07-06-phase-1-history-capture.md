# 2026-07-06: Phase 1 shipped, chord history capture

**Goal.** Build the temporal data foundation: record a sliding-window history of
live chord identifications that Phase 2 detectors can consume, per the plan in
`../temporal-context-key-detection.md`.

**Setup.** Engine at commit `b4a6a8e3` (initial capture) and `8aff5fb7`
(debounce revision). No fixtures or detectors yet; this phase is
capture-in-the-app only.

**What happened.** New `lib/features/history/` module: `ChordEvent` (input,
voicing, ranked candidates with cost gaps, analysis-time tonality, hold
duration) and `ChordHistoryNotifier`, wired into the app lifecycle and covered
by 14 unit tests driven through the real analysis chain.

**Decisions.**

- **Segment on identity change, not release.** A pedaled or legato progression
  records as a chord sequence rather than one union pitch-class set. Release,
  decay below three sounding notes, and mode gating are additional commit
  triggers.
- **Debounce with a pending challenger.** A new identity only ends the current
  chord after persisting past the threshold itself; a challenger that dissolves
  back into the held identity was a finger roll, and the chord continues as one
  uninterrupted event. Committed chords end at the challenger's onset. This came
  out of review: the first implementation split a held chord in two around any
  transient blip, which would have made Phase 2 duration weighting noisier than
  intended.
- **One threshold, double duty.** `historyMinChordDurationProvider` (200 ms)
  serves as both the challenger-stabilization debounce and the commit minimum.
  Split into two providers only if tuning ever needs them apart.
- **Capture-time gating.** Demo and lookup chords are excluded by gating the
  capture frame, not the commit, because their toggle-off transitions land after
  the mode flags have flipped and a commit-time check would record a stale
  non-live chord.
- **Onset snapshots.** Events snapshot input, voicing, candidates, and tonality
  at identity onset; same-identity changes mid-hold (added doubling, manual
  tonality switch) neither update nor re-segment, so stored candidates always
  reflect a ranking performed under the stored tonality. Chosen over
  re-segmenting on context change, which would fake chord repetitions.
- **Retention.** Capacity 100 events (memory cap, enforced on record); age
  filtering is a read-time concern via `recentEvents(window)`. History is
  in-memory only and never persisted, by design.
- **Alternatives definition reused.** Event candidate lists are the chosen
  candidate plus `ChordCandidateRanking.alternatives`, so history and the UI
  agree on what counts as a relevant alternative.

**Next.** Phase 2 prep: freeze `../PROTOCOL.md`, extend the When in Rome tooling
to emit labeled `ChordEvent` fixtures under `../data/`, hand-author the pop/jazz
set, then build the offline harness and the profile-correlation floor.
