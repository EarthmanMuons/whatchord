# Rootless Voicings Notes

Status: working notes, promoted from the root scratchpad on 2026-07-19. These
feed the Track D gate (rootless and ensemble voicings) of the chord-context
initiative; see `temporal-context-chord-recognition.md`. Nothing here is
committed work; it is the design sketch the gate decision will draw on.

## The problem

Jazz comping routinely omits the root: over a bassist, a pianist plays
`E Bb D A` and means C13. The current engine cannot produce that reading. Two
structural constraints stand in the way:

- Candidate roots must be sounding pitch classes (the no-ghost-roots rule in
  `chord_analyzer.dart`), so an absent root is never hypothesized.
- The root is always a required tone; the one-missing-essential allowance covers
  fifths, thirds, and sevenths, never the root.

The result is systematic misreads of comping voicings as slash chords or remote
qualities (`E Bb D A` as something like Asus4b9/E). The contrapunctus benchmark
comparison scored "rootless annotation" as its own failure category (11 cases,
all excluded by the no-ghost-roots policy) and floated a possible ensemble/jazz
mode. This is related to, but stronger than, omission naming (omit/no labels),
which still requires the root to sound.

## Design sketch

1. **Missing-root hypothesis templates.** Templates that explicitly allow one
   missing essential tone where that tone may be the root only. A rootless-13
   template: required 3 and 7 (guide tones); optional 9, 11, 13, alterations;
   root explicitly permitted missing. For candidate root R, check whether the
   set contains {R+4, R+10, R+2, R+9}; for R = C that is exactly E, Bb, D, A,
   making "C13 (rootless)" a scoreable candidate.
2. **Bass semantics in ensemble mode.** Rootless voicings put the 3rd or 7th in
   the lowest voice, which the bass-placement pricing and inversion rules
   systematically misinterpret. Either an ensemble/comping mode reduces bass
   weight and raises guide-tone weight, or the engine distinguishes playedBass
   (lowest input pitch) from functionalBass (unknown or inferred), weighting
   playedBass strongly only in solo mode.
3. **Guide-tone completeness reward.** For jazz-functional chords, guide tones
   carry the identity: reward candidates containing both 3 and 7, more with one
   or more of 9/11/13, more again for dominant-type candidates carrying classic
   dominant colors (13 with 9, altered tensions).
4. **Slash-reading counterweight.** When a rootless reading is plausible, add a
   mild penalty to slash interpretations whose bass is a guide tone commonly
   found at the bottom of rootless voicings, and to roots not supported by
   functional tones. Gentle, because sometimes the slash chord is exactly what
   the music is doing.
5. **Temporal implied-root tracking (the biggest win).** Over a stream of
   frames, track a hidden implied root (Viterbi or beam search) with transition
   costs preferring root motion by fifths and seconds, consistency with key and
   scale-degree priors, and minimal churn in chord quality. Comping moves by
   smooth voice leading and functional progressions, so what is impossible from
   a single snapshot becomes feasible over a phrase.

## Mode question

Solo mode versus ensemble mode is probably a real product distinction, whether
set explicitly or auto-detected: the bass-weighting change in point 2 is wrong
for solo piano and right for comping over a bassist. The gate decision should
treat the mode surface as part of the contract, not an implementation detail.

## Relation to the initiative

Items 1-4 are snapshot-engine changes (candidate generation and pricing), not
temporal ones; item 5 is where temporal context enters. That is why Track D is
gated separately: it changes the engine contract rather than layering on top of
it. The initiative's corpus tags rootless cases from day one (the contrapunctus
failure category plus a hand-authored comping suite) so the gate is decided on
measured headroom, not vividness.
