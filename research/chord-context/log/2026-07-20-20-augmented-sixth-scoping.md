# 2026-07-20: Augmented-sixth spelling scoped

**Goal.** Answer what it would take to measure the augmented-sixth cases (the
initiative's original motivating example, `contextual-spelling-notes.md`) and
size the upside, since they are the one spelling question the protocol's scored
pools have never touched (functional-label category, excluded).

**What the data shows.** Augmented sixths are 1,334 events corpus-wide, 1,295 in
the DCML dev split (~0.7% of dev events; comparable in size to the m7/6 headroom
that shipped). DCML represents them fully: chord_type `Ger`/`It`/`Fr`,
decomposed `root`/`bass_note`/`chord_tones` in fifths, and the note-table `tpc`
gives the score's exact spelling of every tone, already carried in the labels
sidecar. So the spelling ground truth is in hand.

The engine's behavior is structural, verified at the CLI. A German sixth in C
minor, `Ab C Eb Gb`, is named `Ab7` at cost 0.00 and its raised tone is spelled
`Gb` (the flat-7 role of Ab7). The score spells that tone `F#` (an augmented
sixth above the bass, which resolves up to G). The engine has no augmented-sixth
chord quality and no augmented-sixth tone role, so within an Ab7 identity it can
only ever spell Gb; it cannot produce F# for this pitch class in this chord.
Identity and spelling are therefore coupled: the F# spelling is unreachable
without either a new chord vocabulary or a context-override that respells a
dominant's flat-7 as an augmented sixth.

**Plain-English reading.** The score writes these chords one way (an augmented
sixth, F#) and the app writes them another (a dominant seventh, Gb), and the
difference is not a spelling bug, it is the app not having the augmented-sixth
concept at all, on purpose. The measurement would confirm what the CLI already
shows: the app disagrees with the score's spelling on essentially all 1,295,
because it is naming the chord the lead-sheet way, which the initiative decided
long ago is the correct layer for this app.

**Cost and upside.**

- Measurement cost is low: the spelling ground truth already exists; the work is
  an acceptable-answer set for the functional-label category (does the app
  accept `Ab7` as a name for a German sixth?) plus expected-identity labels,
  then un-skipping the category in the spelling harness. A day.
- The upside is small and spelling-only: the identity (`Ab7`) is already the
  lead-sheet-correct reading the initiative committed to, so nothing there
  improves. Only the raised-tone spelling (Gb vs F#) could change, on ~0.7% of
  events.
- And the "fix" is both expensive and philosophically contested. Reaching F#
  needs a new augmented-sixth role or a context-sensitive respelling override,
  both against the pitch-class/lead-sheet design; and for the app's audience the
  value is unclear, since a jazz reader seeing this voicing comps it as Ab7 with
  Gb. The F# spelling is the functionally correct one (it resolves upward), so
  there is a real argument for it, but it is a classical-analysis expectation
  more than a lead-sheet one.

**Decisions.**

- The augmented-sixth question is characterized and sized, not built. It is a
  ~0.7%-of-events, spelling-only, contested improvement that would require
  engine work against the app's design philosophy. It does not clear the bar the
  other fronts were held to.
- If a formal number is ever wanted to fully close it, the path is recorded
  above (acceptable-answer sets + un-skip the category); the result is
  predetermined to be near-total disagreement with the score's spelling, which
  is the app naming these the lead-sheet way by design.
- This closes the last unmeasured spelling thread: the earlier "genuinely
  unmeasured" flag in entry 2026-07-20-17 is now scoped, with the conclusion
  that measuring it would document a deliberate design choice rather than reveal
  headroom.

**Next.**

- No action unless the app decides it wants augmented-sixth spelling for a
  classical-analysis audience, which is a product-scope question beyond this
  initiative's lead-sheet framing.
