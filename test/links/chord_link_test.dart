import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/links/links.dart';
import 'package:whatchord/features/theory/theory.dart';

void main() {
  group('ChordLink.build', () {
    test('emits note names and omits the default C major key', () {
      final uri = ChordLink.build(
        orderedNoteNames: const ['C', 'E', 'G'],
        tonality: const Tonality(Tonic.c, TonalityMode.major),
      );

      expect(uri, isNotNull);
      expect(uri!.host, ChordLink.host);
      expect(uri.path, ChordLink.path);
      expect(uri.queryParameters['notes'], 'C E G');
      expect(uri.queryParameters.containsKey('key'), isFalse);
    });

    test('includes a non-default key', () {
      final uri = ChordLink.build(
        orderedNoteNames: const ['C', 'E', 'G'],
        tonality: const Tonality(Tonic.a, TonalityMode.minor),
      );

      expect(uri!.queryParameters['key'], 'A:min');
    });

    test('normalizes notation glyphs to ASCII', () {
      final uri = ChordLink.build(
        orderedNoteNames: const ['B♭', 'F♯', 'D𝄪', 'E𝄫'],
        tonality: const Tonality(Tonic.c, TonalityMode.major),
      );

      expect(uri!.queryParameters['notes'], 'Bb F# Dx Ebb');
    });

    test('formats a minor key with flat tonic', () {
      final uri = ChordLink.build(
        orderedNoteNames: const ['C'],
        tonality: const Tonality(Tonic.bFlat, TonalityMode.minor),
      );

      expect(uri!.queryParameters['key'], 'Bb:min');
    });

    test('returns null with no notes', () {
      expect(
        ChordLink.build(
          orderedNoteNames: const [],
          tonality: const Tonality(Tonic.c, TonalityMode.major),
        ),
        isNull,
      );
    });
  });

  group('ChordLink.parse', () {
    ChordLinkSeed? parse(String url) => ChordLink.parse(Uri.parse(url));

    test('round-trips a link built by build', () {
      final uri = ChordLink.build(
        orderedNoteNames: const ['C', 'E', 'G'],
        tonality: const Tonality(Tonic.d, TonalityMode.minor),
      )!;

      final seed = ChordLink.parse(uri)!;
      expect(seed.pitchClasses, [0, 4, 7]);
      expect(seed.tonality, const Tonality(Tonic.d, TonalityMode.minor));
    });

    test('parses note names and treats the first as the bass', () {
      final seed = parse(
        'https://${ChordLink.host}/try?notes=E+G+C&key=C:maj',
      )!;
      expect(seed.pitchClasses, [4, 7, 0]);
    });

    test('accepts commas, hyphens, glyphs, and mixed case', () {
      final seed = parse(
        'https://${ChordLink.host}/try?notes=c,e-g%20b%E2%99%AD',
      )!;
      expect(seed.pitchClasses, [0, 4, 7, 10]);
    });

    test('parses single and double accidentals', () {
      // Fx=G(7), Bbb=A(9), C##=D(2), Cb=B(11); # is encoded as %23 as in a real
      // link, since a raw # would start the URL fragment.
      final seed = parse(
        'https://${ChordLink.host}/try?notes=Fx+Bbb+C%23%23+Cb',
      )!;
      expect(seed.pitchClasses, [7, 9, 2, 11]);
    });

    test('still accepts MIDI numbers', () {
      final seed = parse('https://${ChordLink.host}/try?notes=48+52+55')!;
      expect(seed.pitchClasses, [0, 4, 7]);
    });

    test('skips unrecognized tokens but keeps the rest', () {
      final seed = parse('https://${ChordLink.host}/try?notes=C+zz+G')!;
      expect(seed.pitchClasses, [0, 7]);
    });

    test('defaults to C major when key is absent or invalid', () {
      const cMajor = Tonality(Tonic.c, TonalityMode.major);
      expect(parse('https://${ChordLink.host}/try?notes=C')!.tonality, cMajor);
      expect(
        parse('https://${ChordLink.host}/try?notes=C&key=H:maj')!.tonality,
        cMajor,
      );
    });

    test(
      'keeps a valid tonic and defaults the mode when the mode is invalid',
      () {
        expect(
          parse('https://${ChordLink.host}/try?notes=C&key=Eb:blah')!.tonality,
          const Tonality(Tonic.eFlat, TonalityMode.major),
        );
      },
    );

    test('rejects non-try links and other hosts', () {
      expect(parse('https://${ChordLink.host}/chords?notes=C'), isNull);
      expect(parse('https://example.com/try?notes=C'), isNull);
    });

    test('rejects empty or oversized note lists', () {
      expect(parse('https://${ChordLink.host}/try?notes='), isNull);
      final huge = List.filled(300, 'C').join(' ');
      expect(parse('https://${ChordLink.host}/try?notes=$huge'), isNull);
    });
  });
}
