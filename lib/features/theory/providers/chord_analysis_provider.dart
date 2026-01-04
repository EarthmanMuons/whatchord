import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/midi/midi.dart';
import 'package:what_chord/features/theory/providers/analysis_context_provider.dart';
import 'package:what_chord/features/theory/providers/chord_symbol_style_notifier.dart';

import '../engine/engine.dart';
import '../models/chord_analysis.dart';
import '../models/chord_symbol.dart';
import '../models/scale_degree.dart';
import '../providers/tonality_provider.dart';
import '../services/chord_symbol_formatter.dart';
import '../services/inversion_labeler.dart';
import '../services/note_spelling.dart';

final chordAnalysisProvider = Provider<ChordAnalysis>((ref) {
  final best = ref.watch(bestChordCandidateProvider);
  if (best == null) {
    return const ChordAnalysis(
      symbol: ChordSymbol(root: '— — —', quality: '', bass: null),
      inversion: null,
    );
  }

  final context = ref.watch(analysisContextProvider);
  final style = ref.watch(chordSymbolStyleProvider);

  final id = best.identity;

  final root = pcToName(id.rootPc, policy: context.spellingPolicy);
  final bass = id.hasSlashBass
      ? pcToName(id.bassPc, policy: context.spellingPolicy)
      : null;

  final quality = ChordSymbolFormatter.formatQuality(
    quality: id.quality,
    extensions: id.extensions,
    style: style,
  );

  final inversion = InversionLabeler.labelFor(id);

  return ChordAnalysis(
    symbol: ChordSymbol(root: root, quality: quality, bass: bass),
    inversion: inversion,
  );
});

final detectedScaleDegreeProvider = Provider<ScaleDegree?>((ref) {
  final tonality = ref.watch(selectedTonalityProvider);
  final analysis = ref.watch(chordAnalysisProvider);

  // Temporary: if chord root equals tonic label, call it scale degree I.
  // Phase 3: use pitch classes and the tonality scale map.
  if (analysis.symbol.root == tonality.label) {
    return ScaleDegree.one;
  }
  return null;
});

/// Converts currently sounding MIDI notes into a minimal chord-analysis input.
final chordInputProvider = Provider<ChordInput?>((ref) {
  final state = ref.watch(midiNoteStateProvider);
  final sounding = state.soundingNotes;
  if (sounding.isEmpty) return null;

  // Determine bass from the lowest MIDI note number.
  final sorted = sounding.toList()..sort();
  final bassMidi = sorted.first;
  final bassPc = bassMidi % 12;

  // Compute 12-bit pitch-class mask.
  var mask = 0;
  for (final midi in sounding) {
    mask |= (1 << (midi % 12));
  }

  return ChordInput(pcMask: mask, bassPc: bassPc, noteCount: sounding.length);
});

/// Ranked candidates (best-first once Step 2 is implemented).
final chordCandidatesProvider = Provider<List<ChordCandidate>>((ref) {
  final input = ref.watch(chordInputProvider);
  if (input == null) return const <ChordCandidate>[];

  final context = ref.watch(analysisContextProvider);
  return ChordAnalyzer.analyze(input, context: context);
});

final bestChordCandidateProvider = Provider<ChordCandidate?>((ref) {
  final candidates = ref.watch(chordCandidatesProvider);
  return candidates.isNotEmpty ? candidates.first : null;
});

/// Quick debug string you can surface in dev UI while tuning.
final chordDebugStringProvider = Provider<String>((ref) {
  final input = ref.watch(chordInputProvider);
  if (input == null) return 'No notes';

  final maskHex = input.pcMask.toRadixString(16);
  return 'pcMask=0x$maskHex bassPc=${input.bassPc} notes=${input.noteCount}';
});

final chordAnalysisDebugProvider = Provider<String>((ref) {
  final inputDebug = ref.watch(chordDebugStringProvider);

  final candidates = ref.watch(chordCandidatesProvider);
  if (candidates.isEmpty) {
    return 'Chord: no match | $inputDebug';
  }

  final best = candidates.first;
  final id = best.identity;

  final context = ref.watch(analysisContextProvider);
  final style = ref.watch(chordSymbolStyleProvider);

  final root = pcToName(id.rootPc, policy: context.spellingPolicy);
  final bass = id.hasSlashBass
      ? pcToName(id.bassPc, policy: context.spellingPolicy)
      : null;

  final quality = ChordSymbolFormatter.formatQuality(
    quality: id.quality,
    extensions: id.extensions,
    style: style,
  );

  debugPrint('- - -');
  debugPrint('BEST identity: quality=${id.quality} ext=${id.extensions}');
  debugPrint(
    'BEST symbol: ${ChordSymbol(root: root, quality: quality, bass: bass)}',
  );

  final ext = id.extensions.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  final extLabels = ext.map((e) => e.label).toList(growable: false);

  return 'Chord: rootPc=${id.rootPc} '
      'quality=${id.quality.name} '
      'bassPc=${id.bassPc} '
      'ext=$extLabels '
      'score=${best.score.toStringAsFixed(2)} '
      '| $inputDebug';
});
