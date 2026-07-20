# The m7/6 Family: Analysis and Design Options

Status: working notes, 2026-07-19. The musical-review companion to log entries
2026-07-19-01 and -04, which established this family as the entire clean-pool
headroom on both rulers. Sources below were fetched and verified during the
review; URLs are the citations. Resolved 2026-07-20: option C adopted with the
contested middle going to the lead-sheet readings (log entry 2026-07-20-01), and
the scoped rule cleared the protocol's paired-statistics bar offline on both dev
rulers with zero harmful flips (log entry 2026-07-20-02).

## The ambiguity

A minor-seventh chord and the major-sixth chord on its third are the same pitch
classes: {D F A C} is Dm7 and F6; {D F Ab C} is Dø7 (m7b5) and Fm6. Every
inversion of one is a voicing of the other, so the question "which name?" is
decided by convention, not by the notes. The engine's cost model prices the
difference almost entirely as bass placement (root-in-bass 0.0 vs. core
inversion 0.15, plus 0.1 vocabulary for m7b5), which lands every disagreement
inside the near-tie window: this family is permanently a tie-break decision.

Current engine policy, by which chord member is in the bass (verified with
`tool/chord_debug.dart`; each outcome is decided by a different named
tie-breaker, all tonality-blind):

| bass            | chosen          | rule                                        |
| --------------- | --------------- | ------------------------------------------- |
| m7 root (D)     | Dm7 (root pos.) | prefer root-position relative minor7 over 6 |
| m7 third (F)    | F6 (root pos.)  | prefer root-position 6th over inverted 7th  |
| m7 fifth (A/Ab) | F6-family slash | prefer more conventional inversion          |
| m7 seventh (C)  | Dm7/C           | prefer common naming preference             |

## Corpus evidence (DCML dev, log entry -04)

1,344 clean-pool misses, all of them this family: 881 half-diminished readings
named m6, 461 minor-seventh readings named 6, 2 augmented-family relatives.
Structure:

- The expected seventh-chord root sits on degree II of the local key in 55%
  (742) of cases: the ii65 / iiø65 predominant, in both modes. Next largest: VII
  in major (147, the viiø7 family), VI in major (111, the vi65-vs-I6 cases), IV
  in minor (75), #IV in major (57, applied predominants).
- 63% of miss events move directly to a dominant-function chord: textbook
  predominant resolution. What precedes is uninformative (tonic 35%, dominant
  33%, predominant 27%): position-before does not identify the family;
  position-after does.
- 259 of 1,344 carry applied figures (`ii%65/V` and similar), invisible to any
  rule keyed on the local tonic alone.

## What the traditions say

Both sides have real authority behind them, and the two strongest style-guide
sources each state explicitly that context, not the pitch set, decides.

