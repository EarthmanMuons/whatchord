import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/midi/midi.dart';

import '../engine/engine.dart';
import '../models/identity_display.dart';
import '../services/chord_symbol_formatter.dart';
import '../services/inversion_labeler.dart';
import '../services/note_display_formatter.dart';
import '../services/note_spelling.dart';
import 'analysis_context_provider.dart';
import 'analysis_mode_provider.dart';
import 'chord_analysis_providers.dart';
import 'chord_symbol_style_notifier.dart';

final identityDisplayProvider = Provider<IdentityDisplay?>((ref) {
  final mode = ref.watch(analysisModeProvider);
  if (mode == AnalysisMode.none) return null;

  final midis = ref.watch(soundingMidiNotesProvider).toList()..sort();
  if (midis.isEmpty) return null;

  final context = ref.watch(analysisContextProvider);

  switch (mode) {
    case AnalysisMode.single:
      {
        final pc = midis.first % 12;
        final name = pcToName(pc, tonality: context.tonality);

        return NoteDisplay(noteName: name, secondaryLabel: 'Note');
      }

    case AnalysisMode.dyad:
      {
        if (midis.length < 2) return null;

        final bassMidi = midis.first;
        final otherMidi = midis.last;

        final interval = IntervalLabeler.forMidiNotes(
          bassMidi: bassMidi,
          otherMidi: otherMidi,
          direction: IntervalLabelDirection.fromBass,
        );

        final bassPc = bassMidi % 12;
        final root = pcToName(bassPc, tonality: context.tonality);

        return IntervalDisplay(
          referenceName: root,
          intervalLabel: interval.short,
          secondaryLabel: 'Interval · from ${toGlyphAccidentals(root)}',
        );
      }

    case AnalysisMode.chord:
      {
        final best = ref.watch(bestChordCandidateProvider);
        if (best == null) return null;

        final style = ref.watch(chordSymbolStyleProvider);
        final id = best.identity;

        final symbol = ChordSymbolFormatter.fromIdentity(
          identity: id,
          tonality: context.tonality,
          style: style,
        );

        final inversion = InversionLabeler.labelFor(id);
        final secondaryLabel = (inversion == null || inversion.trim().isEmpty)
            ? 'Chord'
            : 'Chord · $inversion';

        return ChordDisplay(symbol: symbol, secondaryLabel: secondaryLabel);
      }

    case AnalysisMode.none:
      return null;
  }
});
