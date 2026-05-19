// tool/chord_debug.dart
//
// Pure-Dart CLI harness for inspecting chord analysis ranking.
//
// Usage: dart run tool/chord_debug.dart [notes...] [options]
//
// Run with --help for examples and options.

import 'dart:io';

import 'package:whatchord/features/theory/domain/theory_domain.dart';
import 'package:whatchord/features/theory/presentation/models/chord_symbol.dart';
import 'package:whatchord/features/theory/presentation/services/chord_symbol_builder.dart';
import 'package:whatchord/features/theory/presentation/services/note_display_formatter.dart';

const _usage = '''
Usage:
  dart run tool/chord_debug.dart [notes...] [options]

Examples:
  dart run tool/chord_debug.dart C E G D
  dart run tool/chord_debug.dart C E G Bb D --bass=C
  dart run tool/chord_debug.dart 60 64 67 74
  dart run tool/chord_debug.dart 60 64 67 70 74 --top=12

Notes may be pitch names or MIDI note numbers.

Options:
  -h, --help             Show this help text.
  -t, --top=N            Number of ranked candidates to show. Default: 4.
  -b, --bass=PC          Override bass pitch class, for example C, Eb, F#.
  -k, --key=KEY          Tonality for tie-breaks/spelling. Default: C:maj.
                         Examples: C, C:maj, A:min, Eb:maj, F#:min.
  -n, --notation=STYLE   Chord symbol style. Valid: textual, symbolic.
                         Default: textual.
  -v, --verbose          Include input and ChordIdentity diagnostics.
  -c, --compact          Use a condensed, single-line-per-candidate output.
''';

