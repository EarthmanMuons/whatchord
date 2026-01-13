// tool/chord_debug.dart
//
// Pure-Dart CLI harness for inspecting chord analysis ranking.
//
// Usage:
//   dart run tool/chord_debug.dart C E G D
//   dart run tool/chord_debug.dart C E G Bb D --bass=C
//   dart run tool/chord_debug.dart 60 64 67 74
//   dart run tool/chord_debug.dart 60 64 67 70 74 --top=12
//
// Optional flags:
//   --top=N           Number of ranked candidates to show (default 3)
//   --bass=PC         Override bass pitch class (e.g., C, Eb, F#)
//
//   --compact         Use a condensed, single-line-per-candidate output
//                     (useful for small screens or quick comparison)
//
//   --reasons=N       Show up to N score-reason tokens per candidate
//                     (default 3; ignored in --details mode)
//
//   --details         Show full score reasons and full ranking decision data
//                     (overrides --reasons and disables compact output)
//
//   --key=KEY         Tonality for tie-breaks/spelling (default C:maj).
//                     Examples: C, C:maj, A:min, Eb:maj, F#:min
//
//   --notation=STYLE  Chord notation style for symbol formatting (default textual).
//                     Examples: textual, symbolic

import 'dart:io';

import 'package:what_chord/features/theory/engine/engine.dart';
import 'package:what_chord/features/theory/models/chord_symbol.dart';
import 'package:what_chord/features/theory/models/key_signature.dart';
import 'package:what_chord/features/theory/models/note_spelling_policy.dart';
import 'package:what_chord/features/theory/models/tonality.dart';
import 'package:what_chord/features/theory/services/chord_symbol_builder.dart';
import 'package:what_chord/features/theory/services/note_spelling.dart';
import 'package:what_chord/features/theory/services/pitch_class.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Provide notes (pitch names or MIDI numbers).');
    exitCode = 2;
    return;
  }

  final top = _readIntFlag(args, 'top') ?? 3;
  final bassName = _readStringFlag(args, 'bass');
  final bassDisplayFromFlag = bassName == null
      ? null
      : normalizeNoteNameToAscii(bassName);

  final keyFlag = _readStringFlag(args, 'key') ?? 'C:maj';
  final tonality = _parseTonalityFlag(keyFlag);

  final ks = KeySignature.fromTonality(tonality);

  // Keep this for informational CLI output only. spellPitchClass() no longer
  // takes a policy; its output is driven primarily by role + tonality (and
  // optionally chordRootName).
  final spellingPolicy = NoteSpellingPolicy(preferFlats: ks.prefersFlats);

  final context = AnalysisContext(
    tonality: tonality,
    keySignature: ks,
    spellingPolicy: spellingPolicy,
  );

  // Notation style (default textual).
  final notationFlag = _readStringFlag(args, 'notation');
  final notation = _parseNotationFlag(notationFlag);

  // Extract positional args (notes), ignoring flags.
  final noteTokens = args.where((a) => !a.startsWith('--')).toList();
  if (noteTokens.isEmpty) {
    stderr.writeln('No notes provided.');
    exitCode = 2;
    return;
  }

  final parsed = _parseNotes(noteTokens);
  final midi = parsed.midiNotes;
  final pcs = parsed.pitchClasses;
  final inputPcLabels = parsed.pcLabels;

  if (pcs.isEmpty) {
    stderr.writeln('Could not parse any notes.');
    exitCode = 2;
    return;
  }

  final pcMask = _pcMaskFrom(pcs);
  final bassPc = bassName != null
      ? pitchClassFromNoteName(bassName)
      : (midi.isNotEmpty
            ? (midi.reduce((a, b) => a < b ? a : b) % 12)
            : pcs.first);

  final input = ChordInput(
    pcMask: pcMask,
    bassPc: bassPc,
    noteCount: midi.isNotEmpty ? midi.length : pcs.length,
  );
  stdout.writeln('input: $input');

  final pcNames =
      pcs
          .map((pc) {
            // If the user provided a name for this pc, prefer it.
            final preserved = inputPcLabels[pc];
            if (preserved != null) return preserved;

            // Otherwise (e.g., MIDI-only input), fall back to spelling.
            return _pcLabel(
              pc,
              context: context,
              chordRootName: null,
              role: null,
            );
          })
          .toSet()
          .toList()
        ..sort();

  stdout.writeln('pcs: ${pcNames.join(', ')}');

  final bassLabel =
      bassDisplayFromFlag ??
      inputPcLabels[bassPc] ??
      _pcLabel(bassPc, context: context, chordRootName: null, role: null);

  stdout.writeln('bass: $bassLabel');

  stdout.writeln(
    'key: ${context.tonality.displayName} (${context.keySignature.label})',
  );
  stdout.writeln('');
  stdout.writeln(
    'Note: sorting uses near-tie heuristics within ±${ChordCandidateRanking.nearTieWindow.toStringAsFixed(2)}',
  );
  stdout.writeln('');

  final results = ChordAnalyzer.analyzeDebug(
    input,
    context: context,
    take: top,
  );

  if (results.isEmpty) {
    stdout.writeln('No candidates.');
    return;
  }

  final bestScore = results.first.candidate.score;

  final compact = args.contains('--compact');
  final details = args.contains('--details');
  final reasonsTop = _readIntFlag(args, 'reasons') ?? (details ? 999 : 3);

  for (var i = 0; i < results.length; i++) {
    final r = results[i];
    final c = r.candidate;
    final id = c.identity;

    final symbol = ChordSymbolBuilder.formatIdentity(
      identity: id,
      tonality: context.tonality,
      notation: notation,
    );

    final score = c.score;
    final deltaBest = score - bestScore;
    final nearTie =
        deltaBest.abs() <= ChordCandidateRanking.nearTieWindow && i != 0;

    final rule = r.vsPrevious?.decidedByRule;

    // One-line summary.
    final rank = (i + 1).toString().padLeft(2);
    final sym = _padRight(symbol, 12);
    final scoreStr = score.toStringAsFixed(3).padLeft(7);
    final deltaStr = _fmtSigned(deltaBest, width: 7, decimals: 3);
    final tieStr = nearTie ? ' ~tie' : '';
    final ruleStr = (i == 0 || rule == null) ? '' : '  (vs prev: $rule)';

    stdout.writeln('$rank) $sym $scoreStr  Δ$deltaStr$tieStr$ruleStr');

    if (!compact) {
      stdout.writeln('     ${_formatIdentityCompact(id)}');

      // Role-aware chord-member spellings.
      final members = _formatChordMembersByRole(id, context: context);
      if (members.isNotEmpty) {
        stdout.writeln('     members: $members');
      }
    }

    // Reasons: tokenized & compact.
    final tokens = _reasonTokens(
      r.scoreReasons,
      take: reasonsTop,
      includeNormalize: true,
      details: details,
    );

    if (tokens.isNotEmpty) {
      // Indent 5 spaces to align under the candidate line.
      stdout.writeln('     ${tokens.join('  ')}');
    }

    // Optional full decision dump in --details mode.
    if (details && r.vsPrevious != null) {
      final d = r.vsPrevious!;
      stdout.writeln(
        '     decision: result=${d.result} scoreDelta=${d.scoreDelta.toStringAsFixed(3)}',
      );
    }

    if (!compact) stdout.writeln('');
  }
}

