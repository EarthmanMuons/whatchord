# 2026-07-20: Rootless ensemble mode at corpus scale

**Goal.** Replace the 18-case gate's feasibility signal (entry 2026-07-20-16)
with a corpus-scale accuracy estimate: if an explicit ensemble mode existed, how
accurately would it name rootless voicings across thousands of real chords?

**Setup.** Every DCML development event whose expected identity is a seventh
chord (guide tones present) with its root actually sounding has its root pitch
class stripped from the real voicing, simulating a bassist covering the root
while the pianist plays the rest. The stripped voicing is scored three ways
against the known identity:

- `current`: the shipped engine's top-1 (no ensemble mode).
- ensemble under the annotated key: the missing-root hypothesis set (guide tones
  required, legal colors, root absent) filtered to diatonic roots; outcome is
  unique-correct, ambiguous (multiple diatonic ghost roots, one correct), or
  miss. The oracle ceiling.
- ensemble under the closed-loop inferred key: the realistic product number,
  across all three key-behavior presets.

Symmetric diminished sevenths are excluded (a rootless dim7 has four equal
roots). This synthesizes rootless voicings from real classical seventh chords:
the mechanism test is genre-independent, but the quality mix is classical (plain
dom7/maj7/min7 dominate; fewer altered jazz extensions), so a true jazz-comping
corpus would be a richer follow-up.

```sh
for mode in stable balanced reactive; do
  dart run tool/chord-context/rootless_corpus.dart \
    --fixtures build/chord-context/fixtures/dcml-distant-listening-v1-span \
    --labels build/chord-context/labels/dcml-distant-listening-v1-span.labels.json \
    --split-file research/chord-context/data/splits/dcml-distant-listening-v1.json \
    --split development --behavior $mode --out build/chord-context/rootless/dcml-dev-$mode
done
```

**What happened.** 13,197 eligible seventh-chord events (1,000x the gate suite).

- **Current engine: 0.0% exact.** At scale, the shipped engine names essentially
  none of them right, confirming the gate's severity finding on thousands of
  cases: with the root stripped, the remaining tones form some other complete,
  cheaper chord.
- **Ensemble mode, annotated-key ceiling: 89.2% unique-correct** (11,777 /
  13,197), 6.9% ambiguous, 3.9% miss. Ghost roots plus a diatonic key filter
  alone name nine in ten correctly and uniquely.
- **Ensemble mode, inferred-key (realistic): 81.9% unique-correct** under
  stable, rising with the local-key-leaning presets to 82.4% (balanced) and
  83.1% (reactive), directly reflecting their better local-key tracking (entry
  -18). Plus ~11% ambiguous where the correct reading survives the filter
  alongside a competitor.
- **Tiebreak headroom: 93.0%.** Unique-correct plus ambiguous under the inferred
  key, i.e. the ceiling if the guide-tone and dominant-color weighting
  (rootless-voicings-notes item 3) resolves the ambiguous bucket. That bucket is
  dominated by dominant7 (625) and halfDiminished7 (585), exactly the readings a
  dominant-color preference is designed to settle.

**Plain-English reading.** With an ensemble toggle turned on, naming a rootless
voicing comes down to: which absent root, when reinstated, gives a chord that
fits the key? On thirteen thousand real seventh chords that question has a
single diatonic answer about 82% of the time using the key the app infers on its
own, and about 89% with a perfect key. Another tenth have two plausible answers
where the right one is present, and those are the
dominant-versus-half-diminished cases a standard jazz weighting settles, so the
realistic reachable accuracy is around 90%. The current app gets zero of these,
so the mode would move naming on comping voicings from useless to roughly
nine-in-ten. Better local-key tracking helps directly, which is why the reactive
preset scores highest here.

**Universality check (would the tiebreak help in solo mode too?).** No, and that
is a good property. The guide-tone/dominant-color tiebreak resolves which ABSENT
root to reinstate, an ambiguity that exists only when the root is missing. With
the root present it is the bass and the cost anchor, so the same sonorities are
already named correctly: of the 1,344 rooted clean-pool misses, exactly 2
involve a dominant-family quality (both the dominant7-sharp-5-vs-augmented
edge), and the rest are the m7/6 family already fixed by lever 0. Spot-checks
confirm the engine already names rooted C13, Dm9, G9, C7#9, and Dm7b5 correctly
with no tiebreak. So the tiebreak has essentially zero addressable headroom in
solo mode; its value is confined to ensemble mode, which means adding it cannot
regress shipped solo-mode naming. It is a self-contained ensemble component, not
a global ranking change.

**Decisions.**

- Track D now has a corpus-scale accuracy estimate, not just feasibility: ~82%
  exact today under the app's own key, ~90% reachable with the guide-tone
  tiebreak, against 0% without the mode. This is the number to weigh a jazz
  ensemble mode against.
- The explicit mode remains mandatory (gate entry -16: 6/6 solo cases admit a
  ghost-root competitor, so auto-detection is impossible); this measurement
  assumes the mode is on.
- The implementation stack is confirmed and now sized: ghost-root templates
  (reaches the identity), diatonic key filter (unique 82-89%),
  guide-tone/dominant-color weighting (recovers the ambiguous ~11% toward ~93%).
  No engine work authorized; this is decision support for the product call.
- Honest scope limit recorded: the chord distribution is classical. The numbers
  should hold or improve on jazz repertoire (richer tensions give more
  guide-tone constraints), but a real jazz-comping corpus would confirm it; none
  is pinned in the repo today.

**Next.**

- Product decision on Track D with the ~82-90% estimate in hand.
- If pursued, the guide-tone/dominant-color tiebreak is the one component still
  only estimated (via the ambiguous bucket); it would be built and measured
  against this same synthesis before shipping.
