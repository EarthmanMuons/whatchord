// tool/src/chord_id_engine.dart
//
// Pure-Dart facade over the chord analysis engine for tooling and the web
// demo. No dart:io, no js_interop, so it compiles for both the CLI harness
// (tool/chord_debug.dart) and the browser entry (tool/web/chord_id_main.dart).
//
// Input is free text: pitch names (C, F#, Bb, Eb) and/or MIDI note numbers
// (60, 64, 67), separated by spaces and/or commas. The first note is treated
// as the bass when only pitch names are given; with MIDI numbers the lowest
// note is the bass.

import 'package:whatchord/features/theory/domain/theory_domain.dart';
import 'package:whatchord/features/theory/presentation/models/chord_symbol.dart';
import 'package:whatchord/features/theory/presentation/services/chord_long_form_formatter.dart';
import 'package:whatchord/features/theory/presentation/services/chord_symbol_builder.dart';
import 'package:whatchord/features/theory/presentation/services/note_display_formatter.dart';

/// Maximum number of note tokens accepted by a single identification request.
const maxChordIdNoteTokens = 128;

/// Maximum number of characters accepted by a single identification request.
const maxChordIdInputCharacters = 512;

const _maxReportedUnrecognizedTokens = 5;
const _maxReportedTokenCharacters = 32;

/// How a candidate relates to the top pick.
enum CandidateClass {
  /// The engine's chosen interpretation (rank 1).
  chosen,

  /// Within [ChordCandidateRanking.nearTieWindow] of the chosen score; a
  /// musically plausible alternative the app would surface.
  nearTie,

  /// Ranked but well below the chosen score; shown for transparency.
  unlikely,
}

extension CandidateClassLabel on CandidateClass {
  String get wireName => switch (this) {
    CandidateClass.chosen => 'chosen',
    CandidateClass.nearTie => 'near-tie',
    CandidateClass.unlikely => 'unlikely',
  };
}

/// One ranked interpretation, formatted for display.
class ChordIdCandidate {
  ChordIdCandidate({
    required this.rank,
    required this.symbol,
    required this.academicName,
    required this.chordTones,
    required this.alsoPlayedNotes,
    required this.score,
    required this.deltaBest,
    required this.classification,
  });

  final int rank;
  final String symbol;
  final String academicName;

  /// Input pitch classes represented by this chord interpretation.
  final String chordTones;

  /// Input pitch classes not represented by this chord interpretation.
  final String alsoPlayedNotes;
  final double score;
  final double deltaBest;
  final CandidateClass classification;

  Map<String, Object?> toJson() => <String, Object?>{
    'rank': rank,
    'symbol': symbol,
    'academicName': academicName,
    'chordTones': chordTones,
    'alsoPlayedNotes': alsoPlayedNotes,
    'score': double.parse(score.toStringAsFixed(2)),
    'deltaBest': double.parse(deltaBest.toStringAsFixed(2)),
    'class': classification.wireName,
  };
}

/// Result of an identification request: either parsed candidates, or errors
/// describing why nothing could be analyzed. [warnings] are non-fatal (e.g.
/// ignored tokens) and may accompany a successful result.
class ChordIdResult {
  ChordIdResult({
    required this.ok,
    required this.notes,
    required this.bass,
    required this.key,
    required this.candidates,
    required this.warnings,
    required this.errors,
  });

  final bool ok;

  /// Display labels of the input notes in entry order, with the player's
  /// spelling preserved and duplicate MIDI numbers collapsed, e.g. for input
  /// "E G C" -> ["E", "G", "C"].
  final List<String> notes;
  final String bass;
  final String key;
  final List<ChordIdCandidate> candidates;
  final List<String> warnings;
  final List<String> errors;

  Map<String, Object?> toJson() => <String, Object?>{
    'ok': ok,
    'input': <String, Object?>{'notes': notes, 'bass': bass, 'key': key},
    'candidates': [for (final c in candidates) c.toJson()],
    'warnings': warnings,
    'errors': errors,
  };
}

