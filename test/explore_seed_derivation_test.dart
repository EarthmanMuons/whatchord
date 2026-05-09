import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/explore/services/explore_seed_derivation.dart';
import 'package:whatchord/features/theory/theory.dart';

void main() {
  group('buildExploreSeedIdentity', () {
    test('uses the selected major-key tonic when idle', () {
      final seed = buildExploreSeedIdentity(
        input: null,
        tonality: const Tonality('C', TonalityMode.major),
      );

      expect(seed.rootPc, 0);
      expect(seed.bassPc, 0);
      expect(seed.quality, ChordQualityToken.major);
    });

    test('uses the selected minor-key tonic when idle', () {
      final seed = buildExploreSeedIdentity(
        input: null,
        tonality: const Tonality('A', TonalityMode.minor),
      );

      expect(seed.rootPc, 9);
      expect(seed.bassPc, 9);
      expect(seed.quality, ChordQualityToken.minor);
    });

    test('uses a single note as root with the current key-mode quality', () {
      final seed = buildExploreSeedIdentity(
        input: _input([64]),
        tonality: const Tonality('D', TonalityMode.major),
      );

      expect(seed.rootPc, 4);
      expect(seed.bassPc, 4);
      expect(seed.quality, ChordQualityToken.major);
    });

    test('maps dyad intervals to simple chord qualities', () {
      expect(_dyadQuality(60, 62), ChordQualityToken.sus2);
      expect(_dyadQuality(60, 63), ChordQualityToken.minor);
      expect(_dyadQuality(60, 64), ChordQualityToken.major);
      expect(_dyadQuality(60, 65), ChordQualityToken.sus4);
      expect(_dyadQuality(60, 66), ChordQualityToken.diminished);
    });

    test('maps perfect fifths to the current key-mode quality', () {
      final majorSeed = buildExploreSeedIdentity(
        input: _input([60, 67]),
        tonality: const Tonality('C', TonalityMode.major),
      );
      final minorSeed = buildExploreSeedIdentity(
        input: _input([60, 67]),
        tonality: const Tonality('A', TonalityMode.minor),
      );

      expect(majorSeed.quality, ChordQualityToken.major);
      expect(minorSeed.quality, ChordQualityToken.minor);
    });

    test('falls back deterministically for ambiguous dyads', () {
      final majorSeed = buildExploreSeedIdentity(
        input: _input([60, 70]),
        tonality: const Tonality('C', TonalityMode.major),
      );
      final minorSeed = buildExploreSeedIdentity(
        input: _input([60, 70]),
        tonality: const Tonality('A', TonalityMode.minor),
      );

      expect(majorSeed.quality, ChordQualityToken.major);
      expect(minorSeed.quality, ChordQualityToken.minor);
    });

    test('preserves the current full-chord identity', () {
      final current = ChordIdentity(
        rootPc: 2,
        bassPc: 6,
        quality: ChordQualityToken.dominant7,
        extensions: const {ChordExtension.flat9},
        toneRolesByInterval: ChordToneRoles.build(
          quality: ChordQualityToken.dominant7,
          extensions: const {ChordExtension.flat9},
          relMask: 0x493,
        ),
        presentIntervalsMask: 0x493,
      );

      final seed = buildExploreSeedIdentity(
        input: _input([62, 66, 69, 72, 75]),
        tonality: const Tonality('C', TonalityMode.major),
        currentChordIdentity: current,
      );

      expect(seed, current);
    });
  });
}

ChordQualityToken _dyadQuality(int bassMidi, int upperMidi) {
  final seed = buildExploreSeedIdentity(
    input: _input([bassMidi, upperMidi]),
    tonality: const Tonality('C', TonalityMode.major),
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
