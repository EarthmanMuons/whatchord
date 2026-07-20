import 'package:test/test.dart';
import 'package:whatchord/whatchord.dart';

void main() {
  test('paper profile preserves pre-release altered-color pricing', () {
    const midiNotes = [38, 49, 53, 57, 60];
    const tonality = Tonality(Tonic.c, TonalityMode.major);
    final keySignature = KeySignature.fromTonality(tonality);
    final context = AnalysisContext(
      tonality: tonality,
      keySignature: keySignature,
      spellingPolicy: NoteSpellingPolicy(
        preferFlats: keySignature.prefersFlats,
      ),
    );
    var pcMask = 0;
    for (final note in midiNotes) {
      pcMask |= 1 << (note % 12);
    }
    final input = ChordInput(
      pcMask: pcMask,
      bassPc: midiNotes.first % 12,
      noteCount: midiNotes.length,
    );
    final voicing = ObservedVoicing.fromMidi(midiNotes);

    final current = ChordAnalyzer().analyze(
      input,
      context: context,
      voicing: voicing,
    );
    final historical = ChordAnalyzer(
      analysisProfile: ChordAnalysisProfile.whatKeyPaper2026,
    ).analyze(input, context: context, voicing: voicing);

    expect(current.first.identity.quality, ChordQuality.minor7);
    expect(current.first.identity.rootPc, 2);
    expect(historical.first.identity.quality, ChordQuality.major7Sharp5);
    expect(historical.first.identity.rootPc, 1);
  });
}
