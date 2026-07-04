import '../models/chord_identity.dart';
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

/// Chooses a root spelling that keeps the whole chord readable.
///
/// Tonality still matters, but role-aware member spellings can override a
/// chromatic tie. For example, pitch class 8 in C major is ambiguous as G# or
/// Ab; a major triad rooted there spells cleanly as Ab-C-Eb, not G#-B#-D#.
String spellChordRoot(ChordIdentity identity, {required Tonality tonality}) {
  final tonalName = pcToName(identity.rootPc, tonality: tonality);
  if (_isDiatonicName(tonalName, tonality: tonality)) return tonalName;

  final candidates = _candidateNamesForPc(identity.rootPc);

  _RootSpellingCandidate? best;
  for (final name in candidates) {
    final cost = _costChordRootName(
      identity,
      rootName: name,
      tonality: tonality,
      tonalName: tonalName,
    );
    final candidate = _RootSpellingCandidate(name: name, cost: cost);
    if (best == null ||
        candidate.cost < best.cost ||
        (candidate.cost == best.cost && candidate.name == tonalName)) {
      best = candidate;
    }
  }

  return best?.name ?? tonalName;
}

bool _isDiatonicName(String name, {required Tonality tonality}) {
  final diatonic = _buildDiatonicPcToName(
    fifths: tonality.keySignature.fifths,
    tonicLetter: tonality.tonic.letter,
  );
  return diatonic.values.contains(normalizeNoteNameToAscii(name));
}

/// Tonality-aware pitch-class spelling (key-signature correct).
String pcToName(int pc, {required Tonality tonality}) {
  final i = pc % 12;

  final ks = tonality.keySignature;
  final diatonic = _buildDiatonicPcToName(
    fifths: ks.fifths,
    tonicLetter: tonality.tonic.letter,
  );

  // Strict diatonic spelling if available.
  final strict = diatonic[i];
  if (strict != null) return strict;

  // Otherwise choose a good chromatic spelling relative to the key.
  return _spellChromaticPc(
    i,
    fifths: ks.fifths,
    tonicLetter: tonality.tonic.letter,
    diatonicPcToName: diatonic,
  );
}

/// Spells the tones of a scale using explicit letter offsets from the tonic.
///
/// [pitchClasses] are the scale tones in ascending scale order starting on the
/// tonic. [letterOffsets] chooses the letter for each tone relative to the
/// tonic letter. Heptatonic scales usually use 0..6; pentatonic and blues
/// scales skip or repeat letters so spellings stay musician-readable.
List<String> spellScaleTones({
  required List<int> pitchClasses,
  required String tonicLetter,
  required List<int> letterOffsets,
}) {
  assert(pitchClasses.length == letterOffsets.length);

  final tonicIndex = _letters.indexOf(tonicLetter.toUpperCase());
  final startIndex = tonicIndex == -1 ? 0 : tonicIndex;

  final names = <String>[];
  for (var d = 0; d < pitchClasses.length; d++) {
    final letter = _letters[(startIndex + letterOffsets[d]) % 7];
    final naturalPc = _naturalPcByLetter[letter]!;
    final targetPc = pitchClasses[d] % 12;

    var delta = (targetPc - naturalPc) % 12;
    if (delta > 6) delta -= 12; // normalize to [-5..+6]

    names.add(letter + _accidentalToAscii(delta));
  }

  return names;
}

/// Spells the tones of a heptatonic scale using consecutive letter names.
///
/// [pitchClasses] are the scale tones in ascending scale order starting on the
/// tonic. One letter is assigned per scale degree, walking consecutively from
/// [tonicLetter], and accidentals are chosen to match each pitch class. Returns
/// ASCII note names such as "Eb" or "F#".
List<String> spellHeptatonicScale({
  required List<int> pitchClasses,
  required String tonicLetter,
}) {
  return spellScaleTones(
    pitchClasses: pitchClasses,
    tonicLetter: tonicLetter,
    letterOffsets: const [0, 1, 2, 3, 4, 5, 6],
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

    // Pricing: keep it stable and musically sane.
    var cost = 0;
    cost += delta.abs() * 10; // prefer smallest chromatic deviation
    if (finalAcc.abs() == 2) cost += 60; // heavily penalize double accidentals
    if (fifths > 0 && finalAcc > 0) cost -= 1; // slight key-direction bias
    if (fifths < 0 && finalAcc < 0) cost -= 1;

    final cand = _Candidate(name: name, cost: cost);
    if (best == null || cand.cost < best.cost) best = cand;
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

List<String> _candidateNamesForPc(int pc) {
  final targetPc = pc % 12;
  final out = <String>[];

  for (final letter in _letters) {
    final naturalPc = _naturalPcByLetter[letter]!;
    var delta = (targetPc - naturalPc) % 12;
    if (delta > 6) delta -= 12;
    // Roots never need double accidentals; restricting to ±1 prevents
    // spellings like B𝄪 or Cbb from appearing as chord root candidates.
    if (delta < -1 || delta > 1) continue;
    out.add(letter + _accidentalToAscii(delta));
  }

  return out;
}

int _costChordRootName(
  ChordIdentity identity, {
  required String rootName,
  required Tonality tonality,
  required String tonalName,
}) {
  var cost = 0;

  if (rootName != tonalName) cost += 3;
  cost += _noteNamePenalty(rootName);

  for (final entry in identity.toneRolesByInterval.entries) {
    final pc = (identity.rootPc + entry.key) % 12;
    final member = spellPitchClass(
      pc,
      tonality: tonality,
      chordRootName: rootName,
      role: entry.value,
    );
    cost += _noteNamePenalty(member);
  }

  return cost;
}

int _noteNamePenalty(String name) {
  final ascii = normalizeNoteNameToAscii(name);
  if (ascii.isEmpty) return 1000;

  final accidental = ascii.substring(1);
  var cost = 0;
  for (final c in accidental.split('')) {
    if (c == '#' || c == 'b') cost += 10;
    if (c == 'x') cost += 20;
  }
  if (accidental.length == 2) cost += 30;
  if (ascii == 'B#' || ascii == 'Cb' || ascii == 'E#' || ascii == 'Fb') {
    cost += 16;
  }
  return cost;
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
  _Candidate({required this.name, required this.cost});
  final String name;
  final int cost;
}

class _RootSpellingCandidate {
  _RootSpellingCandidate({required this.name, required this.cost});
  final String name;
  final int cost;
}
