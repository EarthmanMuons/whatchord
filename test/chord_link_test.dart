import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/links/links.dart';
import 'package:whatchord/features/theory/theory.dart';

void main() {
  group('ChordLink.build', () {
    test('emits MIDI notes and key in the canonical grammar', () {
      final uri = ChordLink.build(
        orderedNotes: const [48, 52, 55],
        tonality: const Tonality(Tonic.c, TonalityMode.major),
      );

      expect(uri, isNotNull);
      expect(uri!.host, ChordLink.host);
      expect(uri.path, ChordLink.path);
      expect(uri.queryParameters['notes'], '48 52 55');
      expect(uri.queryParameters['key'], 'C:maj');
    });

    test('formats a minor key with flat tonic', () {
      final uri = ChordLink.build(
        orderedNotes: const [60],
        tonality: const Tonality(Tonic.bFlat, TonalityMode.minor),
      );

      expect(uri!.queryParameters['key'], 'Bb:min');
    });

    test('returns null with no notes', () {
      expect(
        ChordLink.build(
          orderedNotes: const [],
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
        orderedNotes: const [48, 52, 55],
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

    test('skips unrecognized tokens but keeps the rest', () {
      final seed = parse('https://${ChordLink.host}/try?notes=C+zz+G')!;
      expect(seed.pitchClasses, [0, 7]);
    });

    test('leaves tonality null when key is absent or invalid', () {
      expect(parse('https://${ChordLink.host}/try?notes=C')!.tonality, isNull);
      expect(
        parse('https://${ChordLink.host}/try?notes=C&key=H:maj')!.tonality,
        isNull,
      );
    });

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