**For the bass-rooted sixth chord.** Lead-sheet culture names from the bass and
treats 6 as a first-class quality: Brandt & Roemer's copyist standard ("the term
'sixth' is used only with major or minor triads in the sense of 'added 6th'; the
root of the chord must always be given"), with slash symbols reserved for when
the alternate bass matters
(https://www.popschoolmaastricht.nl/pdf/RoemerBrandt-StandardizedChordSymbolNotation.pdf,
https://www.berklee.edu/berklee-today/summer-2018/lead-sheet). Jazz treats 6 as
interchangeable with maj7 on tonic function (Levine, The Jazz Theory Book: "C
major 7th ... can be notated as Cmaj7, CM7, C6, C6/9, or C-delta";
https://www.ejazzlines.com/mc_files/2/shjtb.pdf), the added sixth having been
jazz's tonic chord of choice since the 1930s
(https://www.mtosmt.org/issues/mto.23.29.2/mto.23.29.2.martin.html). The m6/m7b5
pair is resolved by bass in every practical jazz source
(https://www.jazz-guitar-licks.com/blog/what-s-a-half-diminished-chord-m7b5.html),
IVm6 and im6 are canonical Berklee functional slots, and even one classical
tradition (Riemann's S6, the subdominant with added sixth, fundamental F
regardless of bass) roots the chord on F by fiat
(https://archive.org/details/cu31924022305357). Psychoacoustics agrees the bass
fixes ambiguous roots
(https://journals.sagepub.com/doi/abs/10.1177/10298649211062934), and crowd
transcriptions prefer root-position labels (https://zenodo.org/records/1417549).

**For the seventh-in-inversion.** Common-practice pedagogy has no added-sixth
category in its Roman-numeral inventory: Aldwell & Schachter teach D-F-A-C over
F as ii65 outright ("ii65 is the most frequently-used of all the ii7 chords";
https://sfcm.edu/study/majors/academics/music-theory-and-musicianship/sfcm-theory/online-materials/harmony-supplements/aldwell-schachter-chapter-13),
and "in classical theory there is really no such thing as a sixth chord"
(https://www.ars-nova.com/Theory%20Q&A/Q37.html). Tertian root-finding picks the
seventh-chord root (Temperley's compatibility rule,
https://davidtemperley.com/wp-content/uploads/2015/11/temperley-mp97.pdf), and
music21 returns Am7/C for {A C E G} over C, never C6. The minor-mode iiø65 is
the canonical classical predominant.

**The context conditions, stated for 300 years.** Rousseau's dictionary entry on
Rameau's double emploi: the two chords "carry exactly the same notes ... often
one can only tell which one the author intended by the following chord which
resolves it": rising dissonance means added sixth (plagal, to I), falling
dissonance means inverted seventh (to V)
(https://www.rousseauonline.ch/pdf/rousseauonline-0068.pdf). The modern jazz
equivalent: 6 chords live on I and IV, m7 chords on ii/iii/vi, so "in a C major
tune you are more likely to see C6; in a G major tune, Am7"
(https://music.stackexchange.com/questions/6756/). And Brandt & Roemer, choosing
between the two spellings of one sonority: the choice "might be influenced by
the sequence of chords in the particular progression ... the choice is an
arbitrary one."

**MIR precedent.** Harte's syntax deliberately allows both spellings and
declines to legislate; annotator studies show this exact pair is where human
experts disagree
(https://www.tandfonline.com/doi/full/10.1080/09298215.2019.1613436). The
near-tie is not a bug: it is the honest representation.

## Why key context alone cannot decide

The two candidate roots are a minor third apart, relative-key partners: wherever
F6's root is diatonic, Dm7's root is diatonic too. Root-degree tie-breakers (the
engine's `preferDiatonic`) therefore never separate them, which is the mechanism
behind Phase 0's key-oracle result: ranking under the annotated key moved
nothing, on either ruler. Key can only help through a sharper pattern: which
degree PAIR the two readings occupy (6th on IV vs. m7 on ii, 6th on I vs. m7 on
vi), and that pattern is exactly where the two traditions agree and disagree.

## Design options

**A. Status quo: always the bass-rooted 6th (in bass-on-third position).**
Correct for isolated voicings and jazz tonic function; matches Brandt & Roemer's
unmarked form. But it also misnames the genre-agreed ii-function cases: a jazz
player comping a ii-V in C calls {D F A C} Dm7 regardless of inversion, and
classical analysis agrees; those are 55% of the corpus misses.

**B. Always the seventh-in-inversion.** Matches classical pedagogy and music21.
Unacceptable for a lead-sheet audience: it renames every jazz tonic 6th (C6
becomes Am7/C on a final chord), the added-sixth reading disappears from the app
entirely, and Brandt & Roemer's bass-first convention is violated in the
no-context case.

**C. Context-conditional preference (recommended shape).** Keep the 6th reading
as the isolation and Explore default (product contract: no key, no change).
Under a confident prevailing key, prefer the seventh-in-inversion reading where
the traditions agree, keep the 6th where they agree the other way, and make an
explicit owner call on the contested middle:

- Genre-agreed toward the inversion: the m7 root on degree ii of the key (ii65
  and minor-mode iiø65; jazz ii-V logic and classical pedagogy align). 55% of
  the miss population. Likely also the viiø7 family (m6 rooted on II is not a
  lead-sheet idiom; 147 cases).
- Genre-agreed toward the 6th: the 6th root on the local tonic (I6/i6; jazz
  tonic function, Rameau's plagal face). Note this keeps the vi65-vs-I6 cases
  (111 + 42) as deliberate, audience-correct disagreements with the analysts.
- Contested, needs an owner decision: major-key borrowed iiø65 vs. IVm6
  (classical roots it on ii even over the subdominant bass; Berklee gives IVm6
  its own subdominant-minor slot; the sharpest clash in the literature) and the
  smaller VI/III-rooted cases.

**D. The resolution rule (Rameau) as a temporal cue.** The actual decider in
both traditions is what follows, which a causal live display cannot see.
Consequences: (a) the live layer should rely on key-degree patterns (option C),
not resolution; (b) the history/relabel product is where Rameau's rule belongs,
and this family is its first concrete use case; (c) 63% of corpus cases
resolving to a dominant puts a measurable ceiling on what a retrospective rule
would confirm.

**E. Presentation regardless of ranking.** Both readings are already surfaced
(chosen plus near-tie alternative). Whatever the primary, the alternative
display carries the other tradition's answer; any rule change here only swaps
which is first.

## Measurement plan for option C

The rule is a lever 0 tie-breaker (tonality-gated, this family only), ablated
per the frozen protocol: paired per-piece Wilcoxon on DCML dev and When-in-Rome
dev, no regression on other pools, isolated-voicing behavior untouched
(empty-context invariance guard), benchmark unchanged. Expected recovery if the
genre-agreed subsets adopt the inversion reading: roughly the II-rooted 55% plus
the viiø family, minus the 259 applied-figure cases a local-tonic rule cannot
see. The contested subsets are excluded from the rule until decided, so measured
wins are attributable to agreed conventions only.
