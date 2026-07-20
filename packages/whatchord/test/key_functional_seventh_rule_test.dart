import 'package:test/test.dart';
import 'package:whatchord/whatchord.dart';

// Pins the decided policy for the m7/6 pitch-identity family
// (research/chord-context/log/2026-07-20-01-m7-6-policy.md): the relative
// seventh reading wins only in the genre-agreed key-functional cells; the
// sixth-chord reading stands everywhere else, including the borrowed
// major-key iiø65 (heard as IVm6) and tonic sixths.

void main() {
  final analyzer = ChordAnalyzer();

  AnalysisContext context(String tonic, TonalityMode mode) {
    final tonality = Tonality(Tonic.values.byName(tonic), mode);
    final keySignature = KeySignature.fromTonality(tonality);
    return AnalysisContext(
      tonality: tonality,
      keySignature: keySignature,
      spellingPolicy: NoteSpellingPolicy(
        preferFlats: keySignature.prefersFlats,
      ),
    );
  }

  ChordIdentity top(List<int> midiNotes, AnalysisContext context) {
    var pcMask = 0;
    for (final note in midiNotes) {
      pcMask |= 1 << (note % 12);
    }
    final ranked = analyzer.analyze(
      ChordInput(
        pcMask: pcMask,
        bassPc: midiNotes.first % 12,
        noteCount: midiNotes.length,
      ),
      context: context,
      voicing: ObservedVoicing.fromMidi(midiNotes),
    );
    return ranked.first.identity;
  }

  // {F A C D} with F bass: F6 vs Dm7/F.
  const ii65Voicing = [53, 57, 60, 62];
  // {F Ab C D} with F bass: Fm6 vs Dm7b5/F.
  const halfDimVoicing = [53, 56, 60, 62];

  group('minor7 twin on degree ii', () {
    test('wins in major', () {
      final identity = top(ii65Voicing, context('c', TonalityMode.major));
      expect(identity.quality, ChordQuality.minor7);
      expect(identity.rootPc, 2);
      expect(identity.bassPc, 5);
    });

    test('wins in minor', () {
      // {Bb D F G} in F minor: Gm7/Bb over Bb6, ii of F.
      final identity = top([58, 62, 65, 67], context('f', TonalityMode.minor));
      expect(identity.quality, ChordQuality.minor7);
      expect(identity.rootPc, 7);
    });

    test('stays a tonic sixth when the sixth root is the tonic', () {
      final identity = top(ii65Voicing, context('f', TonalityMode.major));
      expect(identity.quality, ChordQuality.major6);
      expect(identity.rootPc, 5);
    });

    test('root-position minor7 is unaffected', () {
      final identity = top([50, 53, 57, 60], context('c', TonalityMode.major));
      expect(identity.quality, ChordQuality.minor7);
      expect(identity.rootPc, 2);
      expect(identity.bassPc, 2);
    });
  });

  group('halfDiminished7 twin', () {
    test('wins on degree ii in minor', () {
      final identity = top(halfDimVoicing, context('c', TonalityMode.minor));
      expect(identity.quality, ChordQuality.halfDiminished7);
      expect(identity.rootPc, 2);
      expect(identity.bassPc, 5);
    });

    test('wins in higher inversions in minor', () {
      // {Ab C D F} in C minor: Dm7b5/Ab over Fm6/Ab.
      final identity = top([56, 60, 62, 65], context('c', TonalityMode.minor));
      expect(identity.quality, ChordQuality.halfDiminished7);
      expect(identity.rootPc, 2);
      expect(identity.bassPc, 8);
    });

    test('wins on the leading tone in major', () {
      // {D F A B} in C major: Bm7b5/D over Dm6.
      final identity = top([50, 53, 57, 59], context('c', TonalityMode.major));
      expect(identity.quality, ChordQuality.halfDiminished7);
      expect(identity.rootPc, 11);
    });

    test('borrowed major-key iiø65 stays the minor sixth', () {
      final identity = top(halfDimVoicing, context('c', TonalityMode.major));
      expect(identity.quality, ChordQuality.minor6);
      expect(identity.rootPc, 5);
    });
  });

  test('unrelated keys leave the sixth reading in place', () {
    // {F A C D} in B major: neither degree condition holds.
    final identity = top(ii65Voicing, context('b', TonalityMode.major));
    expect(identity.quality, ChordQuality.major6);
    expect(identity.rootPc, 5);
  });

  test('WhatKey paper profile preserves the v2026.7.14 sixth-chord choice', () {
    final historicalAnalyzer = ChordAnalyzer(
      analysisProfile: ChordAnalysisProfile.whatKeyPaper2026,
    );
    var pcMask = 0;
    for (final note in ii65Voicing) {
      pcMask |= 1 << (note % 12);
    }
    final ranked = historicalAnalyzer.analyze(
      ChordInput(
        pcMask: pcMask,
        bassPc: ii65Voicing.first % 12,
        noteCount: ii65Voicing.length,
      ),
      context: context('c', TonalityMode.major),
      voicing: ObservedVoicing.fromMidi(ii65Voicing),
    );

    expect(ranked.first.identity.quality, ChordQuality.major6);
    expect(ranked.first.identity.rootPc, 5);
  });
}
