// tool/chord_debug.dart
//
// Pure-Dart CLI harness for inspecting chord analysis ranking.
//
// Usage: dart run tool/chord_debug.dart [notes...] [options]
//
// Run with --help for examples and options.

import 'dart:convert';
import 'dart:io';

import 'package:whatchord/features/theory/domain/theory_domain.dart';
import 'package:whatchord/features/theory/presentation/models/chord_symbol.dart';
import 'package:whatchord/features/theory/presentation/services/chord_symbol_builder.dart';
import 'package:whatchord/features/theory/presentation/services/harte_chord_formatter.dart';
import 'package:whatchord/features/theory/presentation/services/note_display_formatter.dart';

import 'src/chord_id_engine.dart';

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
  -t, --top=N            Number of ranked candidates to show. Default: 5.
  -b, --bass=PC          Set the bass pitch class, adding it to the sounding
                         notes when needed.
  -k, --key=KEY          Tonality for tie-breaks/spelling. Default: C:maj.
                         Examples: C, C:maj, A:min, Eb:maj, F#:min.
  -n, --notation=STYLE   Chord symbol style. Valid: textual, symbolic.
                         Default: textual.
      --spelling=MODE    How typed note spellings affect ranking.
                         Valid: pc, auto, strict. Default: pc.
      --registers=MODE   How the voicing octaves are read for ranking.
                         Valid: exact, synthesized, none. Default: exact for
                         MIDI input, synthesized (order only) for note names.
  -f, --format=FORMAT    Output format. Valid: text, json. Default: text.
      --json             Alias for --format=json.
  -v, --verbose          Include input, ChordIdentity, and played/missing/extra
                         tone-bucket diagnostics.
  -c, --compact          Use a condensed, single-line-per-candidate output.
