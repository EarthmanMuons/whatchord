import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/midi/midi.dart';

import '../engine/engine.dart';
import '../models/chord_analysis.dart';
import '../models/chord_symbol.dart';
import '../models/scale_degree.dart';
import '../services/chord_symbol_formatter.dart';
import '../services/inversion_labeler.dart';
import '../services/note_spelling.dart';
import 'analysis_context_provider.dart';
import 'chord_symbol_style_notifier.dart';

enum AnalysisMode { none, single, dyad, chord }

final analysisModeProvider = Provider<AnalysisMode>((ref) {
  final input = ref.watch(chordInputProvider);
  if (input == null || input.noteCount == 0) return AnalysisMode.none;
  if (input.noteCount == 1) return AnalysisMode.single;
  if (input.noteCount == 2) return AnalysisMode.dyad;
  return AnalysisMode.chord;
});

final chordAnalysisProvider = Provider<ChordAnalysis>((ref) {
  ChordAnalysis empty() => ChordAnalysis(
    symbol: ChordSymbol(root: '• • •', quality: '', bass: null),
    secondaryLabel: null,
  );

  final mode = ref.watch(analysisModeProvider);
  if (mode == AnalysisMode.none) return empty();

  final context = ref.watch(analysisContextProvider);

  // Needed for single+dyad. You already have this provider in MIDI.
  final midis = ref.watch(soundingMidiNotesProvider).toList()..sort();
  if (midis.isEmpty) return empty();

  switch (mode) {
    case AnalysisMode.single:
      {
        final pc = midis.first % 12;
        final name = pcToName(pc, tonality: context.tonality);

        return ChordAnalysis(
          symbol: ChordSymbol(root: name, quality: '', bass: null),
          secondaryLabel: 'Note',
        );
      }

    case AnalysisMode.dyad:
      {
        if (midis.length < 2) return empty();

        final bassMidi = midis.first;
        final otherMidi = midis.last;

        final interval = IntervalLabeler.forMidiNotes(
          bassMidi: bassMidi,
          otherMidi: otherMidi,
          direction: IntervalLabelDirection.fromBass,
        );

        final bassPc = bassMidi % 12;
        final root = pcToName(bassPc, tonality: context.tonality);

        return ChordAnalysis(
          symbol: ChordSymbol(
            root: root,
            quality: ' ${interval.short}', // e.g. " P8", " m9"
            bass: null,
          ),
          secondaryLabel: 'Interval',
        );
      }

    case AnalysisMode.chord:
      {
        final best = ref.watch(bestChordCandidateProvider);
        if (best == null) return empty();

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
          secondaryLabel: inversion,
        );
      }

    case AnalysisMode.none:
      return empty();
  }
});

final detectedScaleDegreeProvider = Provider<ScaleDegree?>((ref) {
  // Only meaningful for real chord analyses.
  final mode = ref.watch(analysisModeProvider);
  if (mode != AnalysisMode.chord) return null;

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

  final sorted = sounding.toList()..sort();
  final bassMidi = sorted.first;
  final bassPc = bassMidi % 12;

  var mask = 0;
  for (final midi in sounding) {
    mask |= (1 << (midi % 12));
  }

  return ChordInput(pcMask: mask, bassPc: bassPc, noteCount: sounding.length);
});

final chordCandidatesProvider = Provider<List<ChordCandidate>>((ref) {
  final input = ref.watch(chordInputProvider);
  if (input == null) return const <ChordCandidate>[];

  // Guard: do not analyze if we're not in chord mode.
  final mode = ref.watch(analysisModeProvider);
  if (mode != AnalysisMode.chord) return const <ChordCandidate>[];

  final context = ref.watch(analysisContextProvider);
  return ChordAnalyzer.analyze(input, context: context);
});

final bestChordCandidateProvider = Provider<ChordCandidate?>((ref) {
  final candidates = ref.watch(chordCandidatesProvider);
  return candidates.isNotEmpty ? candidates.first : null;
});
