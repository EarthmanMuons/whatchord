import 'dart:io';

import 'package:what_chord/features/theory/engine/engine.dart';
import 'package:what_chord/features/theory/models/chord_symbol.dart';
import 'package:what_chord/features/theory/models/key_signature.dart';
import 'package:what_chord/features/theory/models/note_spelling_policy.dart';
import 'package:what_chord/features/theory/models/tonality.dart';
import 'package:what_chord/features/theory/services/chord_symbol_formatter.dart';
import 'package:what_chord/features/theory/services/note_spelling.dart';
import 'package:what_chord/features/theory/services/pitch_class.dart';

/// Usage:
///   dart run tool/chord_debug.dart C E G D
///   dart run tool/chord_debug.dart C E G Bb D --bass=C
///   dart run tool/chord_debug.dart 60 64 67 74
///   dart run tool/chord_debug.dart 60 64 67 70 74 --top=12
///
/// Optional flags:
///   --top=N           Number of ranked candidates to show (default 5)
///   --bass=PC         Override bass pitch class (e.g., C, Eb, F#)
///
///   --compact         Use a condensed, single-line-per-candidate output
///                     (useful for small screens or quick comparison)
///
///   --reasons=N       Show up to N score-reason tokens per candidate
///                     (default 3; ignored in --details mode)
///
///   --details         Show full score reasons and full ranking decision data
///                     (overrides --reasons and disables compact output)
///
///   --key=KEY         Tonality for tie-breaks/spelling (default C:maj).
///                     Examples: C, C:maj, A:min, Eb:maj, F#:min
void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Provide notes (pitch names or MIDI numbers).');
    exitCode = 2;
    return;
  }

  final top = _readIntFlag(args, 'top') ?? 5;
  final bassName = _readStringFlag(args, 'bass');

  final keyFlag = _readStringFlag(args, 'key') ?? 'C:maj';
  final tonality = _parseTonalityFlag(keyFlag);

  final ks = KeySignature.fromTonality(tonality);
  final spellingPolicy = NoteSpellingPolicy(preferFlats: ks.prefersFlats);

  final context = AnalysisContext(
    tonality: tonality,
    keySignature: ks,
    spellingPolicy: spellingPolicy,
  );

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

  if (pcs.isEmpty) {
    stderr.writeln('Could not parse any notes.');
    exitCode = 2;
    return;
  }

  final pcMask = _toPcMask(pcs);
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
  stdout.writeln('Input: $input');

  final pcNames =
      pcs.map((pc) => pcToName(pc, tonality: context.tonality)).toSet().toList()
        ..sort();
  stdout.writeln('pcs: ${pcNames.join(', ')}');
  stdout.writeln('bass: ${pcToName(bassPc, tonality: tonality)}');
  stdout.writeln(
    'key: ${context.tonality.displayName} (${context.keySignature.label})',
  );
  stdout.writeln(
    'spelling: ${context.spellingPolicy.preferFlats ? 'flats' : 'sharps'}',
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

  final style = ChordSymbolStyle.leadSheet;
  final bestScore = results.first.candidate.score;

  final compact = args.contains('--compact');
  final details = args.contains('--details');
  final reasonsTop = _readIntFlag(args, 'reasons') ?? (details ? 999 : 3);

  for (var i = 0; i < results.length; i++) {
    final r = results[i];
    final c = r.candidate;
    final id = c.identity;

    final symbol = ChordSymbolFormatter.formatIdentity(
      identity: id,
      tonality: context.tonality,
      style: style,
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

int _toPcMask(Iterable<int> pcs) {
  var mask = 0;
  for (final pc in pcs) {
    mask |= (1 << (pc % 12));
  }
  return mask;
}

({List<int> midiNotes, List<int> pitchClasses}) _parseNotes(
  List<String> tokens,
) {
  final midi = <int>[];
  final pcs = <int>[];

  for (final t in tokens) {
    final tt = t.trim();
    if (tt.isEmpty) continue;

    final asInt = int.tryParse(tt);
    if (asInt != null) {
      midi.add(asInt);
      pcs.add(asInt % 12);
      continue;
    }

    pcs.add(pitchClassFromNoteName(tt));
  }

  return (midiNotes: midi, pitchClasses: pcs);
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
    // Your detail currently is like: "raw=8.40 denom=1.73"
    // Optionally, you can include the final score too if you add it to the detail.
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