/// Identifies the chord described by [notes] (free text), ranking up to [top]
/// candidates within the harmonic context of [key].
ChordIdResult identifyChord(
  String notes, {
  String key = 'C:maj',
  ChordNotationStyle notation = ChordNotationStyle.textual,
  int top = 5,
}) {
  if (notes.length > maxChordIdInputCharacters) {
    return ChordIdResult(
      ok: false,
      notes: const [],
      bass: '',
      key: tonalityDisplayLabel(parseTonality(key)),
      candidates: const [],
      warnings: const [],
      errors: const ['Input is too long. Enter no more than 512 characters.'],
    );
  }

  final tonality = parseTonality(key);
  final ks = KeySignature.fromTonality(tonality);
  final context = AnalysisContext(
    tonality: tonality,
    keySignature: ks,
    spellingPolicy: NoteSpellingPolicy(preferFlats: ks.prefersFlats),
  );
  final keyLabel = tonalityDisplayLabel(tonality);

  final tokens = splitNoteTokens(notes);
  if (tokens.isEmpty) {
    return ChordIdResult(
      ok: false,
      notes: const [],
      bass: '',
      key: keyLabel,
      candidates: const [],
      warnings: const [],
      errors: const ['Type some notes, e.g. C E G or 60 64 67.'],
    );
  }
  if (tokens.length > maxChordIdNoteTokens) {
    return ChordIdResult(
      ok: false,
      notes: const [],
      bass: '',
      key: keyLabel,
      candidates: const [],
      warnings: const [],
      errors: const [
        'Too many notes. Enter no more than 128 note names or MIDI numbers.',
      ],
    );
  }

  final parsed = parseNotes(tokens);
  if (parsed.pitchClasses.isEmpty) {
    return ChordIdResult(
      ok: false,
      notes: const [],
      bass: '',
      key: keyLabel,
      candidates: const [],
      warnings: const [],
      errors: [
        if (parsed.unrecognized.isEmpty)
          'Could not parse any notes.'
        else
          'Not a note: ${_formatUnrecognized(parsed.unrecognized)}. '
              'Use note names like C, F#, Bb, or MIDI numbers 0-127.',
      ],
    );
  }

  final warnings = <String>[
    if (parsed.unrecognized.isNotEmpty)
      'Ignored: ${_formatUnrecognized(parsed.unrecognized)}.',
  ];

  final midi = parsed.midiNotes;
  final pcs = parsed.pitchClasses;
  final bassPc = midi.isNotEmpty
      ? midi.reduce((a, b) => a < b ? a : b) % 12
      : pcs.first;

  final pcMask = _pcMaskFrom(pcs) | (1 << bassPc);
  final bassWasMissing = (_pcMaskFrom(pcs) & (1 << bassPc)) == 0;
  final input = ChordInput(
    pcMask: pcMask,
    bassPc: bassPc,
    noteCount:
        (midi.isNotEmpty ? midi.length : pcs.length) + (bassWasMissing ? 1 : 0),
  );

  final noteLabels = inputNoteLabels(parsed, tonality: tonality);

  final bassPreserved = parsed.pcLabels[bassPc];
  final bassLabel = noteDisplayLabel(
    bassPreserved != null
        ? normalizeNoteNameToAscii(bassPreserved)
        : pcToName(bassPc, tonality: tonality),
  );

  // Register evidence only applies when actual MIDI numbers were given; bare
  // pitch names carry no octave, so there is no voicing to reason about.
  final voicing = midi.length >= 2 ? ObservedVoicing.fromMidi(midi) : null;
  final ranked = ChordAnalyzer.analyze(
    input,
    context: context,
    voicing: voicing,
    take: top,
  );
  if (ranked.isEmpty) {
    return ChordIdResult(
      ok: true,
      notes: noteLabels,
      bass: bassLabel,
      key: keyLabel,
      candidates: const [],
      warnings: warnings,
      errors: const [],
    );
  }

  final bestScore = ranked.first.score;
  final candidates = <ChordIdCandidate>[];
  for (var i = 0; i < ranked.length; i++) {
    final c = ranked[i];
    final classification = i == 0
        ? CandidateClass.chosen
        : (ChordCandidateRanking.isNearTie(bestScore, c.score)
              ? CandidateClass.nearTie
              : CandidateClass.unlikely);

    candidates.add(
      ChordIdCandidate(
        rank: i + 1,
        symbol: chordSymbolDisplayLabel(
          ChordSymbolBuilder.fromIdentity(
            identity: c.identity,
            tonality: tonality,
            notation: notation,
          ),
        ),
        academicName: ChordLongFormFormatter.format(
          identity: c.identity,
          tonality: tonality,
        ),
        chordTones: _spellChordTones(c.identity, tonality: tonality),
        alsoPlayedNotes: _spellAlsoPlayedTones(
          c.identity,
          parsed,
          tonality: tonality,
        ),
        score: c.score,
        deltaBest: c.score - bestScore,
        classification: classification,
      ),
    );
  }

  return ChordIdResult(
    ok: true,
    notes: noteLabels,
    bass: bassLabel,
    key: keyLabel,
    candidates: candidates,
    warnings: warnings,
    errors: const [],
  );
}

