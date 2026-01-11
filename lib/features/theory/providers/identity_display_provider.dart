import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/midi/midi.dart';

import '../engine/engine.dart';
import '../models/identity_display.dart';
import '../services/chord_long_form_formatter.dart';
import '../services/chord_symbol_builder.dart';
import '../services/inversion_labeler.dart';
import '../services/note_spelling.dart';
import 'analysis_context_provider.dart';
import 'analysis_mode_provider.dart';
import 'chord_candidates_providers.dart';
import 'chord_notation_style_notifier.dart';

final identityDisplayProvider = Provider<IdentityDisplay?>((ref) {
  final mode = ref.watch(analysisModeProvider);
  if (mode == AnalysisMode.none) return null;

  final midis = ref.watch(soundingMidiNotesSortedProvider);
  if (midis.isEmpty) return null;

  final tonality = ref.watch(analysisContextProvider.select((c) => c.tonality));

  switch (mode) {
    case AnalysisMode.single:
      {
        final pc = midis.first % 12;
        final name = pcToName(pc, tonality: tonality);

        return NoteDisplay(
          noteName: name,
          longLabel: name,
          secondaryLabel: 'Note',
          debugText: _debugForInput(
            midis: midis,
            tonalityName: tonality.toString(),
          ),
        );
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
        final root = pcToName(bassPc, tonality: tonality);

        return IntervalDisplay(
          referenceName: root,
          intervalLabel: interval.short,
          longLabel: interval.long,
          secondaryLabel: 'Interval · from $root',
          debugText: _debugForInterval(
            midis: midis,
            bassMidi: bassMidi,
            otherMidi: otherMidi,
            semitones: interval.semitones,
            intervalShort: interval.short,
            intervalLong: interval.long,
            tonalityName: tonality.displayName,
          ),
        );
      }

    case AnalysisMode.chord:
      {
        final id = ref.watch(
          bestChordCandidateProvider.select((c) => c?.identity),
        );
        if (id == null) return null;

        final notation = ref.watch(chordNotationStyleProvider);

        final symbol = ChordSymbolBuilder.fromIdentity(
          identity: id,
          tonality: tonality,
          notation: notation,
        );

        final inversion = InversionLabeler.labelFor(id);
        final secondaryLabel = (inversion == null || inversion.trim().isEmpty)
            ? 'Chord'
            : 'Chord · $inversion';

        final longLabel = ChordLongFormFormatter.format(
          identity: id,
          tonality: tonality,
        );

        final debugText = _debugForChord(
          midis: midis,
          tonalityName: tonality.toString(),
          chosenSymbol: symbol.toString(),
          rootPc: id.rootPc,
          bassPc: id.bassPc,
          hasSlash: id.hasSlashBass,
          quality: id.quality.toString(),
          extensions: id.extensions.map((e) => e.shortLabel).toList()..sort(),
        );

        return ChordDisplay(
          symbol: symbol,
          longLabel: longLabel,
          secondaryLabel: secondaryLabel,
          debugText: debugText,
        );
      }

    case AnalysisMode.none:
      return null;
  }
});

String _debugForInput({
  required List<int> midis,
  required String tonalityName,
}) {
  final pcs = (midis.map((m) => m % 12).toSet().toList()..sort());
  final sorted = [...midis]..sort();
  return [
    'Context',
    '- Tonality: $tonalityName',
    '',
    'Input',
    '- MIDI: $sorted',
    '- PCs:  $pcs',
  ].join('\n');
}

String _debugForInterval({
  required List<int> midis,
  required int bassMidi,
  required int otherMidi,
  required int semitones,
  required String intervalShort,
  required String intervalLong,
  required String tonalityName,
}) {
  final base = _debugForInput(midis: midis, tonalityName: tonalityName);
  return [
    base,
    '',
    'Interval',
    '- Bass MIDI: $bassMidi',
    '- Other MIDI: $otherMidi',
    '- Semitones: $semitones',
    '- Label: $intervalShort ($intervalLong)',
  ].join('\n');
}

String _debugForChord({
  required List<int> midis,
  required String tonalityName,
  required String chosenSymbol,
  required int rootPc,
  required int bassPc,
  required bool hasSlash,
  required String quality,
  required List<String> extensions,
}) {
  final base = _debugForInput(midis: midis, tonalityName: tonalityName);
  return [
    base,
    '',
    'Chord',
    '- Selected: $chosenSymbol',
    '- Root PC: $rootPc',
    '- Quality: $quality',
    '- Extensions: ${extensions.isEmpty ? '(none)' : extensions.join(', ')}',
    '- Slash bass: ${hasSlash ? 'yes (PC $bassPc)' : 'no'}',
  ].join('\n');
}