/// Converts a collection of notes into a pitch-class bitmask (bits 0..11).
int _pcMaskFrom(Iterable<int> notes) {
  var mask = 0;
  for (final n in notes) {
    mask |= 1 << (n % 12);
  }
  return mask;
}

/// Role-aware pitch-class label (pure dart).
///
/// Uses spellPitchClass() which is driven by role + tonality.
/// We pass chordRootName to give the speller extra context when appropriate.
String _pcLabel(
  int pc, {
  required AnalysisContext context,
  required String? chordRootName,
  required ChordToneRole? role,
}) {
  return spellPitchClass(
    pc,
    tonality: context.tonality,
    chordRootName: chordRootName,
    role: role,
  );
}

/// Formats chord members using ChordIdentity.toneRolesByInterval.
///
/// Output example:
///   root=C  third=E  fifth=G  flat7=Bb  sharp11=F#
///
/// Notes:
/// - Always includes root (interval 0).
/// - Includes all intervals present in toneRolesByInterval.
/// - Sorts by interval for stable output.
String _formatChordMembersByRole(
  ChordIdentity id, {
  required AnalysisContext context,
}) {
  // Determine the chord root name once, then reuse for all member spellings.
  final rootName = _pcLabel(
    id.rootPc,
    context: context,
    chordRootName: null,
    role: ChordToneRole.root,
  );

  final entries = <MapEntry<int, ChordToneRole>>[
    const MapEntry<int, ChordToneRole>(0, ChordToneRole.root),
    ...id.toneRolesByInterval.entries,
  ];

  // De-dup by interval (toneRolesByInterval may or may not include 0).
  final byInterval = <int, ChordToneRole>{};
  for (final e in entries) {
    byInterval[e.key] = e.value;
  }

  final sortedIntervals = byInterval.keys.toList()..sort();

  final parts = <String>[];
  for (final interval in sortedIntervals) {
    final role = byInterval[interval]!;
    final pc = (id.rootPc + interval) % 12;

    final name = _pcLabel(
      pc,
      context: context,
      chordRootName: rootName,
      role: role,
    );

    // Use role.name (enum name) as the token key.
    parts.add('${role.name}=$name');
  }

  return parts.join('  ');
}

