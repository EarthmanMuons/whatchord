import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/theory/domain/analysis/voicing_evidence.dart';
import 'package:whatchord/features/theory/theory.dart';

import 'helpers/theory_test_helpers.dart';

void main() {
  setUp(ChordAnalyzer.clearCache);

  // D A C E G: an Am7 (A C E G) over a D bass. Pitch-class-only, the engine
  // reads this as a root-position D9sus4; an isolated D below the Am7 says it is
  // really Am7/D.
  final input = chordInputFromNames(
    names: ['D', 'A', 'C', 'E', 'G'],
    bass: 'D',
  );
  final context = makeAnalysisContext();

  ChordCandidate? firstWhere(
    List<ChordCandidate> candidates,
    bool Function(ChordCandidate) test,
  ) => candidates.where(test).firstOrNull;

  group('voicing evidence', () {
    test('pitch-class-only analysis keeps the conventional D9sus4', () {
      final results = ChordAnalyzer.analyze(input, context: context);

      expect(results.first.identity.rootPc, pc('D'));
      expect(results.first.identity.quality, ChordQualityToken.dominant7sus4);
    });

    test('an isolated bass below a complete upper chord promotes Am7/D', () {
      // D2 A2 C3 E3 G3: D sits a fifth below the Am7 stacked above it.
      final voicing = ObservedVoicing.fromMidi([38, 45, 48, 52, 55]);

      final results = ChordAnalyzer.analyze(
        input,
        context: context,
        voicing: voicing,
      );

      expect(results.first.identity.rootPc, pc('A'));
      expect(results.first.identity.quality, ChordQualityToken.minor7);
      expect(results.first.identity.hasSlashBass, isTrue);
      expect(results.first.identity.bassPc, pc('D'));

      // The displaced conventional reading stays a visible near-tie alternative.
      final alternatives = ChordCandidateRanking.nearTieAlternatives(results);
      expect(
        firstWhere(
          alternatives,
          (c) =>
              c.identity.rootPc == pc('D') &&
              c.identity.quality == ChordQualityToken.dominant7sus4,
        ),
        isNotNull,
      );
    });

    test('the promotion is tagged as a voicing-driven decision', () {
      final voicing = ObservedVoicing.fromMidi([38, 45, 48, 52, 55]);

      final debug = ChordAnalyzer.analyzeDebug(
        input,
        context: context,
        voicing: voicing,
      );

      expect(debug.first.candidate.identity.rootPc, pc('A'));
      expect(debug[1].vsPrevious?.decidedByVoicing, isTrue);
    });

    test('a compact voicing without an isolated bass does not promote', () {
      // D4 E4 G4 A4 C5: the bass is one step below its neighbor, no isolation.
      final voicing = ObservedVoicing.fromMidi([62, 64, 67, 69, 72]);

      final results = ChordAnalyzer.analyze(
        input,
        context: context,
        voicing: voicing,
      );

      expect(results.first.identity.rootPc, pc('D'));
      expect(results.first.identity.quality, ChordQualityToken.dominant7sus4);
    });

    test('synthesized registers do not promote the slash reading', () {
      // Bass-first order is known, but the octaves were synthesized, so the
      // isolation that distinguishes Am7/D is not available.
      final voicing = ObservedVoicing.fromOrder([
        pc('D'),
        pc('A'),
        pc('C'),
        pc('E'),
        pc('G'),
      ]);

      final results = ChordAnalyzer.analyze(
        input,
        context: context,
        voicing: voicing,
      );

      expect(results.first.identity.rootPc, pc('D'));
      expect(results.first.identity.quality, ChordQualityToken.dominant7sus4);
    });
  });

  group('ObservedVoicing', () {
    test('fewer than two notes is inert', () {
      expect(ObservedVoicing.fromMidi(const []).isInert, isTrue);
      expect(ObservedVoicing.fromMidi(const [60]).isInert, isTrue);
      expect(ObservedVoicing.fromMidi(const [60, 64]).isInert, isFalse);
    });

    test('sorts notes and reports bass gap and span', () {
      final voicing = ObservedVoicing.fromMidi([52, 38, 45]);
      expect(voicing.midiNotes, [38, 45, 52]);
      expect(voicing.bassMidi, 38);
      expect(voicing.bassGap, 7);
      expect(voicing.span, 14);
    });

    test('fromOrder keeps bass-first order and pitch classes', () {
      final voicing = ObservedVoicing.fromOrder([2, 9, 0, 4, 7]); // D A C E G
      expect(voicing.hasExactRegisters, isFalse);
      expect([for (final m in voicing.midiNotes) m % 12], [2, 9, 0, 4, 7]);
      for (var i = 1; i < voicing.midiNotes.length; i++) {
        expect(voicing.midiNotes[i] > voicing.midiNotes[i - 1], isTrue);
      }
    });

    test('register and provenance change the signature', () {
      final a = ObservedVoicing.fromMidi([38, 45, 48]);
      final b = ObservedVoicing.fromMidi([50, 57, 60]);
      final c = ObservedVoicing.fromOrder([2, 9, 0]);
      expect(a.hasExactRegisters, isTrue);
      expect(c.hasExactRegisters, isFalse);
      expect(a.signature == b.signature, isFalse);
      expect(a.signature == c.signature, isFalse);
    });
  });

  group('VoicingEvidence.supportsUpperStructureSlash guards', () {
    const identity = ChordIdentity(
      rootPc: 9,
      bassPc: 2,
      quality: ChordQualityToken.minor7,
      presentIntervalsMask: 0,
    );

    test('inert voicing is never an upper structure', () {
      expect(
        VoicingEvidence.supportsUpperStructureSlash(
          identity,
          ObservedVoicing.inert,
        ),
        isFalse,
      );
    });

    test('synthesized registers are never an upper structure', () {
      final voicing = ObservedVoicing.fromOrder([2, 9, 0, 4, 7]);
      expect(
        VoicingEvidence.supportsUpperStructureSlash(identity, voicing),
        isFalse,
      );
    });
  });
}