void main(List<String> args) {
  if (_hasFlag(args, 'help', 'h')) {
    stdout.write(_usage);
    return;
  }

  if (args.isEmpty) {
    stderr.writeln('Provide notes (pitch names or MIDI numbers).');
    stderr.writeln('');
    stderr.write(_usage);
    exitCode = 2;
    return;
  }

  final top = _readIntFlag(args, 'top', 't') ?? 4;
  final bassName = _readStringFlag(args, 'bass', 'b');
  final bassDisplayFromFlag = bassName == null
      ? null
      : _displayNoteLabel(bassName);

  final keyFlag = _readStringFlag(args, 'key', 'k') ?? 'C:maj';
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

  final notationFlag = _readStringFlag(args, 'notation', 'n');
  final notation = _parseNotationFlag(notationFlag);

  // Extract positional args (notes), ignoring flags.
  final noteTokens = _readNoteTokens(args);
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

  final pcDisplays = pcs.toSet().map((pc) {
    // If the user provided a name for this pc, prefer it.
    final preserved = inputPcLabels[pc];
    if (preserved != null) return (label: _displayNoteLabel(preserved), pc: pc);

    // Otherwise (e.g., MIDI-only input), fall back to spelling.
    return (
      label: _displayNoteLabel(
        _pcLabel(pc, context: context, chordRootName: null, role: null),
      ),
      pc: pc,
    );
  }).toList()..sort((a, b) => a.label.compareTo(b.label));

  final pcNames = [for (final display in pcDisplays) display.label];

  final bassLabel =
      bassDisplayFromFlag ??
      _displayOptionalNoteLabel(inputPcLabels[bassPc]) ??
      _displayNoteLabel(
        _pcLabel(bassPc, context: context, chordRootName: null, role: null),
      );

  final verbose = _hasFlag(args, 'verbose', 'v');
  final compact = _hasFlag(args, 'compact', 'c');
  if (verbose && !compact) {
    stdout.writeln(
      'input: noteCount=${input.noteCount}  bassPc=${input.bassPc}  '
      'mask=${_formatPcMask(input.pcMask)} (bits 11..0)',
    );
    stdout.writeln('pc numbers: ${_formatPcNumbers(pcDisplays)}');
  }
  if (!compact) {
    stdout.writeln(
      'pcs: ${pcNames.join(' ')}  |  bass: $bassLabel (pc $bassPc)  |  key: '
      '${tonalityDisplayLabel(context.tonality)}',
    );
    stdout.writeln('');
  }

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

  for (var i = 0; i < results.length; i++) {
    final r = results[i];
    final c = r.candidate;
    final id = c.identity;

    final symbol = chordSymbolDisplayLabel(
      ChordSymbolBuilder.fromIdentity(
        identity: id,
        tonality: context.tonality,
        notation: notation,
      ),
      spacing: ChordSymbolDisplaySpacing.plain,
    );

    final score = c.score;
    final deltaBest = score - bestScore;
    final nearTie =
        deltaBest.abs() <= ChordCandidateRanking.nearTieWindow && i != 0;

    final rule = _formatRankingRule(r.vsPrevious?.decidedByRule);

    // One-line summary.
    final rank = (i + 1).toString().padLeft(2);
    final sym = _padRight(symbol, 12);
    final scoreStr = score.toStringAsFixed(2).padLeft(6);
    final deltaStr = i == 0
        ? ''
        : '  Δ${_fmtSigned(deltaBest, width: 6, decimals: 2)}';
    final tieStr = nearTie ? ' ~tie' : '';
    final ruleStr = compact && i != 0 && rule.isNotEmpty
        ? '  (vs prev: $rule)'
        : '';

    stdout.writeln('$rank) $sym $scoreStr$deltaStr$tieStr$ruleStr');

    if (compact) continue;

    if (i != 0 && rule.isNotEmpty) {
      stdout.writeln('     (vs prev: $rule)');
    }

    if (verbose) {
      stdout.writeln('     ${_formatIdentityCompact(id)}');
    }

    // Role-aware chord-member spellings.
    final members = _formatChordMembersByRole(id, context: context);
    if (members.isNotEmpty) {
      stdout.writeln('     members: $members');
    }

    // Reasons: tokenized & compact.
    final tokens = _reasonTokens(
      r.scoreReasons,
      includeNormalize: true,
      includeReasonDetails: verbose,
      includeNormalizationDenom: verbose,
      requiredToneCount: _requiredToneCountFromReasons(r.scoreReasons),
    );

    if (tokens.isNotEmpty) {
      // Indent 5 spaces to align under the candidate line.
      stdout.writeln('     scoring: ${tokens.join('  ')}');
    }

    stdout.writeln('');
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
    parts.add('${role.name}=${_displayNoteLabel(name)}');
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

String _formatIdentityCompact(ChordIdentity id) {
  // Start from the model's canonical toString().
  var s = id.toString();

  // Strip enum type prefixes for readability.
  s = s.replaceAll('ChordQualityToken.', '');
  s = s.replaceAll('ChordExtension.', '');
  s = s.replaceAll('ChordToneRole.', '');

  return s;
}

ChordNotationStyle _parseNotationFlag(String? raw) {
  if (raw == null) return ChordNotationStyle.textual;

  final s = raw.trim().toLowerCase();
  if (s.isEmpty) return ChordNotationStyle.textual;

  return switch (s) {
    'textual' || 'text' => ChordNotationStyle.textual,
    'symbolic' || 'symbol' => ChordNotationStyle.symbolic,
    _ => _failUnknownNotation(raw),
  };
}

Never _failUnknownNotation(String raw) {
  stderr.writeln('Unknown --notation value: "$raw"');
  stderr.writeln('Valid: textual, symbolic');
  exit(2);
}

bool _hasFlag(List<String> args, String name, String shortName) {
  return args.contains('--$name') || args.contains('-$shortName');
}

int? _readIntFlag(List<String> args, String name, String shortName) {
  final value = _readStringFlag(args, name, shortName);
  return value == null ? null : int.tryParse(value);
}

String? _readStringFlag(List<String> args, String name, String shortName) {
  final long = '--$name';
  final longPrefix = '$long=';
  final short = '-$shortName';
  final shortPrefix = '$short=';

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith(longPrefix)) {
      return arg.substring(longPrefix.length);
    }
    if (arg == long && i + 1 < args.length) {
      return args[i + 1];
    }
    if (arg.startsWith(shortPrefix)) {
      return arg.substring(shortPrefix.length);
    }
    if (arg == short && i + 1 < args.length) {
      return args[i + 1];
    }
  }

  return null;
}