({List<int> midiNotes, List<int> pitchClasses, Map<int, String> pcLabels})
_parseNotes(List<String> tokens) {
  final midi = <int>[];
  final pcs = <int>[];

  // First-seen label wins per pitch class.
  final pcLabels = <int, String>{};

  for (final t in tokens) {
    final raw = t.trim();
    if (raw.isEmpty) continue;

    final asInt = int.tryParse(raw);
    if (asInt != null) {
      midi.add(asInt);
      final pc = asInt % 12;
      pcs.add(pc);
      // For MIDI inputs, we *don't* have a user spelling; leave label unset.
      continue;
    }

    // Preserve the user's accidental choice (including glyph accidentals),
    // but normalize whitespace and casing in a lightweight way.
    // If you'd prefer to canonicalize glyphs to ASCII, use normalizeNoteNameToAscii.
    final preserved = raw;

    final pc = pitchClassFromNoteName(raw);
    pcs.add(pc);

    pcLabels.putIfAbsent(pc, () => preserved);
  }

  return (midiNotes: midi, pitchClasses: pcs, pcLabels: pcLabels);
}

Tonality _parseTonalityFlag(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return const Tonality('C', TonalityMode.major);

  // Accept: "C", "C:maj", "C:major", "A:min", "A:minor"
  // Also accept "A minor" / "C major" (space separated).
  //
  // IMPORTANT: don't destroy glyph accidentals. We'll normalize accidentals
  // to ASCII after we isolate the tonic token.
  final compact = s.replaceAll(RegExp(r'\s+'), '');

  // Split on ":" if present (preferred syntax).
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

  // Mode parsing is case-insensitive.
  final modeToken = (modePart ?? '').toLowerCase();
  var mode = TonalityMode.major;

  if (modePart != null) {
    if (modeToken == 'min' || modeToken == 'minor') mode = TonalityMode.minor;
    if (modeToken == 'maj' || modeToken == 'major') mode = TonalityMode.major;
  } else {
    // If user typed "...minor" or "...major" without colon, handle it.
    final lower = tonicPart.toLowerCase();

    if (lower.endsWith('minor')) {
      mode = TonalityMode.minor;
      tonicPart = tonicPart.substring(0, tonicPart.length - 'minor'.length);
    } else if (lower.endsWith('major')) {
      mode = TonalityMode.major;
      tonicPart = tonicPart.substring(0, tonicPart.length - 'major'.length);
    } else if (lower.endsWith('min')) {
      mode = TonalityMode.minor;
      tonicPart = tonicPart.substring(0, tonicPart.length - 'min'.length);
    } else if (lower.endsWith('maj')) {
      mode = TonalityMode.major;
      tonicPart = tonicPart.substring(0, tonicPart.length - 'maj'.length);
    }
  }

  // Canonicalize tonic:
  // - trims again (defensive)
  // - converts ♯/♭/𝄪/𝄫 to ASCII #/b/x/bb
  // - uppercases the letter
  final tonicAscii = normalizeNoteNameToAscii(tonicPart);

  return Tonality(tonicAscii, mode);
}

