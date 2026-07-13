import 'package:test/test.dart';

import 'package:whatchord/src/services/chord_tone_roles.dart';
import 'package:whatchord/whatchord.dart';

void main() {
  test('uses official shorthand for exact common qualities', () {
    expect(
      HarteChordFormatter.format(
        _identity(
          root: 'C',
          quality: ChordQuality.major,
          intervals: const [0, 4, 7],
        ),
      ),
      'C:maj',
    );

    expect(
      HarteChordFormatter.format(
        _identity(
          root: 'C',
          quality: ChordQuality.diminished7,
          intervals: const [0, 3, 6, 9],
        ),
      ),
      'C:dim7',
    );

    expect(
      HarteChordFormatter.format(
        _identity(
          root: 'C',
          quality: ChordQuality.minor7Sharp5,
          intervals: const [0, 3, 8, 10],
        ),
      ),
      'C:min7(#5)',
    );
  });

  test('adds extra degrees to official shorthands', () {
    final identity = _identity(
      root: 'C',
      quality: ChordQuality.major7,
      extensions: const {ChordExtension.sharp11},
      intervals: const [0, 4, 7, 11, 6],
    );

    expect(HarteChordFormatter.format(identity), 'C:maj7(#11)');
  });

  test('uses component lists for unsupported chord types', () {
    expect(
      HarteChordFormatter.format(
        _identity(
          root: 'C',
          quality: ChordQuality.sus2,
          intervals: const [0, 2, 7],
        ),
      ),
      'C:(2,5)',
    );

    expect(
      HarteChordFormatter.format(
        _identity(
          root: 'C',
          quality: ChordQuality.dominant7Flat5,
          intervals: const [0, 4, 6, 10],
        ),
      ),
      'C:(3,b5,b7)',
    );
  });

  test('uses Harte bass degrees instead of bass note names', () {
    final identity = _identity(
      root: 'D#',
      bass: 'A#',
      quality: ChordQuality.minor7,
      extensions: const {ChordExtension.nine},
      intervals: const [0, 3, 7, 10, 2],
    );

    expect(HarteChordFormatter.format(identity), 'Eb:min9/5');
  });

  test('preserves an explicit enharmonic root spelling', () {
    final identity = _identity(
      root: 'C#',
      quality: ChordQuality.minor,
      intervals: const [0, 3, 7],
    );

    expect(HarteChordFormatter.format(identity, rootName: 'C#'), 'C#:min');
    expect(HarteChordFormatter.format(identity, rootName: 'Db'), 'Db:min');
  });

  test('keeps suspended fourth as official shorthand with extra degrees', () {
    final identity = _identity(
      root: 'Bb',
      quality: ChordQuality.dominant7sus4,
      intervals: const [0, 5, 7, 10],
    );

    expect(HarteChordFormatter.format(identity), 'Bb:sus4(b7)');
  });
}

ChordIdentity _identity({
  required String root,
  required ChordQuality quality,
  required List<int> intervals,
  String? bass,
  Set<ChordExtension> extensions = const {},
}) {
  final presentIntervalsMask = _maskOfIntervals(intervals);

  return ChordIdentity(
    rootPc: pitchClassFromNoteName(root),
    bassPc: pitchClassFromNoteName(bass ?? root),
    quality: quality,
    extensions: extensions,
    toneRolesByInterval: ChordToneRoles.build(
      quality: quality,
      extensions: extensions,
      relMask: presentIntervalsMask,
    ),
    presentIntervalsMask: presentIntervalsMask,
  );
}

int _maskOfIntervals(Iterable<int> intervals) {
  var mask = 0;
  for (final interval in intervals) {
    mask |= 1 << (interval % 12);
  }
  return mask;
}
