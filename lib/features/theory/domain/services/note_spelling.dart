import '../models/chord_tone_role.dart';
import '../models/key_signature.dart';
import '../models/tonality.dart';
import 'pitch_class.dart';

/// Spells a pitch class using chord-tone role context when available.
///
/// - If [role] and [chordRootName] are provided, the letter is chosen by
///   diatonic degree above the chord root (e.g. "#11" uses the 4th letter,
///   "b5" uses the 5th letter), then accidentals are computed to hit [pc].
/// - Otherwise, falls back to tonality-aware [pcToName].
String spellPitchClass(
  int pc, {
  required Tonality tonality,
  String? chordRootName,
  ChordToneRole? role,
}) {
  if (role == null || chordRootName == null || chordRootName.trim().isEmpty) {
    return pcToName(pc, tonality: tonality);
  }

  final rootAscii = normalizeNoteNameToAscii(chordRootName);
  final rootLetter = rootAscii[0].toUpperCase();

  final rootIndex = _letters.indexOf(rootLetter);
  if (rootIndex == -1) return pcToName(pc, tonality: tonality);

  final degree = role.degreeFromRoot; // 1..7
  final targetLetter = _letters[(rootIndex + (degree - 1)) % 7];

  final naturalPc = _naturalPcByLetter[targetLetter]!;
  final targetPc = pc % 12;

  // Signed delta in semitones from natural letter to target PC.
  var delta = (targetPc - naturalPc) % 12;
  if (delta > 6) delta -= 12; // normalize to [-5..+6]

  // Keep current system conservative: allow up to double accidentals.
  if (delta < -2 || delta > 2) {
    return pcToName(pc, tonality: tonality);
  }

  return targetLetter + _accidentalToAscii(delta);
}

/// Tonality-aware pitch-class spelling (key-signature correct).
String pcToName(int pc, {required Tonality tonality}) {
  final i = pc % 12;

  final ks = tonality.keySignature;
  final diatonic = _buildDiatonicPcToName(
    fifths: ks.fifths,
    tonicLetter: _tonicLetter(tonality.tonic),
  );

  // Strict diatonic spelling if available.
  final strict = diatonic[i];
  if (strict != null) return strict;

  // Otherwise choose a good chromatic spelling relative to the key.
  return _spellChromaticPc(
    i,
    fifths: ks.fifths,
    tonicLetter: _tonicLetter(tonality.tonic),
    diatonicPcToName: diatonic,
  );
}

/// ---------- Internals ----------

const _letters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];

const _naturalPcByLetter = <String, int>{
  'C': 0,
  'D': 2,
  'E': 4,
  'F': 5,
  'G': 7,
  'A': 9,
  'B': 11,
};

const _sharpOrder = ['F', 'C', 'G', 'D', 'A', 'E', 'B'];
const _flatOrder = ['B', 'E', 'A', 'D', 'G', 'C', 'F'];

String _tonicLetter(String tonic) {
  // Handles "F#", "Bb", "F♯", "B♭" by taking just the diatonic letter.
  // Assumes tonic is normalized to start with A-G.
  return tonic.isEmpty ? 'C' : tonic[0].toUpperCase();
}

Map<String, int> _accidentalsByLetterFromFifths(int fifths) {
  final accByLetter = <String, int>{for (final l in _letters) l: 0};

  if (fifths > 0) {
    for (var k = 0; k < fifths; k++) {
      accByLetter[_sharpOrder[k]] = 1;
    }
  } else if (fifths < 0) {
    for (var k = 0; k < -fifths; k++) {
      accByLetter[_flatOrder[k]] = -1;
    }
  }

  return accByLetter;
}

Map<int, String> _buildDiatonicPcToName({
  required int fifths,
  required String tonicLetter,
}) {
  final tonicIndex = _letters.indexOf(tonicLetter);
  final startIndex = tonicIndex == -1 ? 0 : tonicIndex;

  final accByLetter = _accidentalsByLetterFromFifths(fifths);

  // Letter sequence of the scale starting on tonic letter.
  final diatonicLetters = List<String>.generate(
    7,
    (d) => _letters[(startIndex + d) % 7],
    growable: false,
  );

  final pcToName = <int, String>{};

  for (final letter in diatonicLetters) {
    final naturalPc = _naturalPcByLetter[letter]!;
    final acc = accByLetter[letter]!;
    final spelledPc = (naturalPc + acc) % 12;
    pcToName[spelledPc] = letter + _accidentalToAscii(acc);
  }

  return pcToName;
}

String _spellChromaticPc(
  int pc, {
  required int fifths,
  required String tonicLetter,
  required Map<int, String> diatonicPcToName,
}) {
  final accByLetter = _accidentalsByLetterFromFifths(fifths);

  // Avoid "wrap" spellings unless the key signature actually includes them diatonically.
  final diatonicNames = diatonicPcToName.values.toSet();
  bool allowWrap(String name) => diatonicNames.contains(name);

  _Candidate? best;

  for (final letter in _letters) {
    final baseAcc = accByLetter[letter]!;
    final naturalPc = _naturalPcByLetter[letter]!;
    final basePc = (naturalPc + baseAcc) % 12;

    // Signed semitone delta from in-key letter to target pc.
    var delta = (pc - basePc) % 12;
    if (delta > 6) delta -= 12; // normalize to [-5..+6]

    // Only allow up to double accidentals for now.
    if (delta < -2 || delta > 2) continue;

    final finalAcc = baseAcc + delta;
    if (finalAcc < -2 || finalAcc > 2) continue;

    final name = letter + _accidentalToAscii(finalAcc);

    final isWrap = name == 'B#' || name == 'Cb' || name == 'E#' || name == 'Fb';
    if (isWrap && !allowWrap(name)) continue;

    // Scoring: keep it stable and musically sane.
    var score = 0;
    score += delta.abs() * 10; // prefer smallest chromatic deviation
    if (finalAcc.abs() == 2) score += 60; // heavily penalize double accidentals
    if (fifths > 0 && finalAcc > 0) score -= 1; // slight key-direction bias
    if (fifths < 0 && finalAcc < 0) score -= 1;

    final cand = _Candidate(name: name, score: score);
    if (best == null || cand.score < best.score) best = cand;
  }

  return best?.name ?? _fallbackSharpName(pc);
}

String _accidentalToAscii(int acc) {
  return switch (acc) {
    -2 => 'bb',
    -1 => 'b',
    0 => '',
    1 => '#',
    2 => 'x', // double sharp
    _ => '',
  };
}

String _fallbackSharpName(int pc) {
  const sharps = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];
  return sharps[pc % 12];
}

class _Candidate {
  _Candidate({required this.name, required this.score});
  final String name;
  final int score;
}
