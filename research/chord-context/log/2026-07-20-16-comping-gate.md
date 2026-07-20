# 2026-07-20: Track D comping suite and gate measurement

**Goal.** Build the hand-authored comping suite entry 2026-07-19-04 required
before the Track D (rootless/ensemble voicings) gate could be decided, and
measure the three things the gate turns on: how badly the shipped engine does on
real comping voicings, whether relaxing the no-ghost-roots rule can reach the
expected readings, and what that relaxation would cost.

**Setup.** New suite,
`research/chord-context/data/sources/comping/comping-suite-v1.json`
(`chord-context-comping-suite/1`): 18 cases of canonical left-hand comping forms
(Levine rootless A/B forms) written as MIDI exactly as a pianist plays them over
a bassist, each with an explicit expected identity and an intent (`rootless`,
`shell`, `solo`). Cases sharing a `pitchSetId` have identical pitch classes and
differ only in intent, so the gate's central question is directly measurable.
Harness `tool/chord-context/comping_gate.dart` scores the shipped engine and
simulates the missing-root hypothesis from `rootless-voicings-notes.md` item 1
(guide tones required, legal colors only, root absent), reporting every
surviving hypothesis and then those surviving a diatonic key filter. Behavioral
probes, excluded from pooled statistics per PROTOCOL.md.

One authoring error was caught by the first run and fixed: a case labeled
rootless had its root sounding (F Ab C D contains D), so it is an inversion, not
a rootless voicing; it is reclassified as a guard case for the minor-mode lever
0 cell.

```sh
dart run tool/chord-context/comping_gate.dart \
  --suite research/chord-context/data/sources/comping/comping-suite-v1.json
```

**What happened.**

1. **The shipped engine gets 0 of 12 rootless and shell cases right** (6/18
   overall: every success is a solo or guard case). A rootless ii-V-I in B-flat
   reads as `Ebmaj7 / Ebmaj7#11 / Dm7` instead of `Cm9 / F13 / Bbmaj9`, and the
   worked C13 example from the notes reads as `Asus4add-flat-9/E`. The wrong
   readings are not close calls: the Ebmaj7 reading of a rootless Cm9 costs
   0.00, because with C absent it is a complete, root-position, perfectly
   ordinary chord.
2. **Ghost roots can reach every case: 12 of 12.** The missing-root hypothesis
   contains the expected identity in every rootless and shell case, so the
   mechanism proposed in the notes is sufficient in principle.
3. **But it is ambiguous on its own: unique in only 4 of 12.** Absent-root
   readings multiply; `E G B D` admits Cmaj7, C#o7, Ebmaj7 and Abm(maj7) with
   equal structural warrant.
4. **A diatonic key filter resolves much of that: unique in 7 of 12.** The five
   that survive are pairs where both candidate roots are diatonic, and they
   share a shape: `F A B E` in C is either G13 (canonical) or Cmaj7 with an 11th
   and 13th and no root or fifth (structurally legal, musically implausible).
   Resolving those is exactly the guide-tone and dominant-color weighting of
   notes item 3, not new theory.
5. **Every solo case would admit a ghost-root competitor: 6 of 6.** The same
   notes that spell a correct root-position chord always also spell some
   rootless chord. Auto-detecting ensemble mode from the pitch set is therefore
   impossible in principle, not merely hard.

**Plain-English reading.** For a jazz pianist comping over a bassist, the app
today is not slightly wrong, it is wrong on essentially every chord, because the
note the chord is named after is the one the bassist is playing. Allowing the
engine to name a chord after a note nobody played would fix all of these, but
the same permission would let it rename correct chords too: every plain voicing
in the suite could also be read as some rootless chord. So this cannot be
inferred from the notes; the player has to tell the app which situation they are
in. Given that mode, the key narrows most cases to one answer, and the handful
left over are the ones where a dominant reading and a strained tonic reading
compete, which normal jazz weighting settles.

**Decisions.**

- The gate now has its evidence: severity is total (0/12), feasibility is total
  (12/12 reachable), and the price is a user-visible mode plus three stacked
  layers (ghost-root templates, key filtering, guide-tone/color weighting).
- An explicit ensemble/comping mode is a hard requirement, not a design
  preference: 6/6 solo cases prove auto-detection cannot work from pitch
  content. Any future implementation that tries to infer the mode is rejected in
  advance by this measurement.
- No engine work is authorized by this entry. The gate decision is a product
  judgment about whether to add a mode for jazz comping, now costed.
- The suite is committed as the acceptance ruler for that work if it ever
  proceeds, including the solo and m7/6 guard cases that any ensemble mode must
  not regress (all 6 pass today).

**Next.**

- Product decision on Track D with this costing in hand.
- With this front measured, every front named in the design doc has been either
  shipped, closed, or costed; the initiative's remaining item is the Track B
  residual, which has no adoption candidate.
