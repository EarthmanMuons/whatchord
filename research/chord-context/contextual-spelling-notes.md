# Contextual Spelling Notes

Status: working notes, promoted from the root scratchpad on 2026-07-19. These
feed Track B (contextual spelling and notation) of the chord-context initiative;
see `temporal-context-chord-recognition.md`. The line-of-fifths material
originates from a conversation with Hex on the Music Theory Discord, lightly
edited.

## The problem

WhatChord names sonorities at the pitch-class layer, so enharmonically
equivalent chords get one canonical name regardless of function. With
surrounding context (key, prior chords, melodic direction), a different
enharmonic spelling of the same pitch classes is often the musician-expected
reading. This is a presentation-layer problem: the identity ranking can be
correct while the spelling is not.

## Canonical test cases: augmented sixths vs. dominant sevenths

Each pair is pitch-class identical; only context distinguishes them.

- `Ab C Eb F#`: German augmented sixth in C minor, if resolving to G. Spelled
  `Ab C Eb Gb`, it is Ab7 functioning as a dominant seventh.
- `Ab C F#`: Italian augmented sixth in C minor. Spelled `Ab C Gb`, an
  incomplete Ab7.
- `Ab C D F#`: French augmented sixth in C minor. Spelled `Ab C D Gb`, an Ab7#11
  / Ab7b5-flavored dominant color.

The best first test case is the German sixth with its resolution played out:
`Ab C Eb F#` moving to `G B D G` (directly, or through the cadential six-four
`G C Eb G`). The resolution makes the augmented-sixth function unambiguous.
WhatChord's current pitch-class layer calls the sonority Ab7, which is expected
and correct for that layer; the contextual spelling layer is what would
distinguish them. Note that a C minor key context alone often suffices, before
the resolution arrives: Gb is remote in C minor's fifths neighborhood while F#
is adjacent, so key-conditioned spelling handles this causally.

## Line-of-fifths window heuristic (Hex)

The core idea: choose the enharmonic spelling of a rolling window of pitch
classes that minimizes the width of the spelled set on the line of fifths. Hex's
illustration, two spellings of the same combined pitch classes:

```
Gb Db Ab Eb Bb F C G D A E B F# C# G# D# A#
                 * *   * *   *        *
```

versus:

```
Bbb Fb Cb Gb Db Ab Eb Bb F C G D A E B F# C# G# D# A#
*         *        *       * *   * *
```

Taken together, the pitch classes span 9 fifths when spelled contrapuntally
correctly versus 13 when spelled naively. (In lead-sheet symbol terms, for a
diminished seventh Hex would still almost always take the bass as the root.)

Heuristics, in Hex's formulation:

- Keep rolling windows of recent pitch classes and infer the most likely
  spelling of the whole set, minimizing its total width in fifths.
- Maximize the number of diatonic semitones between adjacent notes.
- Assume the last semitone in any chromatic line is diatonic, and strongly
  prefer diatonic semitones for the final motion of any line involving a
  semitone in the MIDI.

Known bounds: by itself the method never produces a window wider than 12 fifths
(the enharmonic diesis; anything wider could be respelled). In practice,
chromatic notes most often approach diatonic notes by diatonic semitone, which
can produce correctly spelled passages in a single key that aggregate to
slightly more than 12 uniquely spelled pitches. Combined with the semitone
heuristics, this should spell most material well short of constant modulation to
remote regions. A side benefit: consistent spelling helps choose roots
consistently on the lead-sheet side.

The fifths-window approach works best once enough context exists to surmise the
key, which ties it to the temporal-context initiative: the rolling pitch window
is itself a lightweight temporal structure, independent of chord boundaries.

## Voice-leading direction

A smaller detail: temporal direction can inform isolated-note spelling, sharps
for ascending motion and flats for descending. Low priority next to the
fifths-window heuristic, which subsumes much of it.

## Ground truth

When-in-Rome fixtures derive from scores with real spelled pitches, which makes
spelling accuracy directly measurable, an unusually clean ground truth compared
to the label-mapping problems on the identity side.
