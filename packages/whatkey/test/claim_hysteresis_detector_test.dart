import 'package:test/test.dart';

import 'package:whatchord/whatchord.dart';
import 'package:whatkey/whatkey.dart';

const _cMajor = Tonality(Tonic.c, TonalityMode.major);
const _gMajor = Tonality(Tonic.g, TonalityMode.major);
const _aMinor = Tonality(Tonic.a, TonalityMode.minor);

/// Scripted inner detector: emits a fixed sequence of claims (null =
/// abstain), each with a two-entry ranked list so the wrapper can re-anchor
/// to a committed key.
class _ScriptedDetector implements KeyDetector {
  final List<Tonality?> script;
  int _index = 0;

  _ScriptedDetector(this.script);

  @override
  String get name => 'scripted';

  @override
  String get configuration => 'script=${script.length}';

  @override
  void reset() => _index = 0;

  @override
  KeyEstimateFrame onEvent(ChordEvent event) {
    final claim = script[_index++];
    final ranked = [
      for (final tonality in const [_cMajor, _gMajor, _aMinor])
        KeyEstimate(
          tonality: tonality,
          confidence: tonality == claim ? 1.0 : 0.5,
        ),
    ]..sort((a, b) => b.confidence.compareTo(a.confidence));
    if (claim == null) return KeyEstimateFrame.abstain(ranked);
    return KeyEstimateFrame(ranked: ranked, claim: ranked.first);
  }
}

ChordEvent _event(int index) => ChordEvent(
  timestamp: DateTime.fromMillisecondsSinceEpoch(index * 2000),
  input: const ChordInput(pcMask: 0x91, bassPc: 0, noteCount: 3),
  voicing: ObservedVoicing.fromMidi(const [48, 60, 64, 67]),
  candidates: [
    ChordCandidate(
      identity: const ChordIdentity(
        rootPc: 0,
        bassPc: 0,
        quality: ChordQualityToken.major,
        presentIntervalsMask: 0x91,
      ),
      cost: 0,
    ),
  ],
  tonality: _cMajor,
  duration: const Duration(seconds: 2),
);

List<Tonality?> _claims(List<Tonality?> script, {int minStreak = 2}) {
  final detector = ClaimHysteresisDetector(
    inner: _ScriptedDetector(script),
    minStreak: minStreak,
  );
  detector.reset();
  return [
    for (var i = 0; i < script.length; i++)
      detector.onEvent(_event(i)).claim?.tonality,
  ];
}

void main() {
  test('one-frame blip does not switch the claim', () {
    final claims = _claims([
      _cMajor, _cMajor, _gMajor, _cMajor, _cMajor, //
    ]);
    expect(claims, [null, _cMajor, _cMajor, _cMajor, _cMajor]);
  });

  test('a sustained challenger switches after minStreak frames', () {
    final claims = _claims([
      _cMajor, _cMajor, _gMajor, _gMajor, _gMajor, //
    ]);
    expect(claims, [null, _cMajor, _cMajor, _gMajor, _gMajor]);
  });

  test('the first claim also waits out the streak', () {
    final claims = _claims([_cMajor, _cMajor, _cMajor]);
    expect(claims, [null, _cMajor, _cMajor]);

    final immediate = _claims([_cMajor, _cMajor], minStreak: 1);
    expect(immediate, [_cMajor, _cMajor]);
  });

  test('inner abstention passes through and resets the challenger streak', () {
    final claims = _claims([
      _cMajor, _cMajor, _gMajor, null, _gMajor, _gMajor, //
    ]);
    // The abstention at index 3 resets G's streak, so G needs two more
    // consecutive frames before the switch lands at index 5.
    expect(claims, [null, _cMajor, _cMajor, null, _cMajor, _gMajor]);
  });

  test('a changing challenger never accumulates a streak', () {
    final claims = _claims([
      _cMajor, _cMajor, _gMajor, _aMinor, _gMajor, _aMinor, //
    ]);
    expect(claims, [null, _cMajor, _cMajor, _cMajor, _cMajor, _cMajor]);
  });
}