ChordNotationStyle _parseNotationFlag(String? raw) {
  if (raw == null) return ChordNotationStyle.textual;

  final s = raw.trim().toLowerCase();
  if (s.isEmpty) return ChordNotationStyle.textual;

  // Allow a few aliases so the CLI remains ergonomic.
  // Keep this intentionally small: fail fast on unknown values.
  return switch (s) {
    'textual' => ChordNotationStyle.textual,
    'symbolic' => ChordNotationStyle.symbolic,

    // Common mental-model aliases.
    'text' => ChordNotationStyle.textual,
    'symbol' => ChordNotationStyle.symbolic,

    _ => _failUnknownNotation(raw),
  };
}

Never _failUnknownNotation(String raw) {
  stderr.writeln('Unknown --notation value: "$raw"');
  stderr.writeln('Valid: textual, symbolic');
  exitCode = 2;
  throw StateError('Invalid --notation=$raw');
}

String _formatIdentityCompact(ChordIdentity id) {
  // Start from the model's canonical toString().
  var s = id.toString();

  // Strip enum type prefixes for readability.
  s = s.replaceAll('ChordQualityToken.', '');
  s = s.replaceAll('ChordExtension.', '');
  s = s.replaceAll('ChordToneRole.', '');

  return s;
}

int? _readIntFlag(List<String> args, String name) {
  final prefix = '--$name=';
  for (final a in args) {
    if (a.startsWith(prefix)) {
      return int.tryParse(a.substring(prefix.length));
    }
  }
  return null;
}

String? _readStringFlag(List<String> args, String name) {
  final prefix = '--$name=';
  for (final a in args) {
    if (a.startsWith(prefix)) {
      return a.substring(prefix.length);
    }
  }
  return null;
}

String _padRight(String s, int width) {
  if (s.length >= width) return s;
  return s + (' ' * (width - s.length));
}

String _fmtSigned(double v, {required int width, int decimals = 2}) {
  final sign = v >= 0 ? '+' : '';
  final s = '$sign${v.toStringAsFixed(decimals)}';
  return s.padLeft(width);
}

/// Converts ScoreReason entries into compact CLI tokens.
/// Example tokens:
///   req+12  miss-6  opt+3  bass+1  alt-0.6  raw=8.40 denom=1.73 => 4.85
List<String> _reasonTokens(
  List<ScoreReason> reasons, {
  required int take,
  required bool includeNormalize,
  required bool details,
}) {
  if (reasons.isEmpty) return const [];

  // Pull out normalize (info) separately.
  ScoreReason? normalize;
  final deltas = <ScoreReason>[];

  for (final r in reasons) {
    final isNormalize = r.label.toLowerCase() == 'normalize';
    if (isNormalize) {
      normalize = r;
      continue;
    }
    // Ignore pure zero deltas unless in details mode.
    if (!details && r.delta == 0.0) continue;
    deltas.add(r);
  }

  // Sort delta reasons by absolute impact.
  deltas.sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));

  // Take top N delta reasons.
  final picked = deltas.take(take).toList(growable: false);

  final tokens = <String>[];
  for (final r in picked) {
    tokens.add(_formatDeltaToken(r));
  }

  if (includeNormalize && normalize != null && normalize.detail != null) {
    // IMPORTANT: render normalize as info, not +0.00.
    tokens.add(normalize.detail!);
  }

  return tokens;
}

String _formatDeltaToken(ScoreReason r) {
  // Map long labels to compact keys for CLI.
  final key = switch (r.label) {
    'required tones' => 'req',
    'missing required' => 'miss',
    'optional tones' => 'opt',
    'penalty tones' => 'pen',
    'extras' => 'extra',
    'bass fit' => 'bass',
    'alterations penalty' => 'alt',
    'tonality bias' => 'ton',
    _ => r.label.replaceAll(' ', ''),
  };

  // Compact number formatting: integers look cleaner when whole.
  final v = r.delta;
  final sign = v >= 0 ? '+' : '';
  final asInt = v == v.roundToDouble();

  final num = asInt ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  // If detail is tiny (like count=3), include it in brackets.
  final detail = (r.detail == null || r.detail!.isEmpty)
      ? ''
      : (r.detail!.length <= 10 ? '[${r.detail}]' : '');

  return '$key$sign$num$detail';
}
