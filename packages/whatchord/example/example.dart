/// Tour of the whatchord engine: name a voicing, surface the alternatives,
/// explain the ranking, build a chord from a spec, and harmonize a scale.
///
/// Run with: dart run example/example.dart
library;

import 'package:whatchord/whatchord.dart';

void main() {
  final context = contextForKey(const Tonality(Tonic.c, TonalityMode.major));

  // --- Name a voicing -------------------------------------------------------
  // Analysis works on pitch classes: which of the twelve notes are sounding,
  // which one is in the bass, and how many notes are held.
  // C E G A reads as C6 or as Am7 over C; the engine weighs both.
  final input = inputFromNames(['C', 'E', 'G', 'A']);
  final candidates = ChordAnalyzer.analyze(input, context: context);

  final top = present(candidates.first, context);
  print('symbol:   ${chordSymbolTextLabel(top.symbol)}');
  print('spoken:   ${top.spokenLabel}');
  print('academic: ${top.longLabel}');
  print('members:  ${top.members.join(' ')} (${top.memberDegrees.join(' ')})');
  print('degree:   ${top.scaleDegreeAnalysis?.romanNumeral} in C major');

  // --- Alternatives ----------------------------------------------------------
  // Readings priced close to the winner are worth showing to a musician.
  final alternatives = ChordCandidateRanking.alternatives(candidates);
  for (final alt in alternatives) {
    print('also:     ${chordSymbolTextLabel(present(alt, context).symbol)}');
  }

  // --- Explain the ranking ---------------------------------------------------
  // explain() returns the same ranking with each candidate's cost breakdown
  // and the rule that ordered it against the previous one.
  final explained = ChordAnalyzer.explain(input, context: context);
  print('\nwhy ${chordSymbolTextLabel(top.symbol)} wins:');
  for (final reason in explained.first.costReasons) {
    print('  $reason');
  }
  final runnerUp = explained[1];
  print('vs next:  ${runnerUp.vsPrevious?.decidedByRule ?? 'cost'}');

  // --- Build a chord from a spec ---------------------------------------------
  // The construction API answers the inverse question: given a selected
  // root, quality, and extensions, produce a canonical example.
  final construction = ChordConstruction(
    rootPc: Tonic.d.pitchClass,
    quality: ChordQualityToken.minor7,
    extensions: {ChordExtension.eleven},
    bassPc: Tonic.d.pitchClass,
  );
  final example = ChordExampleBuilder.build(
    state: construction,
    tonality: context.tonality,
    notation: ChordNotationStyle.textual,
  );
  print('\nbuilt:    ${chordSymbolTextLabel(example.presentation.symbol)}');
  print('voicing:  MIDI ${example.normalizedVoicing.join(' ')}');

  // --- Harmonize a scale -----------------------------------------------------
  const ebMajor = Tonality(Tonic.eFlat, TonalityMode.major);
  final harmony = ScaleHarmonizer.harmonize(
    const Scale(Tonic.eFlat, ScaleKind.major),
  );
  final degrees = [
    for (final degree in harmony.degrees)
      '${degree.triadRoman}=${triadSymbol(degree, ebMajor)}',
  ];
  print('\nEb major: ${degrees.join(' ')}');
}

/// Analysis context for a key: its signature decides enharmonic spelling.
AnalysisContext contextForKey(Tonality tonality) {
  final keySignature = KeySignature.fromTonality(tonality);
  return AnalysisContext(
    tonality: tonality,
    keySignature: keySignature,
    spellingPolicy: NoteSpellingPolicy(preferFlats: keySignature.prefersFlats),
  );
}

/// Builds a [ChordInput] from note names; the first name is the bass.
ChordInput inputFromNames(List<String> names) {
  final pcs = [for (final name in names) pitchClassFromNoteName(name)];
  var mask = 0;
  for (final pc in pcs) {
    mask |= 1 << pc;
  }
  return ChordInput(pcMask: mask, bassPc: pcs.first, noteCount: pcs.length);
}

/// The textual triad symbol for a harmonized scale degree (e.g. "Fm").
String triadSymbol(ScaleDegreeHarmony degree, Tonality tonality) {
  return scaleDegreeChordSymbol(
    degree: degree,
    showSevenths: false,
    tonality: tonality,
    notation: ChordNotationStyle.textual,
    noteNameSystem: NoteNameSystem.international,
  );
}

/// Renders [candidate] for display in the key of [context].
ChordPresentation present(ChordCandidate candidate, AnalysisContext context) {
  return ChordPresentationBuilder.fromIdentity(
    identity: candidate.identity,
    tonality: context.tonality,
    notation: ChordNotationStyle.textual,
  );
}
