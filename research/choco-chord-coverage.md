# Chord Coverage From ChoCo

WhatChord's chord analyzer is built around a practical question: when a musician
plays a voicing, what name would they expect to see? That is not quite the same
thing as enumerating every possible pitch-class set. A chord label is a musical
judgment, and the useful labels are the ones that appear often enough in real
music to be worth recognizing, ranking, and explaining well.

In May 2026, we checked that assumption against the [ChoCo chord corpus][choco].
The goal was not to train WhatChord from the corpus or import corpus-specific
behavior into the app. The goal was simpler:

- find which chord labels appear in a large public collection of real chord
  annotations;
- compare those labels with the chord families WhatChord already supports;
- identify missing labels that appear often enough to deserve implementation
  priority.

## Source Material

[ChoCo][choco] is a large linked-data chord corpus that gathers annotations from
many existing datasets and formats, including Isophonics, RWC Pop, Weimar Jazz,
USPop2002, Wikifonia, iReal Pro, and others. The project distributes
[JAMS][jams-chord] files and conversion tools so chord annotations can be
queried in a common format.

For this pass, we used ChoCo's converted JAMS files:

```text
partitions/*/choco/jams-converted/*.jams
```

Those files expose converted [Harte-style][harte] chord labels under JAMS
annotations. That matters because the original corpora do not all use the same
notation. Harte syntax gives us one common surface language for labels such as:

```text
C:maj
D:min7
G:7(b9)
F#:hdim7
Bb:(3,5,b7,9,#11)
```

JAMS is only the container format. The chord observations themselves live in
annotation records whose namespace is `chord` or `chord_harte`, with each
observation carrying a `value`, `time`, and `duration`.

## Method

The extraction script lives in
[`tool/choco/chord_label_stats.py`](../tool/choco/chord_label_stats.py).

The command used for this snapshot was:

```sh
python3 tool/choco/chord_label_stats.py /private/tmp/choco --jams-version converted --top 50
```

The script:

1. Reads every converted ChoCo JAMS file.
2. Extracts `chord` and `chord_harte` annotation values.
3. Ignores `N`, `X`, and empty labels because those mean no chord or unknown
   harmony, not a chord quality WhatChord should name.
4. Removes the root from each label, so `C:maj`, `Eb:maj`, and `F#:maj` count as
   the same chord body: `maj`.
5. Expands Harte shorthands and explicit degree lists into degree sets.
6. Applies Harte omission markers such as `*5`, which indicate an omitted tone.
7. Compares each degree set with WhatChord's current chord templates plus the
   extensions WhatChord already models.

The comparison is intentionally about chord bodies, not root spellings.
WhatChord already has separate logic for enharmonic spelling; this research pass
is about quality coverage.

The script writes CSV reports to:

```text
build/choco-stats/choco_chord_bodies.csv
build/choco-stats/choco_chord_labels.csv
build/choco-stats/choco_unsupported_bodies.csv
```

## Snapshot Results

The converted ChoCo snapshot contained:

| Measure                                  | Count     |
| ---------------------------------------- | --------- |
| Converted JAMS files scanned             | 16,249    |
| Non-`N`/`X` chord observations           | 1,097,701 |
| Distinct full chord labels               | 4,798     |
| Distinct chord bodies after root removal | 350       |

Against WhatChord's current templates and extensions:

| Coverage basis | Covered   | Unsupported | Coverage |
| -------------- | --------- | ----------- | -------- |
| Observations   | 1,085,031 | 12,670      | 98.85%   |
| Duration       | 3,082,437 | 37,074      | 98.81%   |

That is the important result: most of the chord language that appears in this
large, mixed real-music corpus is already inside WhatChord's present recognition
surface.

## Most Common Chord Bodies

The highest-frequency bodies were unsurprising and useful as a sanity check:

| Body               | Observations | WhatChord status |
| ------------------ | -----------: | ---------------- |
| `maj`              |      375,189 | supported        |
| `7`                |      169,546 | supported        |
| `min`              |      123,885 | supported        |
| `min7`             |       71,362 | supported        |
| `(3,5,b7)`         |       65,666 | supported        |
| `min(b7)`          |       45,260 | supported        |
| `maj7`             |       40,493 | supported        |
| `dim`              |       24,612 | supported        |
| `9`                |       15,367 | supported        |
| `(3,5,b7,9)`       |       14,565 | supported        |
| `maj6`             |       13,636 | supported        |
| `(3,5,6)`          |       10,261 | supported        |
| `dim7`             |        8,083 | supported        |
| `min6`             |        6,253 | supported        |
| `(3,5,b7,9,11,13)` |        6,145 | supported        |
| `7(b9)`            |        6,131 | supported        |

