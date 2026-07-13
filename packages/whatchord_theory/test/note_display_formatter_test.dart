import 'package:test/test.dart';

import 'package:whatchord_theory/whatchord_theory.dart';

void main() {
  group('noteDisplayLabel', () {
    test('converts canonical ASCII note accidentals for UI', () {
      expect(noteDisplayLabel('Bb'), 'B♭');
      expect(noteDisplayLabel('F#'), 'F♯');
      expect(noteDisplayLabel('Abb'), 'A𝄫');
      expect(noteDisplayLabel('Fx'), 'F𝄪');
    });

    test('supports German note names', () {
      expect(noteDisplayLabel('B', noteNameSystem: NoteNameSystem.german), 'H');
      expect(
        noteDisplayLabel('Bb', noteNameSystem: NoteNameSystem.german),
        'B',
      );
      expect(
        noteDisplayLabel('F#', noteNameSystem: NoteNameSystem.german),
        'Fis',
      );
      expect(
        noteDisplayLabel('Eb', noteNameSystem: NoteNameSystem.german),
        'Es',
      );
    });

    test('supports fixed-Do note names', () {
      expect(
        noteDisplayLabel('C', noteNameSystem: NoteNameSystem.fixedDo),
        'Do',
      );
      expect(
        noteDisplayLabel('F#', noteNameSystem: NoteNameSystem.fixedDo),
        'Fa♯',
      );
      expect(
        noteDisplayLabel('Bb', noteNameSystem: NoteNameSystem.fixedDo),
        'Si♭',
      );
    });
  });

  group('theoryTokenDisplayLabel', () {
    test('converts canonical ASCII role and quality tokens for UI', () {
      expect(theoryTokenDisplayLabel('b9'), '♭9');
      expect(theoryTokenDisplayLabel('#11'), '♯11');
      expect(theoryTokenDisplayLabel('bb7'), '𝄫7');
      expect(theoryTokenDisplayLabel('m7(b5)'), 'm7(♭5)');
    });
  });

  group('NoteLongFormFormatter', () {
    test('spells notes in plain English', () {
      expect(NoteLongFormFormatter.format('C'), 'C natural');
      expect(NoteLongFormFormatter.format('Bb'), 'B flat');
      expect(NoteLongFormFormatter.format('F#'), 'F sharp');
      expect(NoteLongFormFormatter.format('Abb'), 'A double flat');
      expect(NoteLongFormFormatter.format('Fx'), 'F double sharp');
    });

    test('spells fixed-Do note names for semantics', () {
      expect(
        NoteLongFormFormatter.format(
          'F#',
          noteNameSystem: NoteNameSystem.fixedDo,
        ),
        'Fa sharp',
      );
    });

    test('spells German note names through a dedicated semantic path', () {
      expect(
        NoteLongFormFormatter.format(
          'F#',
          noteNameSystem: NoteNameSystem.german,
        ),
        'Fis',
      );
      expect(
        NoteLongFormFormatter.format(
          'Bb',
          noteNameSystem: NoteNameSystem.german,
        ),
        'B',
      );
    });
  });

  group('tonalityDisplayLabel', () {
    test('uses German Dur and Moll key names', () {
      expect(
        tonalityDisplayLabel(
          const Tonality(Tonic.fSharp, TonalityMode.major),
          noteNameSystem: NoteNameSystem.german,
        ),
        'Fis-Dur',
      );
      expect(
        tonalityDisplayLabel(
          const Tonality(Tonic.eFlat, TonalityMode.minor),
          noteNameSystem: NoteNameSystem.german,
        ),
        'es-Moll',
      );
    });

    test(
      'preserves English major and minor labels for International names',
      () {
        expect(
          tonalityDisplayLabel(
            const Tonality(Tonic.fSharp, TonalityMode.major),
          ),
          'F♯ major',
        );
        expect(
          tonalityDisplayLabel(const Tonality(Tonic.eFlat, TonalityMode.minor)),
          'E♭ minor',
        );
      },
    );
  });

  group('chordSymbolDisplayLabel', () {
    test('converts root, quality, and slash bass accidentals for UI', () {
      final symbol = ChordSymbol(root: 'Bb', quality: '7(#11)', bass: 'F#');

      expect(chordSymbolDisplayLabel(symbol), 'B♭7(♯11) / F♯');
    });

    test('uses compact fixed-Do chord names', () {
      final symbol = ChordSymbol(root: 'F#', quality: 'm7(b5)', bass: 'C#');

      expect(
        chordSymbolDisplayLabel(symbol, noteNameSystem: NoteNameSystem.fixedDo),
        'Fa♯m7(♭5) / Do♯',
      );
    });

    test('uses German H and B in chord names', () {
      final symbol = ChordSymbol(root: 'B', quality: '7', bass: 'Bb');

      expect(
        chordSymbolDisplayLabel(symbol, noteNameSystem: NoteNameSystem.german),
        'H7 / B',
      );
    });
  });

  group('chordSymbolTextLabel', () {
    test('uses compact slash-bass spacing for copy text', () {
      final symbol = ChordSymbol(root: 'Bb', quality: '7(#11)', bass: 'F#');

      expect(chordSymbolTextLabel(symbol), 'B♭7(♯11)/F♯');
    });

    test('keeps non-slash chord symbols unchanged', () {
      final symbol = ChordSymbol(root: 'C', quality: 'maj7');

      expect(chordSymbolTextLabel(symbol), 'Cmaj7');
    });
  });
}
