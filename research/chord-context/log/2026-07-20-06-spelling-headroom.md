# 2026-07-20: Track B spelling headroom on DCML

**Goal.** Open Track B with a headroom measurement: how does the engine's member
spelling compare to the score's actual spelling, per tone, and how much of the
gap does key context already explain?

**Setup.** Ground truth is the DCML note table's `tpc` (line of fifths, the
score's exact spelling), carried into the labels sidecar per event as a
pitch-class-to-tpc map; pitch classes a span spells two ways are counted and
skipped. Spelling is scored only on events the arm names correctly at
root+quality, spelled exactly as the app's display path spells them (root via
`spellChordRoot`, role-classified tones via `spellPitchClass`, unexplained tones
via `noteNameForPitchClass`). Three arms: neutral (C major), inferred
(closed-loop detector key, the production path), and annotated (the score's
local key on its true enharmonic side). Two measurement fixes landed during
verification and are part of the record: the sidecar wire keys now keep the
annotation's true tonic spelling wherever it is single-accidental (previously G#
minor collapsed to Ab minor, which corrupted the annotated arm to 97.3%), and
the confusion-table name rendering had a floor-division bug for flat-side tpc
(display only; accuracy compares raw tpc).

```sh
mise run research:chord-context-fixtures-dcml
dart run tool/chord-context/spelling_eval.dart \
  --fixtures build/chord-context/fixtures/dcml-distant-listening-v1-span \
  --labels build/chord-context/labels/dcml-distant-listening-v1-span.labels.json \
  --split-file research/chord-context/data/splits/dcml-distant-listening-v1.json \
  --split development \
  --out build/chord-context/spelling/dcml-dev
```

**What happened.** DCML dev, clean pool, identity-correct events:

| arm       | identity | tones  | roots  | events all correct |
| --------- | -------- | ------ | ------ | ------------------ |
| neutral   | 97.80%   | 97.29% | 97.30% | 97.22%             |
| inferred  | 98.46%   | 98.04% | 98.01% | 97.92%             |
| annotated | 98.82%   | 99.41% | 99.43% | 99.32%             |

Every top confusion in every arm is an enharmonic-diesis pair (tpc off by 12: Db
vs C#, Gb vs F#, Ab vs G#, Eb vs D#, F vs E#, Cb vs B). The production path's
top confusions are one-directional flat-for-sharp (Db->C# 415, Gb->F# 378,
Ab->G# 327, Bb->A# 279): the key detector's claims live in pitch-class space and
the wire tonic table picks a fixed enharmonic side, so scores in sharp-side keys
get flat-side spellings. The annotated arm's residual 0.6% is the true
key-independent tail (chromatic lines, D#->Eb both directions), the part Hex's
semitone-line rules target.

**Plain-English reading.** When the engine knows the real key, spelled the way
the score spells it, its existing machinery already writes 99.4% of tones the
way the score does. The production gap (about 2 tones in 100) is therefore not
mostly a spelling-rule problem: it is that the app's inferred key cannot say
whether the player is in F# or in Gb, because key detection works on pitch
classes. Choosing the enharmonic side of the key is the Track B problem, worth
about 1.4 points of tone accuracy, and the line-of-fifths window over recently
played material is the natural mechanism for choosing it. A further half point
lives in chromatic lines that no key setting decides.

**Decisions.**

- Track B's concrete target is the enharmonic-side choice for the prevailing key
  (and secondarily chromatic-line spelling), not a rewrite of member spelling:
  the role-driven speller is validated at 99.4% under the true key.
- Design direction per the working notes: a rolling line-of-fifths window over
  recent pitch material chooses the key's enharmonic side (and can bias
  chromatic-tone sides), evaluated against the annotated arm as the ceiling and
  the current production arm as the baseline.
- When-in-Rome spelling ground truth is deferred: its fixture pipeline drops
  spelling; DCML's note-level tpc is sufficient for this phase.

**Next.**

- Design the side-chooser (window contents, width bound at the diesis, decay,
  interaction with manual key selection where the user's chosen spelling side
  must always win) and evaluate it in this harness.
- Fold the chromatic-line rules (last-semitone-diatonic) into a second ablation
  once the side-chooser's recovery is known.
