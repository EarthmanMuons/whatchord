import 'package:test/test.dart';

import 'package:whatchord/src/services/chord_tone_roles.dart';
import 'package:whatchord/whatchord.dart';

void main() {
  group('buildSeedIdentity', () {
    test('uses the selected major-key tonic when idle', () {
      final seed = buildSeedIdentity(
        input: null,
        tonality: const Tonality(Tonic.c, TonalityMode.major),
      );

      expect(seed.rootPc, 0);
      expect(seed.bassPc, 0);
      expect(seed.quality, ChordQuality.major);
    });

    test('uses the selected minor-key tonic when idle', () {
      final seed = buildSeedIdentity(
        input: null,
        tonality: const Tonality(Tonic.a, TonalityMode.minor),
      );

      expect(seed.rootPc, 9);
      expect(seed.bassPc, 9);
      expect(seed.quality, ChordQuality.minor);
    });

    test('uses a single note as root with the current key-mode quality', () {
      final seed = buildSeedIdentity(
        input: _input([64]),
        tonality: const Tonality(Tonic.d, TonalityMode.major),
      );

      expect(seed.rootPc, 4);
      expect(seed.bassPc, 4);
      expect(seed.quality, ChordQuality.major);
    });

    test('maps dyad intervals to simple chord qualities', () {
      expect(_dyadQuality(60, 62), ChordQuality.sus2);
      expect(_dyadQuality(60, 63), ChordQuality.minor);
      expect(_dyadQuality(60, 64), ChordQuality.major);
      expect(_dyadQuality(60, 65), ChordQuality.sus4);
      expect(_dyadQuality(60, 66), ChordQuality.diminished);
    });

    test('maps perfect fifths to the current key-mode quality', () {
      final majorSeed = buildSeedIdentity(
        input: _input([60, 67]),
        tonality: const Tonality(Tonic.c, TonalityMode.major),
      );
      final minorSeed = buildSeedIdentity(
        input: _input([60, 67]),
        tonality: const Tonality(Tonic.a, TonalityMode.minor),
      );

      expect(majorSeed.quality, ChordQuality.major);
      expect(minorSeed.quality, ChordQuality.minor);
    });

    test('falls back deterministically for ambiguous dyads', () {
      final majorSeed = buildSeedIdentity(
        input: _input([60, 70]),
        tonality: const Tonality(Tonic.c, TonalityMode.major),
      );
      final minorSeed = buildSeedIdentity(
        input: _input([60, 70]),
        tonality: const Tonality(Tonic.a, TonalityMode.minor),
      );

      expect(majorSeed.quality, ChordQuality.major);
      expect(minorSeed.quality, ChordQuality.minor);
    });

    test('preserves the current full-chord identity', () {
      final current = ChordIdentity(
        rootPc: 2,
        bassPc: 6,
        quality: ChordQuality.dominant7,
        extensions: const {ChordExtension.flat9},
        toneRolesByInterval: ChordToneRoles.build(
          quality: ChordQuality.dominant7,
          extensions: const {ChordExtension.flat9},
          relMask: 0x493,
        ),
        presentIntervalsMask: 0x493,
      );

      final seed = buildSeedIdentity(
        input: _input([62, 66, 69, 72, 75]),
        tonality: const Tonality(Tonic.c, TonalityMode.major),
        currentChordIdentity: current,
      );

      expect(seed, current);
    });
  });
}

ChordQuality _dyadQuality(int bassMidi, int upperMidi) {
  final seed = buildSeedIdentity(
    input: _input([bassMidi, upperMidi]),
    tonality: const Tonality(Tonic.c, TonalityMode.major),
  );
  return seed.quality;
}

ChordInput _input(List<int> midis) {
  final sorted = [...midis]..sort();
  var mask = 0;
  for (final midi in sorted) {
    mask |= 1 << (midi % 12);
  }

  return ChordInput(
    pcMask: mask,
    bassPc: sorted.first % 12,
    noteCount: sorted.length,
  );
}