/// Splits free-text input into individual note tokens on commas, hyphens, and
/// whitespace, dropping empties.
List<String> splitNoteTokens(String raw) {
  return raw
      .split(RegExp(r'[\s,-]+'))
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();
}

/// Parses a key string into a [Tonality].
///
/// Accepts "C", "C:maj", "C:major", "A:min", "Eb:maj", "F# minor". Unknown
/// tonics fall back to C; unknown modes fall back to major.
Tonality parseTonality(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return const Tonality(Tonic.c, TonalityMode.major);

  final compact = s.replaceAll(RegExp(r'\s+'), '');
  String tonicPart;
  String? modePart;
  final colon = compact.indexOf(':');
  if (colon >= 0) {
    tonicPart = compact.substring(0, colon);
    modePart = compact.substring(colon + 1);
  } else {
    tonicPart = compact;
    modePart = null;
  }

  var mode = TonalityMode.major;
  if (modePart != null) {
    final m = modePart.toLowerCase();
    if (m == 'min' || m == 'minor') mode = TonalityMode.minor;
  } else {
    final lower = tonicPart.toLowerCase();
    for (final suffix in const ['minor', 'major', 'min', 'maj']) {
      if (!lower.endsWith(suffix)) continue;
      mode = suffix.startsWith('min') ? TonalityMode.minor : TonalityMode.major;
      tonicPart = tonicPart.substring(0, tonicPart.length - suffix.length);
      break;
    }
  }

  Tonic tonic;
  try {
    tonic = Tonic.tryFromLabel(normalizeNoteNameToAscii(tonicPart)) ?? Tonic.c;
  } on ArgumentError {
    tonic = Tonic.c;
  }
  return Tonality(tonic, mode);
}

/// One successfully parsed note, kept in input order. [name] holds the raw
/// pitch-name spelling for name tokens (null for MIDI tokens); [midi] holds the
/// absolute MIDI number for numeric tokens (null for name tokens).
typedef ParsedNote = ({int pc, String? name, int? midi});

/// Result of parsing note tokens: MIDI numbers, pitch classes, the player's
/// preferred spelling per pitch class (first seen wins), the notes in input
/// order, and any tokens that were neither a valid pitch name nor an in-range
/// MIDI number.
class NoteParse {
  NoteParse(
    this.midiNotes,
    this.pitchClasses,
    this.pcLabels,
    this.ordered,
    this.unrecognized,
  );
  final List<int> midiNotes;
  final List<int> pitchClasses;
  final Map<int, String> pcLabels;
  final List<ParsedNote> ordered;
  final List<String> unrecognized;
}

