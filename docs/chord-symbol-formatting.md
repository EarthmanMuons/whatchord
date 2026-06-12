# Chord Symbol Formatting

WhatChord formats chord symbols as concise names for the detected harmonic
identity, not as exhaustive inventories of the notes being played. The defaults
favor common lead-sheet usage, readable symbols, and consistent meaning across
Analysis and Explore.

## Symbol Structure

A symbol has three parts:

```text
root + quality and extensions + optional slash bass
```

Examples include `C`, `Cm7`, `C13♭9`, and `Cmaj7 / E`.

The root and bass are spelled in the current tonal context. The middle portion
is formatted from the identified chord quality and extensions, so notation and
spelling preferences change its presentation without changing the underlying
analysis.

WhatChord offers two compact notation styles:

- Textual notation uses labels such as `m`, `maj7`, `dim`, and `aug`.
- Symbolic notation uses labels such as `−`, `Δ7`, `°`, and `+`.

The examples below use textual notation unless a distinction matters.

## Headline Extensions

The highest eligible natural extension becomes the symbol's headline on
seventh-family chords:

- `C7` with a 9th becomes `C9`.
- `Cm7` with a supported 11th becomes `Cm11`.
- `Cmaj7` with a supported 13th becomes `Cmaj13`.
- `C7sus4` with a supported 9th becomes `C9sus4`.

A headline communicates a stacked extension. It absorbs lower natural extensions
that the headline conventionally implies:

- `11` implies a 9th.
- `13` implies a 9th, but does not require or imply a sounding natural 11th.

Alterations remain explicit, so a dominant 13th with a flat 9th and sharp 11th
is `C13(♭9,♯11)`.

Fully diminished seventh chords are an exception. Natural upper tones are shown
as added tones, such as `Cdim7(add9)`, rather than promoted headlines.

## Extensions vs. Added Tones

WhatChord distinguishes a stacked extension from a tone added outside that
stack:

- A natural 9th is `9` when supported by a seventh; otherwise it is `add9`.
- A natural 11th is `11` when supported by a seventh and some form of 9th;
  otherwise it is `add11`.
- A natural 13th is `13` when supported by a seventh and some form of 9th;
  otherwise it is `add13`.

The supporting 9th may be natural or altered. For example, a dominant chord with
a sharp 9th, sharp 11th, and natural 13th can headline as `C13(♯9,♯11)`.

Sixth chords use the conventional `6/9` spelling when an added 9th is present.

### Why Not `add2` or `add4`?

Chord symbols describe harmonic function more than register. A D added to a C
triad serves as the ninth whether it is voiced next to the root or an octave
above it; the same principle makes F an added eleventh. WhatChord therefore uses
`add9` and `add11` consistently instead of changing the name to `add2` or `add4`
based on voicing.

`sus2` and `sus4` remain distinct because they describe replacement of the
third, not merely an added tone.

## Alterations

Altered upper extensions are written explicitly: `♭9`, `♯9`, `♯11`, and `♭13`.
When a triad has an altered ninth without the harmonic support for a stacked
extension, WhatChord can use `add♭9` or `add♯9`.

Altered fifths that define the base quality stay in its conventional quality
label, including any parentheses, such as `C7♭5`, `Cmaj7♯5`, or `Cm7(♭5)`.

Modifiers are ordered consistently by musical degree: ninths, elevenths, then
thirteenths, with alterations placed alongside their degree.

## Parentheses

Parentheses group modifiers when grouping improves readability:

- Multiple modifiers are grouped: `C7(♭9,♯11)`.
- Added tones on seventh-family chords are grouped: `C7(add13)`.
- Modifiers on suspended seventh-family chords are grouped to avoid ambiguous
  strings such as `7sus49`.
- Diminished seventh additions are grouped: `Cdim7(add9)`.

A single ordinary modifier is normally inline: `C7♭9`, `C13♯11`, or `Cadd♯9`.
Added tones on triad-like chords also remain inline because `add` already makes
their role clear: `Cadd9`, `Cmadd11`, or `Caugadd13`.

Textual notation separates grouped modifiers with commas. Symbolic notation uses
compact accidental symbols and no commas.

## Omissions

WhatChord does not print `no5`, `omit3`, or similar omission markers.

Omissions are properties of a particular voicing, while the displayed symbol
names the best-supported harmonic identity. Commonly omitted tones, especially
perfect fifths in extended chords, are accounted for during analysis without
turning the result into a performance instruction. Structurally weak readings
that omit important tones are penalized or rejected when candidates are ranked.

This keeps symbols concise and avoids implying that a player should omit a tone
merely because it was absent from the observed voicing. Note membership and
analysis details provide the literal information when it is needed.

## Slash Bass

A non-root bass is appended after a slash, as in `Cmaj7 / E`. The spaces around
the slash distinguish bass notation from the compact `6/9` quality.

The formatter removes an added-tone label when the slash bass already supplies
that same tone. For example, it prefers `A♭7 / D♭` over the redundant
`A♭7(add11) / D♭`. Similarly, a seventh chord whose only 9th is supplied by the
slash bass is shown as `C7 / D`, not `C9 / D`.

## Analysis vs. Explore

Analysis names the observed voicing and ranks plausible identities. Explore
builds clear, canonical examples of a selected symbol. They share the same
symbol formatter, but their note-selection goals differ:

- Analysis may recognize a conventional chord even when an omittable tone is
  absent.
- Explore supplies the implied members of a headline extension so its example
  clearly demonstrates the selected symbol.
