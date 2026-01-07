import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/midi/midi.dart';
import 'package:what_chord/features/theory/providers/tonality_provider.dart';

import '../engine/engine.dart';
import '../models/chord_analysis.dart';
import '../models/chord_symbol.dart';
import '../models/scale_degree.dart';
import '../services/chord_symbol_formatter.dart';
import '../services/inversion_labeler.dart';
import '../services/note_spelling.dart';
import 'analysis_context_provider.dart';
import 'chord_symbol_style_notifier.dart';

final chordAnalysisProvider = Provider<ChordAnalysis>((ref) {
  final pcs = ref.watch(soundingPitchClassesProvider);

  if (pcs.isEmpty) {
    return ChordAnalysis(
      symbol: ChordSymbol(root: '— — —', quality: '', bass: null),
      inversion: null,
    );
  }

  final context = ref.watch(analysisContextProvider);

  // Determine bassPc from your existing input provider (or re-derive it).
  final input = ref.watch(chordInputProvider);
  if (input == null) {
    return ChordAnalysis(
      symbol: ChordSymbol(root: '— — —', quality: '', bass: null),
      inversion: null,
    );
  }

  // Dyad: show interval label instead of guessing a chord.
  if (pcs.length == 2) {
    final bassPc = input.bassPc;
    final otherPc = pcs.first == bassPc ? pcs.last : pcs.first;

    final interval = IntervalLabeler.forPitchClasses(
      bassPc: bassPc,
      otherPc: otherPc,
    );

    final tonality = ref.watch(selectedTonalityProvider);

    final root = pcToName(bassPc, tonality: tonality);
    final other = pcToName(otherPc, tonality: tonality);

    return ChordAnalysis(
      symbol: ChordSymbol(
        root: root,
        quality: ' ${interval.short}', // e.g. " P5" or " m3"
        bass: other, // show the other pitch class as the "slash" target
      ),
      inversion: null,
    );
  }

  // 3+ pitch classes: normal chord identification.
  final best = ref.watch(bestChordCandidateProvider);
  if (best == null) {
    return ChordAnalysis(
      symbol: ChordSymbol(root: '— — —', quality: '', bass: null),
      inversion: null,
    );
  }

  final style = ref.watch(chordSymbolStyleProvider);
  final id = best.identity;

  final root = pcToName(id.rootPc, tonality: context.tonality);
  final bass = id.hasSlashBass
      ? pcToName(id.bassPc, tonality: context.tonality)
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
  final best = ref.watch(bestChordCandidateProvider);
  if (best == null) return null;

  final context = ref.watch(analysisContextProvider);
  return context.tonality.scaleDegreeForChord(best.identity);
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

final soundingPitchClassesProvider = Provider<List<int>>((ref) {
  final state = ref.watch(midiNoteStateProvider);
  final sounding = state.soundingNotes;
  final pcs = sounding.map((m) => m % 12).toSet().toList()..sort();
  return pcs;
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