Some labels appear in shorthand form, while others appear as explicit Harte
degree lists. For example, `7`, `(3,5,b7)`, and some `maj(b7)` forms describe
the same practical dominant-seventh material. The script preserves the original
body in the report but classifies by expanded degree set.

## Unsupported Labels

The largest unsupported bodies were not strong candidates for new chord-quality
support:

| Body        | Observations | Interpreted degree set | Notes                   |
| ----------- | -----------: | ---------------------- | ----------------------- |
| `(*3,*5)`   |        6,008 | empty                  | omitted third and fifth |
| `(*3,5)`    |        1,595 | `5`                    | fifth-only sonority     |
| `(5)`       |          710 | `5`                    | fifth-only sonority     |
| `(1,*3,*5)` |          623 | `1`                    | root-only sonority      |

These labels are useful in corpus annotation, but they do not map cleanly to
full chord identities. They fit WhatChord's existing design choice to report
dyads as intervals rather than promote them into chord templates, and they are
not evidence that WhatChord is missing a mainstream chord family.

The first unsupported bodies that look more like candidate chord qualities were
much rarer:

| Body          | Observations | Possible interpretation                             |
| ------------- | -----------: | --------------------------------------------------- |
| `(b3,#5)`     |          225 | minor sharp-five triad shell                        |
| `min(#5)`     |          159 | minor sharp-five                                    |
| `min(#5,*5)`  |          147 | minor sharp-five with omitted natural fifth         |
| `(b3,#5,b7)`  |          107 | minor seventh sharp-five                            |
| `min7(#5,*5)` |           81 | minor seventh sharp-five with omitted natural fifth |

Those are real labels, but they are far below the dominant, major, minor,
suspended, diminished, augmented, sixth, seventh, and altered-dominant material
WhatChord already handles.

## What This Suggests

The main conclusion is conservative: WhatChord should not add a large new set of
chord families just because a long tail exists in the corpus. The current engine
covers the overwhelming majority of observed real-corpus chord annotations by
count and by duration.

Priority recommendations:

1. Keep improving ranking, spelling, and explanations for the supported
   high-frequency families. That work affects the most real music.
2. Do not re-add `power5` as a chord template based on this corpus result.
   WhatChord previously supported a power-fifth chord, but removed it because it
   created poor ranking behavior for a piano-focused app. The current design is
   deliberate: dyads are reported as intervals, while chord identities start at
   triads and above.
3. Track minor sharp-five and minor-seventh sharp-five as low-priority candidate
   qualities. They appear in real annotations, but not often enough to displace
   higher-impact work.
4. Treat double-flat-third, double-flat-seventh, and highly chromatic explicit
   degree sets as notation edge cases unless a clear user-facing need appears.

## Limitations

This pass measures label coverage, not analyzer output accuracy. A supported
degree set only means WhatChord has the vocabulary to name the chord; it does
not prove that every voicing in the corpus would be ranked identically by the
live analyzer.

The corpus also mixes audio annotations, score-derived annotations, lead-sheet
sources, and converted symbolic formats. ChoCo's normalization is exactly what
makes this kind of broad query possible, but converted labels can still encode
source-specific conventions such as omission markers.

Finally, a corpus is not a product spec. WhatChord is an interactive MIDI tool,
not an offline chord-transcription benchmark. The corpus is best used as a
reality check: it helps keep the recognition roadmap grounded in music people
actually annotate and play.

## Reproducing

Clone ChoCo outside the repository:

```sh
git clone --depth 1 https://github.com/smashub/choco.git /private/tmp/choco
```

Run the report:

```sh
python3 tool/choco/chord_label_stats.py /private/tmp/choco --jams-version converted --top 50
```

If you use `mise`, `mise run research:choco-coverage` runs the same pass and
reads `/private/tmp/choco` by default (override with `CHOCO_ROOT`).

Inspect:

```text
build/choco-stats/choco_chord_bodies.csv
build/choco-stats/choco_unsupported_bodies.csv
```

[choco]: https://github.com/smashub/choco
[jams-chord]: https://jams.readthedocs.io/en/stable/namespaces/chord.html
[harte]: https://ismir2005.ismir.net/proceedings/1080.pdf
