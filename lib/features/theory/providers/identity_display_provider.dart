import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/input/input.dart';

import '../domain/theory_domain.dart';
import '../models/identity_display.dart';
import '../services/chord_long_form_formatter.dart';
import '../services/chord_quality_token_labels.dart';
import '../services/chord_symbol_builder.dart';
import '../services/interval_formatter.dart';
import '../services/inversion_formatter.dart';
import '../services/note_long_form_formatter.dart';
import '../services/note_spelling.dart';
import 'analysis_context_provider.dart';
import 'analysis_mode_provider.dart';
import 'chord_candidates_providers.dart';
import 'chord_member_spellings_providers.dart';
import 'theory_preferences_notifier.dart';

final identityDisplayProvider = Provider<IdentityDisplay?>((ref) {
  final mode = ref.watch(analysisModeProvider);
  if (mode == AnalysisMode.none) return null;

  final midis = ref.watch(soundingNotesSortedProvider);
  if (midis.isEmpty) return null;

  final tonality = ref.watch(analysisContextProvider.select((c) => c.tonality));

  switch (mode) {
    case AnalysisMode.single:
      {
        final pc = midis.first % 12;
        final name = pcToName(pc, tonality: tonality);
        final longLabel = NoteLongFormFormatter.format(name);

        return NoteDisplay(
          noteName: name,
          longLabel: longLabel,
          secondaryLabel: 'Note',
          debugText: _debugForNote(
            midis: midis,
            tonalityName: tonality.toString(),
            noteName: name,
            longLabel: longLabel,
          ),
        );
      }

    case AnalysisMode.dyad:
      {
        if (midis.length < 2) return null;

        final bassMidi = midis.first;
        final otherMidi = midis.last;

        final interval = IntervalFormatter.forMidiNotes(
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
            fromRoot: root,
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

        final inversion = InversionFormatter.format(id);
        final secondaryLabel = (inversion == null || inversion.trim().isEmpty)
            ? 'Chord'
            : 'Chord · $inversion';

        final longLabel = ChordLongFormFormatter.format(
          identity: id,
          tonality: tonality,
        );

        final qualityLabel = id.quality.label(ChordQualityLabelForm.short);

        final members = ref.watch(chordMemberSpellingsProvider);

        final debugText = _debugForChord(
          midis: midis,
          tonalityName: tonality.toString(),
          chosenSymbol: symbol.toString(),
          longLabel: longLabel,
          rootPc: id.rootPc,
          bassPc: id.bassPc,
          hasSlash: id.hasSlashBass,
          quality: qualityLabel,
          extensions: id.extensions.map((e) => e.shortLabel).toList()..sort(),
          members: members,
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

String _debugForNote({
  required List<int> midis,
  required String tonalityName,
  required String noteName,
  required String longLabel,
}) {
  final base = _debugForInput(midis: midis, tonalityName: tonalityName);
  return [
    'Note Identity',
    '- Displayed: $noteName',
    '- Long:      $longLabel',
    '',
    base,
  ].join('\n');
}

String _debugForInterval({
  required List<int> midis,
  required int bassMidi,
  required int otherMidi,
  required int semitones,
  required String fromRoot,
  required String intervalShort,
  required String intervalLong,
  required String tonalityName,
}) {
  final base = _debugForInput(midis: midis, tonalityName: tonalityName);
  return [
    'Interval Identity',
    '- Displayed: $intervalShort',
    '- Long:      $intervalLong',
    '- From:      $fromRoot',
    '',
    base,
    '',
    'Interval',
    '- Bass MIDI: $bassMidi',
    '- Other MIDI: $otherMidi',
    '- Semitones: $semitones',
  ].join('\n');
}

String _debugForChord({
  required List<int> midis,
  required String tonalityName,
  required String chosenSymbol,
  required String longLabel,
  required int rootPc,
  required int bassPc,
  required bool hasSlash,
  required String quality,
  required List<String> extensions,
  required List<String> members,
}) {
  final base = _debugForInput(midis: midis, tonalityName: tonalityName);
  return [
    'Chord Identity',
    '- Displayed: $chosenSymbol',
    '- Long:      $longLabel',
    '- Members:   ${members.isEmpty ? '(none)' : members.join(', ')}',
    '',
    base,
    '',
    'Chord',
    '- Root PC: $rootPc',
    '- Quality: $quality',
    '- Extensions: ${extensions.isEmpty ? '(none)' : extensions.join(', ')}',
    '- Slash Bass: ${hasSlash ? '$bassPc' : '(none)'}',
  ].join('\n');
}
