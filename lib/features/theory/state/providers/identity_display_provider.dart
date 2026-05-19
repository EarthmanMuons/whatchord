import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/core.dart';
import 'package:whatchord/features/input/input.dart';

import '../../domain/theory_domain.dart';
import '../../presentation/models/identity_display.dart';
import '../../presentation/services/chord_quality_token_labels.dart';
import '../../presentation/services/chord_symbol_builder.dart';
import '../../presentation/services/interval_formatter.dart';
import '../../presentation/services/inversion_formatter.dart';
import '../../presentation/services/note_display_formatter.dart';
import '../../presentation/services/note_long_form_formatter.dart';
import 'analysis_context_provider.dart';
import 'analysis_mode_provider.dart';
import 'chord_candidates_providers.dart';
import 'chord_presentation_provider.dart';
import 'theory_preferences_notifier.dart';

final identityDisplayProvider = Provider<IdentityDisplay?>((ref) {
  final mode = ref.watch(analysisModeProvider);
  if (mode == AnalysisMode.none) return null;

  final midis = ref.watch(soundingNoteNumbersSortedProvider);
  if (midis.isEmpty) return null;

  final tonality = ref.watch(analysisContextProvider.select((c) => c.tonality));
  final noteNameSystem = ref.watch(noteNameSystemProvider);
  final keyName = tonalityDisplayLabel(
    tonality,
    noteNameSystem: noteNameSystem,
  );

  final appVersion = ref.watch(appVersionProvider).asData?.value;

  switch (mode) {
    case AnalysisMode.single:
      {
        final pc = midis.first % 12;
        final name = pcToName(pc, tonality: tonality);
        final displayName = noteDisplayLabel(
          name,
          noteNameSystem: noteNameSystem,
        );
        final longLabel = NoteLongFormFormatter.format(
          name,
          noteNameSystem: noteNameSystem,
        );

        return NoteDisplay(
          noteName: displayName,
          longLabel: longLabel,
          secondaryLabel: 'Note',
          debugText: _debugForNote(
            midis: midis,
            keyName: keyName,
            noteName: displayName,
            longLabel: longLabel,
            appVersion: appVersion,
          ),
        );
      }

    case AnalysisMode.dyad:
      {
        if (midis.length < 2) return null;

        final bassMidi = midis.first;
        final upperMidi = midis.last;

        final interval = IntervalFormatter.forMidiNotes(
          bassMidi: bassMidi,
          upperMidi: upperMidi,
          direction: IntervalLabelDirection.fromBass,
        );

        final bassPc = bassMidi % 12;
        final root = pcToName(bassPc, tonality: tonality);
        final displayRoot = noteDisplayLabel(
          root,
          noteNameSystem: noteNameSystem,
        );

        return IntervalDisplay(
          referenceName: displayRoot,
          intervalLabel: interval.long,
          longLabel: interval.long,
          secondaryLabel: 'Interval · from $displayRoot',
          debugText: _debugForInterval(
            midis: midis,
            keyName: keyName,
            bassMidi: bassMidi,
            upperMidi: upperMidi,
            semitones: interval.semitones,
            intervalLong: interval.long,
            fromRoot: displayRoot,
            appVersion: appVersion,
          ),
        );
      }

    case AnalysisMode.chord:
      {
        final presentation = ref.watch(chordPresentationProvider);
        if (presentation == null) return null;
        final id = presentation.identity;
        final notation = ref.watch(chordNotationStyleProvider);
        final alternatives = ref
            .watch(nearTieChordCandidatesProvider)
            .map(
              (c) => chordSymbolDisplayLabel(
                ChordSymbolBuilder.fromIdentity(
                  identity: c.identity,
                  tonality: tonality,
                  notation: notation,
                ),
                noteNameSystem: noteNameSystem,
                spacing: ChordSymbolDisplaySpacing.plain,
              ),
            )
            .toList(growable: false);

        final inversion = InversionFormatter.format(id);
        final secondaryLabel = (inversion == null || inversion.trim().isEmpty)
            ? 'Chord'
            : 'Chord · $inversion';

        final qualityLabel = id.quality.label(ChordQualityLabelForm.long);

        final extensions = [...id.extensions]
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        final extensionLabels = extensions
            .map((e) => theoryTokenDisplayLabel(e.shortLabel))
            .toList();
        final debugText = _debugForChord(
          midis: midis,
          keyName: keyName,
          chosenSymbol: chordSymbolDisplayLabel(
            presentation.symbol,
            noteNameSystem: noteNameSystem,
            spacing: ChordSymbolDisplaySpacing.plain,
          ),
          longLabel: presentation.longLabel,
          rootPc: id.rootPc,
          quality: qualityLabel,
          extensions: extensionLabels,
          alternatives: alternatives,
          scaleDegreeAnalysis: presentation.scaleDegreeAnalysis,
          members: presentation.members
              .map((m) => noteDisplayLabel(m, noteNameSystem: noteNameSystem))
              .toList(),
          degrees: presentation.memberDegrees
              .map(theoryTokenDisplayLabel)
              .toList(),
          appVersion: appVersion,
        );

        return ChordDisplay(
          symbol: presentation.symbol,
          longLabel: presentation.longLabel,
          semanticLongLabel: presentation.semanticLongLabel,
          secondaryLabel: secondaryLabel,
          debugText: debugText,
        );
      }

    case AnalysisMode.none:
      return null;
  }
});