List<String> _readNoteTokens(List<String> args) {
  const valueFlags = {
    '--top',
    '--bass',
    '--key',
    '--notation',
    '-t',
    '-b',
    '-k',
    '-n',
  };

  final out = <String>[];
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('--') || RegExp(r'^-[A-Za-z]').hasMatch(arg)) {
      final flag = arg.split('=').first;
      if (valueFlags.contains(flag) &&
          !arg.contains('=') &&
          i + 1 < args.length) {
        i++;
      }
      continue;
    }
    out.add(arg);
  }
  return out;
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

String _displayNoteLabel(String noteName) {
  return noteDisplayLabel(normalizeNoteNameToAscii(noteName));
}

String? _displayOptionalNoteLabel(String? noteName) {
  if (noteName == null) return null;
  return _displayNoteLabel(noteName);
}

String _formatPcMask(int mask) => mask.toRadixString(2).padLeft(12, '0');

String _formatPcNumbers(List<({String label, int pc})> pcDisplays) {
  return [
    for (final display in pcDisplays) '${display.label}=${display.pc}',
  ].join('  ');
}

/// Converts ScoreReason entries into compact CLI tokens.
/// Example tokens:
///   req+12  miss-6  opt+3  bass+1  alt-0.6  => 8.40 raw, 4.85 final
List<String> _reasonTokens(
  List<ScoreReason> reasons, {
  required bool includeNormalize,
  required bool includeReasonDetails,
  required bool includeNormalizationDenom,
  required int requiredToneCount,
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
    if (r.delta == 0.0) continue;
    deltas.add(r);
  }

  // Sort delta reasons by absolute impact.
  deltas.sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));

  final tokens = <String>[];
  for (final r in deltas) {
    tokens.add(
      _formatDeltaToken(r, includeReasonDetails: includeReasonDetails),
    );
  }

  if (includeNormalize && normalize != null && normalize.detail != null) {
    // IMPORTANT: render normalize as info, not +0.00.
    tokens.add(
      _formatNormalizeToken(
        normalize.detail!,
        includeDenom: includeNormalizationDenom,
        requiredToneCount: requiredToneCount,
      ),
    );
  }

  return tokens;
}

String _formatRankingRule(String? rule) {
  if (rule == null || rule.isEmpty) return '';
  return rule.replaceAll(RegExp(r'[()]'), '').replaceAll(RegExp(r'\s+'), ' ');
}

String _formatNormalizeToken(
  String detail, {
  required bool includeDenom,
  required int requiredToneCount,
}) {
  final match = RegExp(
    r'^raw=([^\s]+) denom=([^\s]+) => (.+)$',
  ).firstMatch(detail);
  if (match == null) return detail;

  final raw = match.group(1)!;
  final denom = match.group(2)!;
  final normalized = match.group(3)!;
  if (includeDenom) {
    return '=>  $raw raw / sqrt($requiredToneCount required tones, denom=$denom), $normalized final';
  }
  return '=>  $raw raw, $normalized final';
}

int _requiredToneCountFromReasons(List<ScoreReason> reasons) {
  for (final reason in reasons) {
    if (reason.label != 'required tones') continue;
    final detail = reason.detail;
    if (detail == null) continue;
    final match = RegExp(r'^count=(\d+)$').firstMatch(detail);
    if (match != null) return int.parse(match.group(1)!);
  }
  return 1;
}

String _formatDeltaToken(ScoreReason r, {required bool includeReasonDetails}) {
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
  final detail =
      (!includeReasonDetails || r.detail == null || r.detail!.isEmpty)
      ? ''
      : (r.detail!.length <= 10 ? '[${r.detail}]' : '');

  return '$key$sign$num$detail';
}
