# Live MIDI Latency Targets

## What this is

A design note for live MIDI responsiveness: the latency targets WhatChord should
protect when changing the engine, MIDI/input pipeline, Riverpod wiring, or
benchmark harness. It exists so performance work does not optimize throughput
while accidentally allowing musician-visible lag.

The headline: live chord labels should feel effectively immediate during normal
playing and should not fall a note-change behind during fast ornaments, trills,
tremolos, or rapid chord changes.

---

## Targets

For live MIDI input, target the full user-visible path:

- **p95 MIDI state change to chord label update: <= 30-40ms.**
- **p99 MIDI state change to chord label update: <= 50ms.**
- **Pure engine analysis time: low single-digit milliseconds.**
- **Chord coalescing/settling window: ~15-25ms when needed.**
- **Avoid fixed live-input debounce above 40-50ms.**

The engine target is deliberately smaller than the interaction target. Engine
analysis should not be the dominant source of latency, because the full path
also includes MIDI transport, OS scheduling, input state updates, provider
notifications, and frame rendering.

These numbers are design targets, not a promise that every platform and device
can always meet them. They are the thresholds future changes should explain if
they intentionally exceed.

---

## Why these numbers

The user does not perceive a benchmark iteration; they perceive the time between
changing the notes under their fingers and seeing the chord label change.

For musicians, latency in the 30-50ms range can start to feel late during active
performance feedback. Under ~30ms usually reads as effectively immediate for
visual chord feedback. By 50-100ms, the label can visibly trail the performance,
especially when the player is watching the display while changing shapes. Above
100ms, the analyzer is very likely to feel behind.

Adjacent music-performance systems give useful calibration. Professional live
audio monitoring often aims for roughly 10ms of end-to-end latency, where the
performer is directly hearing themselves through the system. Networked music
performance is usually more forgiving than direct monitoring, but latency around
20-30ms is commonly treated as the region where timing starts to become
noticeable or musically problematic. WhatChord's chord label is visual feedback
rather than the performer hearing their own sound, so it does not need to meet a
10ms audio-monitoring target. But those numbers explain why 30-50ms is the right
caution zone for live analysis feedback.

Fast playing makes the budget concrete. A fast trill can produce note-on changes
around 12-20 notes per second, or one new note every 50-80ms. If WhatChord waits
75-100ms before publishing a new analysis, the displayed identity can be one
gesture behind. Rapid chord changes and tremolos have the same failure mode: the
app may still be showing the previous state when the next state has already
arrived.

Chord attacks also are not perfectly simultaneous. A pianist may press the notes
of a block chord across roughly 5-30ms, and a loose attack, rolled shape, or
MIDI transport serialization can widen that spread. A short settling window can
therefore improve correctness by avoiding transient partial-chord labels.
However, the window needs to stay short enough that it does not hide genuinely
fast changes. Around 15-25ms is a reasonable design range; a fixed debounce past
40-50ms should be treated as a latency risk unless there is a narrow, measured
reason for it.

---

## Engine budget versus interaction budget

Keep these budgets separate:

- **Engine budget**: pure Dart chord analysis should remain fast enough that it
  is not the dominant source of live latency.
- **Interaction budget**: MIDI event ingestion, note-state updates, analysis,
  provider propagation, presentation mapping, and UI paint should together
  remain below the perceptual target.

The benchmark harness is best suited to the engine budget. It should continue to
report reproducible engine timing, memory, and operation counters. But engine
throughput alone is not the whole live experience. A change can make
`ChordAnalyzer.analyze` faster while adding debounce, coalescing, scheduling, or
provider churn that makes the visible label slower.

When changing the live path, prefer measurements that can answer both questions:

- How long does the pure analysis take?
- How long after a MIDI state change does the user-visible chord identity
  update?

If the harness gains live-latency fixtures later, report tail behavior such as
p95 and p99. Averages are useful for throughput, but latency regressions are
often felt in the tail.

---

## Design implications

Analyze promptly on every meaningful MIDI state change. If the app needs to
settle potentially simultaneous notes, treat that as a short coalescing window,
not as a broad debounce of live analysis.

Prefer provisional immediacy over delayed certainty where the UI can support it.
For example, the analyzer may update immediately as notes arrive while a short
settling window prevents committing a transient state to longer-lived history or
derived temporal context. The exact mechanism can vary by feature, but live
input should not wait for a long debounce before the app can react.

Avoid hiding latency in state management. Provider subscriptions, timers, and
coalescing logic should be explicit, cancelable, and easy to reason about. If a
feature adds a delay to the live path, make the delay named and covered by a
test or benchmark expectation where practical.

Benchmark changes should be interpreted against these targets. Constant-factor
engine wins are valuable because they preserve headroom for platform variability
and dense voicings. But a change that improves average benchmark throughput
while adding 75ms of fixed live-input delay would be wrong for the product.