// ---- Analysis details formatting -----------------------------------------

String _debugForNote({
  required List<int> midis,
  required String keyName,
  required String noteName,
  required String longLabel,
  required String? appVersion,
}) {
  return _debugDoc(
    sections: [
      _debugSection('Note Identity', [
        'Displayed: $noteName',
        'Full name: $longLabel',
      ]),
      _debugContext(keyName: keyName),
      _debugInput(midis: midis),
      _debugApp(appVersion: appVersion),
    ],
  );
}

String _debugForInterval({
  required List<int> midis,
  required String keyName,
  required int bassMidi,
  required int upperMidi,
  required int semitones,
  required String fromRoot,
  required String intervalLong,
  required String? appVersion,
}) {
  return _debugDoc(
    sections: [
      _debugSection('Interval Identity', [
        'Full name: $intervalLong',
        'Reference: from $fromRoot',
      ]),
      _debugContext(keyName: keyName),
      _debugInput(midis: midis),
      _debugSection('Details', [
        'Bass MIDI: $bassMidi',
        'Upper MIDI: $upperMidi',
        'Semitones: $semitones',
      ]),
      _debugApp(appVersion: appVersion),
    ],
  );
}

String _debugForChord({
  required List<int> midis,
  required String keyName,
  required String chosenSymbol,
  required String longLabel,
  required int rootPc,
  required String quality,
  required List<String> extensions,
  required List<String> alternatives,
  required ScaleDegreeAnalysis? scaleDegreeAnalysis,
  required List<String> members,
  required List<String> degrees,
  required String? appVersion,
}) {
  final realizedBassPc = midis.first % 12;

  return _debugDoc(
    sections: [
      _debugSection('Chord Identity', [
        'Displayed: $chosenSymbol',
        'Full name: $longLabel',
        'Degrees: ${degrees.isEmpty ? '(none)' : degrees.join(', ')}',
        'Members: ${members.isEmpty ? '(none)' : members.join(', ')}',
      ]),
      _debugAlternatives(alternatives),
      _debugContext(keyName: keyName),
      _debugInput(midis: midis),
      _debugSection('Details', [
        'Root pitch class: $rootPc',
        'Quality: $quality',
        'Extensions: ${_fmtList(extensions)}',
        'Bass pitch class: $realizedBassPc',
        'Scale degree: ${_scaleDegreeDebugLabel(scaleDegreeAnalysis)}',
      ]),
      _debugApp(appVersion: appVersion),
    ],
  );
}

String _scaleDegreeDebugLabel(ScaleDegreeAnalysis? analysis) {
  if (analysis == null) return '(none)';
  return '${analysis.romanNumeral} (${analysis.functionName}, '
      '${analysis.source.displayLabel})';
}

String _fmtList<T>(Iterable<T> items, {String empty = '(none)'}) {
  final list = items.toList();
  return list.isEmpty ? empty : '[${list.join(', ')}]';
}

String _debugSection(String title, List<String> lines) {
  return [title, ...lines.map((l) => '• $l')].join('\n');
}

String _debugAlternatives(List<String> alternatives) {
  final lines = alternatives.isEmpty ? const ['(none)'] : alternatives;
  return _debugSection('Alternatives', lines);
}

String _debugContext({required String keyName}) {
  return _debugSection('Context', ['Key: $keyName']);
}

String _debugInput({required List<int> midis}) {
  final pcs = (midis.map((m) => m % 12).toSet().toList()..sort());

  return _debugSection('Input', [
    'MIDI notes: ${_fmtList(midis)}',
    'Pitch classes (C=0): ${_fmtList(pcs)}',
    'Note count: ${midis.length}',
  ]);
}

String _debugApp({required String? appVersion}) {
  final String title;
  if (Platform.isAndroid) {
    title = 'Android App';
  } else if (Platform.isIOS) {
    title = 'iOS App';
  } else {
    title = 'App';
  }

  final versionLine = appVersion != null
      ? 'WhatChord v$appVersion'
      : 'WhatChord v(loading)';

  return _debugSection(title, [versionLine]);
}

String _debugDoc({required List<String> sections}) {
  return [
    ...sections.expand((s) => [s, '']).toList()..removeLast(),
  ].join('\n');
}