''';

void main(List<String> args) {
  if (_hasFlag(args, 'help', 'h')) {
    stdout.write(_usage);
    return;
  }

  final unknownFlags = _unknownFlags(args);
  if (unknownFlags.isNotEmpty) {
    stderr.writeln(
      'Unknown flag${unknownFlags.length == 1 ? '' : 's'}: '
      '${unknownFlags.join(', ')}',
    );
    stderr.writeln('Use --help to see supported options.');
    exitCode = 2;
    return;
  }

  if (args.isEmpty) {
    stderr.writeln('Provide notes (pitch names or MIDI numbers).');
    stderr.writeln('');
    stderr.write(_usage);
    exitCode = 2;
    return;
  }

  final top = _readIntFlag(args, 'top', 't') ?? 5;
  final bassName = _readStringFlag(args, 'bass', 'b');

  final keyFlag = _readStringFlag(args, 'key', 'k') ?? 'C:maj';
  final tonality = parseTonality(keyFlag);

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
  final spellingMode = _parseSpellingModeFlag(
    _readStringFlag(args, 'spelling', ''),
  );
  final registersMode = _parseRegistersFlag(
    _readStringFlag(args, 'registers', ''),
  );
  final outputFormat = _parseOutputFormatFlag(args);

  // Extract positional args (notes), ignoring flags.
  final noteTokens = splitNoteTokens(_readNoteTokens(args).join(' '));
  if (noteTokens.isEmpty) {
    stderr.writeln('No notes provided.');
    exitCode = 2;
    return;
  }

  final prepared = prepareChordDebugInput(
    noteTokens: noteTokens,
    bassName: bassName,
    context: context,
  );
  if (prepared == null) {
    stderr.writeln('Could not parse any notes.');
    exitCode = 2;
    return;
  }
  final input = prepared.input;
  final pcDisplays = prepared.pcDisplays;
  final bassLabel = prepared.bassLabel;

  // Input notes in entry order, matching the website demo's "Notes" line.
  final noteLabels = inputNoteLabels(prepared.parsed, tonality: tonality);

  final verbose = _hasFlag(args, 'verbose', 'v');
  final compact = _hasFlag(args, 'compact', 'c');

  // MIDI numbers carry exact octaves; note names give order only. The
  // --registers flag overrides this to exercise either path from the CLI.
  final debugMidi = prepared.parsed.midiNotes;
  final orderedPcs = [for (final note in prepared.parsed.ordered) note.pc];
  final voicing = _buildDebugVoicing(
    mode: registersMode,
    midi: debugMidi,
    orderedPitchClasses: orderedPcs,
  );

  final baseResults = ChordAnalyzer.analyzeDebug(
    input,
    context: context,
    voicing: voicing,
    take: spellingMode == ChordDebugSpellingMode.pc
        ? top
        : (top < 24 ? 24 : top),
  );
  final results = _applySpellingMode(
    baseResults,
    parsed: prepared.parsed,
    context: context,
    spellingMode: spellingMode,
    take: top,
    voicing: voicing,
  );

  if (outputFormat == _OutputFormat.json) {
    _writeJsonOutput(
      input: input,
      context: context,
      notation: notation,
      pcDisplays: pcDisplays,
      bassLabel: bassLabel,
      spellingMode: spellingMode,
      parsed: prepared.parsed,
      results: results,
    );
    return;
  }

  if (verbose && !compact) {
    stdout.writeln(
      'input: noteCount=${input.noteCount}  bassPc=${input.bassPc}  '
      'mask=${_formatPcMask(input.pcMask)} (bits 11..0)',
    );
    stdout.writeln('pc numbers: ${_formatPcNumbers(pcDisplays)}');
    stdout.writeln('spelling: ${spellingMode.wireName}');
  }
  if (!compact) {
    stdout.writeln(
      'notes: ${noteLabels.join(' ')}  |  bass: $bassLabel (pc ${input.bassPc})  |  '
      'key: ${tonalityDisplayLabel(context.tonality)}',
    );
    stdout.writeln('');
  }

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
    );

    final score = c.score;
    final deltaBest = score - bestScore;
    final nearTie = i != 0 && ChordCandidateRanking.isNearTie(bestScore, score);

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
      final spelling = _spellingEvidenceFor(
        id,
        parsed: prepared.parsed,
        context: context,
        spellingMode: spellingMode,
      );
      final spellingText = _formatSpellingEvidence(spelling);
      if (spellingText.isNotEmpty) {
        stdout.writeln('     spelling: $spellingText');
      }
    }

    // Role-aware chord-member spellings.
    final members = _formatChordMembersByRole(id, context: context);
    if (members.isNotEmpty) {
      stdout.writeln('     members: $members');
    }

    // Played/missing/also-played tone buckets, mirroring the app's tone ledger.
    if (verbose) {
      stdout.writeln(
        '     tones: ${_formatToneBuckets(id, r.scoreReasons, context: context)}',
      );
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
  final rootName = spellChordRoot(id, tonality: context.tonality);

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

/// Formats the played, missing, and also-played tone buckets for a candidate,
/// mirroring the app's "Why This Chord?" tone ledger.
///
/// Output example:
///   chord=[1:C 3:E 5:G*]  missing=[7:B]  also=[#9:D#]
///
/// Played chord tones come from the final identity, while missing tones remain
/// template-based. The bass tone is marked with a trailing `*`.
String _formatToneBuckets(
  ChordIdentity id,
  List<ScoreReason> reasons, {
  required AnalysisContext context,
}) {
  final chordMask = id.toneRolesByInterval.keys.fold<int>(
    0,
    (mask, interval) => mask | (1 << interval),
  );
  final missingMask = _maskForReason(reasons, 'missing required');
  final alsoMask = id.presentIntervalsMask & ~chordMask;

  final segments = <String>[
    'chord=[${_formatTones(id, chordMask, context: context)}]',
  ];

  final missing = _formatTones(id, missingMask, context: context);
  if (missing.isNotEmpty) segments.add('missing=[$missing]');

  final also = _formatTones(id, alsoMask, context: context);
  if (also.isNotEmpty) segments.add('also=[$also]');

  return segments.join('  ');
}

/// Returns the root-relative interval mask the analyzer recorded for [label],
/// or 0 when that reason carries no tone set.
int _maskForReason(List<ScoreReason> reasons, String label) {
  for (final reason in reasons) {
    if (reason.label == label) return reason.intervals ?? 0;
  }
  return 0;
}

/// Formats the tones in [mask] as `degree:note` tokens, ordered by chord degree
/// when roles are available and marking the bass tone with a trailing `*`.
String _formatTones(
  ChordIdentity id,
  int mask, {
  required AnalysisContext context,
}) {
  final parts = <String>[];
  final intervals =
      [
        for (var interval = 0; interval < 12; interval++)
          if ((mask & (1 << interval)) != 0) interval,
      ]..sort((a, b) {
        final roleA = id.toneRolesByInterval[a];
        final roleB = id.toneRolesByInterval[b];
        if (roleA == null || roleB == null) return a.compareTo(b);
        final degreeComparison = roleA.degreeOrder.compareTo(roleB.degreeOrder);
        return degreeComparison != 0 ? degreeComparison : a.compareTo(b);
      });
  for (final interval in intervals) {
    final pc = {(id.rootPc + interval) % 12};
    final degree = theoryTokenDisplayLabel(
      ChordMemberDegreeFormatter.formatDegrees(
        identity: id,
        pitchClasses: pc,
      ).first,
    );
    final note = _displayNoteLabel(
      ChordMemberSpeller.spellMembers(
        identity: id,
        pitchClasses: pc,
        tonality: context.tonality,
      ).first,
    );
    final bassMark = pc.first == id.bassPc ? '*' : '';
    parts.add('$degree:$note$bassMark');
  }
  return parts.join(' ');
}

/// Parsed analysis input shared by the text, JSON, and batch output paths.
typedef ChordDebugPrepared = ({
  ChordInput input,
  List<({String label, int pc})> pcDisplays,
  String bassLabel,
  NoteParse parsed,
});

/// Parses [noteTokens] (with an optional explicit [bassName]) into the
/// [ChordInput], per-pitch display labels, and bass label used by every output
/// path. Returns null when no notes could be parsed. Shared with the batch
/// entry point (tool/chord_oracle_batch.dart) so its results match the CLI.
ChordDebugPrepared? prepareChordDebugInput({
  required List<String> noteTokens,
  String? bassName,
  required AnalysisContext context,
}) {
  final parsed = parseNotes(noteTokens);
  final midi = parsed.midiNotes;
  final pcs = parsed.pitchClasses;
  final inputPcLabels = parsed.pcLabels;

  if (pcs.isEmpty) return null;

  final bassPc = bassName != null
      ? pitchClassFromNoteName(bassName)
      : (midi.isNotEmpty
            ? (midi.reduce((a, b) => a < b ? a : b) % 12)
            : pcs.first);
  final parsedPcMask = _pcMaskFrom(pcs);
  final bassWasMissing = (parsedPcMask & (1 << bassPc)) == 0;
  final pcMask = parsedPcMask | (1 << bassPc);

  final input = ChordInput(
    pcMask: pcMask,
    bassPc: bassPc,
    noteCount:
        (midi.isNotEmpty ? midi.length : pcs.length) + (bassWasMissing ? 1 : 0),
  );

  final pcDisplays = {...pcs, bassPc}.map((pc) {
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

  final bassDisplayFromFlag = bassName == null
      ? null
      : _displayNoteLabel(bassName);
  final bassLabel =
      bassDisplayFromFlag ??
      _displayOptionalNoteLabel(inputPcLabels[bassPc]) ??
      _displayNoteLabel(
        _pcLabel(bassPc, context: context, chordRootName: null, role: null),
      );

  return (
    input: input,
    pcDisplays: pcDisplays,
    bassLabel: bassLabel,
    parsed: parsed,
  );
}

List<RankedCandidateDebug> _applySpellingMode(
  List<RankedCandidateDebug> baseResults, {
  required NoteParse parsed,
  required AnalysisContext context,
  required ChordDebugSpellingMode spellingMode,
  required int take,
  ObservedVoicing? voicing,
}) {
  if (spellingMode == ChordDebugSpellingMode.pc || !_hasNamedInput(parsed)) {
    return baseResults.take(take).toList(growable: false);
  }

  final adjusted = [
    for (final result in baseResults)
      _adjustCandidateForSpelling(
        result,
        parsed: parsed,
        context: context,
        spellingMode: spellingMode,
      ),
  ];

  final ranked = ChordCandidateRanking.rank(
    adjusted,
    (r) => r.candidate,
    tonality: context.tonality,
    voicing: voicing,
  ).take(take).toList(growable: false);

  return [
    for (var i = 0; i < ranked.length; i++)
      RankedCandidateDebug(
        candidate: ranked[i].candidate,
        scoreReasons: ranked[i].scoreReasons,
        template: ranked[i].template,
        vsPrevious: i == 0
            ? null
            : ChordCandidateRanking.explain(
                ranked[i - 1].candidate,
                ranked[i].candidate,
                tonality: context.tonality,
                voicing: voicing,
              ),
      ),
  ];
}

RankedCandidateDebug _adjustCandidateForSpelling(
  RankedCandidateDebug result, {
  required NoteParse parsed,
  required AnalysisContext context,
  required ChordDebugSpellingMode spellingMode,
}) {
  final evidence = _spellingEvidenceFor(
    result.candidate.identity,
    parsed: parsed,
    context: context,
    spellingMode: spellingMode,
  );
  if (evidence.delta == 0) return result;

  return RankedCandidateDebug(
    candidate: ChordCandidate(
      identity: result.candidate.identity,
      score: result.candidate.score + evidence.delta,
    ),
    scoreReasons: result.scoreReasons,
    vsPrevious: result.vsPrevious,
    template: result.template,
  );
}

bool _hasNamedInput(NoteParse parsed) => parsed.pcLabels.isNotEmpty;

_SpellingEvidence _spellingEvidenceFor(
  ChordIdentity id, {
  required NoteParse parsed,
  required AnalysisContext context,
  required ChordDebugSpellingMode spellingMode,
}) {
  if (spellingMode == ChordDebugSpellingMode.pc || !_hasNamedInput(parsed)) {
    return _SpellingEvidence.empty(spellingMode);
  }

  final rootName = spellChordRoot(id, tonality: context.tonality);
  final preserved = <String>[];
  final respelled = <String>[];

  for (final entry in parsed.pcLabels.entries) {
    final pc = entry.key;
    final typed = normalizeNoteNameToAscii(entry.value);
    final interval = intervalAboveRoot(pc, id.rootPc);
    final role = interval == 0
        ? ChordToneRole.root
        : id.toneRolesByInterval[interval];
    if (role == null) continue;

    final candidate = normalizeNoteNameToAscii(
      spellPitchClass(
        pc,
        tonality: context.tonality,
        chordRootName: rootName,
        role: role,
      ),
    );
    if (candidate == typed) {
      preserved.add(_displayNoteLabel(typed));
    } else {
      respelled.add(
        '${_displayNoteLabel(typed)} as ${_displayNoteLabel(candidate)}',
      );
    }
  }

  final matchDelta = spellingMode == ChordDebugSpellingMode.strict
      ? 0.10
      : 0.05;
  final respellDelta = spellingMode == ChordDebugSpellingMode.strict
      ? -3.00
      : -0.45;
  final delta = preserved.length * matchDelta + respelled.length * respellDelta;

  return _SpellingEvidence(
    mode: spellingMode,
    hasNamedInput: true,
    matches: preserved.length,
    respellings: respelled.length,
    delta: delta,
    preserved: preserved,
    respelled: respelled,
  );
}

String _formatSpellingEvidence(_SpellingEvidence evidence) {
  if (evidence.mode == ChordDebugSpellingMode.pc || !evidence.hasNamedInput) {
    return '';
  }

  final parts = <String>[];
  if (evidence.preserved.isNotEmpty) {
    parts.add('preserves ${evidence.preserved.join(', ')}');
  }
  if (evidence.respelled.isNotEmpty) {
    parts.add('respells ${evidence.respelled.join(', ')}');
  }
  parts.add(_fmtSigned(evidence.delta, width: 0, decimals: 2));
  return parts.join('; ');
}

class _SpellingEvidence {
  final ChordDebugSpellingMode mode;
  final bool hasNamedInput;
  final int matches;
  final int respellings;
  final double delta;
  final List<String> preserved;
  final List<String> respelled;

  const _SpellingEvidence({
    required this.mode,
    required this.hasNamedInput,
    required this.matches,
    required this.respellings,
    required this.delta,
    required this.preserved,
    required this.respelled,
  });

  factory _SpellingEvidence.empty(ChordDebugSpellingMode mode) =>
      _SpellingEvidence(
        mode: mode,
        hasNamedInput: false,
        matches: 0,
        respellings: 0,
        delta: 0,
        preserved: const [],
        respelled: const [],
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'mode': mode.wireName,
    'matches': matches,
    'respellings': respellings,
    'delta': double.parse(delta.toStringAsFixed(2)),
    'preserved': preserved,
    'respelled': respelled,
  };
}

/// Builds the JSON payload emitted by `--format=json`. Shared with the batch
/// entry point (tool/chord_oracle_batch.dart) so both produce identical output.
Map<String, Object?> chordDebugJsonPayload({
  required ChordInput input,
  required AnalysisContext context,
  required ChordNotationStyle notation,
  required List<({String label, int pc})> pcDisplays,
  required String bassLabel,
  required List<RankedCandidateDebug> results,
  ChordDebugSpellingMode spellingMode = ChordDebugSpellingMode.pc,
  NoteParse? parsed,
}) {
  final bestScore = results.isEmpty ? null : results.first.candidate.score;
  return <String, Object?>{
    'input': <String, Object?>{
      'noteCount': input.noteCount,
      'pcMask': input.pcMask,
      'pcMaskBinary': _formatPcMask(input.pcMask),
      'pitchClasses': [
        for (final display in pcDisplays)
          <String, Object?>{'pc': display.pc, 'label': display.label},
      ],
      'bassPc': input.bassPc,
      'bassLabel': bassLabel,
      'key': tonalityDisplayLabel(context.tonality),
      'spellingMode': spellingMode.wireName,
    },
    'candidates': [
      for (var i = 0; i < results.length; i++)
        _candidateJson(
          rank: i + 1,
          result: results[i],
          bestScore: bestScore,
          context: context,
          notation: notation,
          spellingMode: spellingMode,
          parsed: parsed,
        ),
    ],
  };
}

void _writeJsonOutput({
  required ChordInput input,
  required AnalysisContext context,
  required ChordNotationStyle notation,
  required List<({String label, int pc})> pcDisplays,
  required String bassLabel,
  required ChordDebugSpellingMode spellingMode,
  required NoteParse parsed,
  required List<RankedCandidateDebug> results,
}) {
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert(
      chordDebugJsonPayload(
        input: input,
        context: context,
        notation: notation,
        pcDisplays: pcDisplays,
        bassLabel: bassLabel,
        spellingMode: spellingMode,
        parsed: parsed,
        results: results,
      ),
    ),
  );
}

Map<String, Object?> _candidateJson({
  required int rank,
  required RankedCandidateDebug result,
  required double? bestScore,
  required AnalysisContext context,
  required ChordNotationStyle notation,
  required ChordDebugSpellingMode spellingMode,
  required NoteParse? parsed,
}) {
  final c = result.candidate;
  final id = c.identity;
  final rootName = spellChordRoot(id, tonality: context.tonality);
  final symbol = chordSymbolDisplayLabel(
    ChordSymbolBuilder.fromIdentity(
      identity: id,
      tonality: context.tonality,
      notation: notation,
    ),
  );
  final sortedExtensions = id.extensions.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final sortedRoles = id.toneRolesByInterval.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final deltaBest = bestScore == null ? null : c.score - bestScore;
  final spelling = parsed == null
      ? null
      : _spellingEvidenceFor(
          id,
          parsed: parsed,
          context: context,
          spellingMode: spellingMode,
        );

  return <String, Object?>{
    'rank': rank,
    'symbol': symbol,
    'harte': HarteChordFormatter.format(id, rootName: rootName),
    'score': c.score,
    'deltaBest': deltaBest,
    'nearTie':
        bestScore != null &&
        rank != 1 &&
        ChordCandidateRanking.isNearTie(bestScore, c.score),
    'rootPc': id.rootPc,
    'rootName': rootName,
    'bassPc': id.bassPc,
    'quality': id.quality.name,
    'extensions': [for (final extension in sortedExtensions) extension.name],
    'presentIntervalsMask': id.presentIntervalsMask,
    'toneRolesByInterval': {
      for (final entry in sortedRoles) entry.key.toString(): entry.value.name,
    },
    'template': result.template.quality.name,
    if (spelling != null &&
        spelling.mode != ChordDebugSpellingMode.pc &&
        spelling.hasNamedInput)
      'spellingEvidence': spelling.toJson(),
    'scoreReasons': [
      for (final reason in result.scoreReasons)
        <String, Object?>{
          'label': reason.label,
          'delta': reason.delta,
          if (reason.detail != null) 'detail': reason.detail,
        },
    ],
    if (result.vsPrevious?.decidedByRule != null)
      'vsPreviousRule': result.vsPrevious!.decidedByRule.toString(),
  };
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

_OutputFormat _parseOutputFormatFlag(List<String> args) {
  if (_hasLongFlag(args, 'json')) return _OutputFormat.json;

  final raw = _readStringFlag(args, 'format', 'f');
  if (raw == null || raw.trim().isEmpty) return _OutputFormat.text;

  return switch (raw.trim().toLowerCase()) {
    'text' => _OutputFormat.text,
    'json' => _OutputFormat.json,
    _ => _failUnknownFormat(raw),
  };
}

Never _failUnknownFormat(String raw) {
  stderr.writeln('Unknown --format value: "$raw"');
  stderr.writeln('Valid: text, json');
  exit(2);
}

Never _failUnknownNotation(String raw) {
  stderr.writeln('Unknown --notation value: "$raw"');
  stderr.writeln('Valid: textual, symbolic');
  exit(2);
}

ChordDebugSpellingMode _parseSpellingModeFlag(String? raw) {
  if (raw == null || raw.trim().isEmpty) return ChordDebugSpellingMode.pc;

  return switch (raw.trim().toLowerCase()) {
    'pc' || 'pitch-class' || 'pitch-classes' => ChordDebugSpellingMode.pc,
    'auto' => ChordDebugSpellingMode.auto,
    'strict' || 'exact' => ChordDebugSpellingMode.strict,
    _ => _failUnknownSpellingMode(raw),
  };
}

Never _failUnknownSpellingMode(String raw) {
  stderr.writeln('Unknown --spelling value: "$raw"');
  stderr.writeln('Valid: pc, auto, strict');
  exit(2);
}

/// How to build the [ObservedVoicing] passed to analysis.
enum _RegistersMode { auto, exact, synthesized, none }

_RegistersMode _parseRegistersFlag(String? raw) {
  if (raw == null || raw.trim().isEmpty) return _RegistersMode.auto;

  return switch (raw.trim().toLowerCase()) {
    'exact' || 'midi' => _RegistersMode.exact,
    'synthesized' || 'ordered' || 'order' => _RegistersMode.synthesized,
    'none' || 'off' || 'pc' => _RegistersMode.none,
    _ => _failUnknownRegistersMode(raw),
  };
}

Never _failUnknownRegistersMode(String raw) {
  stderr.writeln('Unknown --registers value: "$raw"');
  stderr.writeln('Valid: exact, synthesized, none');
  exit(2);
}

/// Builds the voicing for the given mode. [auto] mirrors the real interfaces:
/// exact octaves when MIDI numbers were given, otherwise order-only.
ObservedVoicing? _buildDebugVoicing({
  required _RegistersMode mode,
  required List<int> midi,
  required List<int> orderedPitchClasses,
}) {
  final hasMidi = midi.length >= 2;
  return switch (mode) {
    _RegistersMode.none => null,
    _RegistersMode.exact => hasMidi ? ObservedVoicing.fromMidi(midi) : null,
    _RegistersMode.synthesized => ObservedVoicing.fromOrder(
      orderedPitchClasses,
    ),
    _RegistersMode.auto =>
      hasMidi
          ? ObservedVoicing.fromMidi(midi)
          : ObservedVoicing.fromOrder(orderedPitchClasses),
  };
}

enum ChordDebugSpellingMode {
  pc('pc'),
  auto('auto'),
  strict('strict');

  const ChordDebugSpellingMode(this.wireName);

  final String wireName;
}

enum _OutputFormat { text, json }

bool _hasFlag(List<String> args, String name, String shortName) {
  return args.contains('--$name') || args.contains('-$shortName');
}

bool _hasLongFlag(List<String> args, String name) {
  return args.contains('--$name');
}

List<String> _unknownFlags(List<String> args) {
  const knownFlags = {
    '--help',
    '--top',
    '--bass',
    '--key',
    '--notation',
    '--spelling',
    '--registers',
    '--format',
    '--json',
    '--verbose',
    '--compact',
    '-h',
    '-t',
    '-b',
    '-k',
    '-n',
    '-f',
    '-v',
    '-c',
  };

  final unknown = <String>[];
  for (final arg in args) {
    if (!arg.startsWith('--') && !RegExp(r'^-[A-Za-z]').hasMatch(arg)) {
      continue;
    }

    final flag = arg.split('=').first;
    if (!knownFlags.contains(flag)) {
      unknown.add(flag);
    }
  }
  return unknown;
}

int? _readIntFlag(List<String> args, String name, String shortName) {
  final value = _readStringFlag(args, name, shortName);
  return value == null ? null : int.tryParse(value);
}

String? _readStringFlag(List<String> args, String name, String shortName) {
  final long = '--$name';
  final longPrefix = '$long=';
  final hasShort = shortName.isNotEmpty;
  final short = hasShort ? '-$shortName' : '';
  final shortPrefix = hasShort ? '$short=' : '';

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith(longPrefix)) {
      return arg.substring(longPrefix.length);
    }
    if (arg == long && i + 1 < args.length) {
      return args[i + 1];
    }
    if (hasShort && arg.startsWith(shortPrefix)) {
      return arg.substring(shortPrefix.length);
    }
    if (hasShort && arg == short && i + 1 < args.length) {
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
    '--spelling',
    '--registers',
    '--format',
    '-t',
    '-b',
    '-k',
    '-n',
    '-f',
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
    'sus-tone bass' => 'sus-bass',
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