/// Parses already-split note [tokens] (pitch names or MIDI numbers).
NoteParse parseNotes(List<String> tokens) {
  final midi = <int>[];
  final pcs = <int>[];
  final pcLabels = <int, String>{};
  final ordered = <ParsedNote>[];
  final unrecognized = <String>[];

  for (final token in tokens) {
    final raw = token.trim();
    if (raw.isEmpty) continue;

    final asInt = int.tryParse(raw);
    if (asInt != null) {
      if (asInt < 0 || asInt > 127) {
        unrecognized.add(raw);
        continue;
      }
      midi.add(asInt);
      pcs.add(asInt % 12);
      ordered.add((pc: asInt % 12, name: null, midi: asInt));
      continue;
    }

    try {
      final pc = pitchClassFromNoteName(raw);
      pcs.add(pc);
      pcLabels.putIfAbsent(pc, () => raw);
      ordered.add((pc: pc, name: raw, midi: null));
    } on ArgumentError {
      unrecognized.add(raw);
    }
  }

  return NoteParse(midi, pcs, pcLabels, ordered, unrecognized);
}

/// Echoes the parsed input notes in entry order, preserving the player's
/// spelling. Identical MIDI numbers collapse (the same key cannot sound twice);
/// repeated note names are kept, so the echo mirrors the actual voicing for
/// later spread/density context. This is the "Notes" line shared by the website
/// demo and the CLI harness.
List<String> inputNoteLabels(NoteParse parsed, {required Tonality tonality}) {
  final seenMidi = <int>{};
  return <String>[
    for (final n in parsed.ordered)
      if (n.midi == null || seenMidi.add(n.midi!))
        noteDisplayLabel(
          n.name != null
              ? normalizeNoteNameToAscii(n.name!)
              : pcToName(n.pc, tonality: tonality),
        ),
  ];
}

String _spellChordTones(ChordIdentity id, {required Tonality tonality}) {
  final rootName = spellChordRoot(id, tonality: tonality);
  final byInterval = <int, ChordToneRole>{
    0: ChordToneRole.root,
    ...id.toneRolesByInterval,
  };
  final intervals = byInterval.keys.toList()
    ..sort((a, b) {
      final degreeComparison = _degreeOrder(
        byInterval[a]!,
      ).compareTo(byInterval[b]!.degreeOrder);
      return degreeComparison != 0 ? degreeComparison : a.compareTo(b);
    });
  return [
    for (final interval in intervals)
      noteDisplayLabel(
        spellPitchClass(
          (id.rootPc + interval) % 12,
          tonality: tonality,
          chordRootName: rootName,
          role: byInterval[interval],
        ),
      ),
  ].join(' ');
}

int _degreeOrder(ChordToneRole role) => role.degreeOrder;

String _spellAlsoPlayedTones(
  ChordIdentity id,
  NoteParse parsed, {
  required Tonality tonality,
}) {
  final recognizedMask = id.toneRolesByInterval.keys.fold<int>(
    1 << id.rootPc,
    (mask, interval) => mask | (1 << ((id.rootPc + interval) % 12)),
  );
  final seen = <int>{};
  return [
    for (final note in parsed.ordered)
      if (seen.add(note.pc) && recognizedMask & (1 << note.pc) == 0)
        noteDisplayLabel(
          note.name != null
              ? normalizeNoteNameToAscii(note.name!)
              : pcToName(note.pc, tonality: tonality),
        ),
  ].join(' ');
}

int _pcMaskFrom(Iterable<int> notes) {
  var mask = 0;
  for (final n in notes) {
    mask |= 1 << (n % 12);
  }
  return mask;
}

String _quote(String s) => '"$s"';

String _formatUnrecognized(List<String> tokens) {
  final shown = tokens
      .take(_maxReportedUnrecognizedTokens)
      .map((token) {
        final value = token.length <= _maxReportedTokenCharacters
            ? token
            : '${token.substring(0, _maxReportedTokenCharacters)}...';
        return _quote(value);
      })
      .join(', ');
  final remaining = tokens.length - _maxReportedUnrecognizedTokens;
  return remaining > 0 ? '$shown, and $remaining more' : shown;
}
