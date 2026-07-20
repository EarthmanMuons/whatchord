# 2026-07-20: Track B residual decomposed and closed

**Goal.** Due diligence on the Track B spelling residual (production 98.64%
tones vs 99.41% annotated ceiling, entry 2026-07-20-06): is there anything left
to squeeze, and where does the 0.77-point gap actually live?

**Setup.** Two additions to the spelling harness. A new oracle arm
`inferredRightSide` keeps the inferred key's pitch class and mode but takes the
annotated key's enharmonic side whenever they agree, so the gap from `inferred`
to it is exactly what perfect enharmonic side-following could win, and the gap
from it to `annotated` is key-detection error. And every misspelled tone is now
bucketed by which speller produced it (root / role-classified member / fallback
for unexplained tones) and whether it is diatonic in the ranking key.

```sh
dart run tool/chord-context/spelling_eval.dart \
  --fixtures build/chord-context/fixtures/dcml-distant-listening-v1-span \
  --labels build/chord-context/labels/dcml-distant-listening-v1-span.labels.json \
  --split-file research/chord-context/data/splits/dcml-distant-listening-v1.json \
  --split development \
  --out build/chord-context/spelling/dcml-dev-paths
```

**What happened.** On identity-correct events, tone errors: inferred 2,354,
inferredRightSide 2,320, annotated 1,024 (of ~174k tones). The 1,330-error gap
from production to the ceiling splits cleanly:

- **Perfect enharmonic side-following would recover 34 tones** (2,354 -> 2,320),
  0.02 points. The oracle ceiling for the mechanism the Isophonics census
  "validated" is essentially zero, because the F# cold-start fix (entry -11)
  plus the fewer-accidentals table already match the annotated side on almost
  every event where the inferred key is otherwise right. The census measured the
  direction of annotators' side preference, not the residual frequency of
  disagreement with an already-good table; measured, the frequency is
  negligible.
- **Key-detection error is the other 1,296 tones** (98%): events where the
  inferred key's pitch class or mode is simply wrong, which no spelling rule can
  fix. This is a WhatKey concern, not a Track B one.

The error-path buckets close the chromatic-line question independently. Under
the annotated key, every one of the 1,024 residual errors is a chord tone (root
or role-classified member); **zero are fallback-path (unexplained/passing)
tones.** Hex's line-of-fifths chromatic rules (last-semitone-diatonic, maximize
diatonic semitones between adjacent notes) act on passing and non-chord tones,
which are the fallback path, so within the clean pool they have no addressable
errors at all: on an identity- correct event every sounding tone is a chord
member by construction. The 439 chromatic errors that remain under the correct
key are chromatic chord tones (secondary-dominant roots, augmented-sixth
members, borrowed-chord tones), which is the functional-label / augmented-sixth
territory the protocol excludes from scored pools and which needs
acceptable-answer sets, a different problem than contextual spelling.

**Plain-English reading.** The spelling residual looked like three opportunities
and is really none. Choosing the enharmonic side of the key is worth two
hundredths of a point now that the F# default is in, because the key labels are
already spelled the way scores spell them almost whenever the key itself is
right. The chromatic-line heuristics have nothing to bite on in the pool we
score, because that pool only contains chords whose every note is a chord tone.
And the large part of the gap is the key detector guessing the wrong key, which
is a detection problem the spelling layer cannot touch. There is no
contextual-spelling mechanism left that would move the number.

**Decisions.**

- Track B is closed. The role-driven speller is validated at 99.4% under the
  true key (entry -06); the F# side fix shipped (entry -11); and the measured
  residual is 98% key-detection error and 2% a side-following ceiling too small
  to build for. No adoption candidate exists or is reachable at this layer.
- The chromatic-line rules are formally out of scope for the clean pool (zero
  fallback-path errors) and belong, if anywhere, to a future
  passing-tone/spelling study on the extra-tones pool, which entry -12 already
  closed as a span-view artifact. Recorded so the idea is not re-proposed
  against this evidence.
- Augmented sixths and other chromatic chord-tone spellings remain genuinely
  unmeasured (functional-label category, excluded from scored pools); they need
  acceptable-answer sets before any claim, and are noted as the only unexamined
  spelling question, distinct from the contextual side/line work this front
  covered.

**Next.**

- With Track B closed, the initiative's fronts are all shipped, closed, or
  costed. The only open product decisions are Track D (jazz comping mode, costed
  in entry -16) and history relabeling (a more accurate passive log, entry -15);
  both are user-experience calls, not research questions.
