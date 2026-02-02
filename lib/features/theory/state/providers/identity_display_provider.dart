import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/core.dart';
import 'package:whatchord/features/input/input.dart';

import '../../domain/theory_domain.dart';
import '../../presentation/models/identity_display.dart';
import '../../presentation/services/chord_long_form_formatter.dart';
import '../../presentation/services/chord_quality_token_labels.dart';
import '../../presentation/services/chord_symbol_builder.dart';
import '../../presentation/services/interval_formatter.dart';
import '../../presentation/services/inversion_formatter.dart';
import '../../presentation/services/note_long_form_formatter.dart';
import 'analysis_context_provider.dart';
import 'analysis_mode_provider.dart';
import 'chord_candidates_providers.dart';
import 'chord_member_spellings_providers.dart';
import 'theory_preferences_notifier.dart';

final identityDisplayProvider = Provider<IdentityDisplay?>((ref) {
  final mode = ref.watch(analysisModeProvider);
  if (mode == AnalysisMode.none) return null;

  final midis = ref.watch(soundingNoteNumbersSortedProvider);
  if (midis.isEmpty) return null;

  final tonality = ref.watch(analysisContextProvider.select((c) => c.tonality));

  final appVersion = ref.watch(appVersionProvider).asData?.value;

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
            keyName: tonality.displayName,
            noteName: name,
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

        return IntervalDisplay(
          referenceName: root,
          intervalLabel: interval.short,
          longLabel: interval.long,
          secondaryLabel: 'Interval · from $root',
          debugText: _debugForInterval(
            midis: midis,
            keyName: tonality.displayName,
            bassMidi: bassMidi,
            upperMidi: upperMidi,
            semitones: interval.semitones,
            intervalShort: interval.short,
            intervalLong: interval.long,
            fromRoot: root,
            appVersion: appVersion,
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

        final qualityLabel = id.quality.label(ChordQualityLabelForm.long);

        final extensions = [...id.extensions]
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        final extensionLabels = extensions.map((e) => e.shortLabel).toList();

        final members = ref.watch(chordMemberSpellingsProvider);

        final debugText = _debugForChord(
          midis: midis,
          keyName: tonality.displayName,
          chosenSymbol: symbol.toString(),
          longLabel: longLabel,
          rootPc: id.rootPc,
          bassPc: id.bassPc,
          hasSlash: id.hasSlashBass,
          quality: qualityLabel,
          extensions: extensionLabels,
          members: members,
          appVersion: appVersion,
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
      _debugSection('Note Identity', ['Label: $noteName', 'Name: $longLabel']),
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
  required String intervalShort,
  required String intervalLong,
  required String? appVersion,
}) {
  return _debugDoc(
    sections: [
      _debugSection('Interval Identity', [
        'Label: $intervalShort',
        'Name: $intervalLong',
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
  required int bassPc,
  required bool hasSlash,
  required String quality,
  required List<String> extensions,
  required List<String> members,
  required String? appVersion,
}) {
  final realizedBassPc = midis.first % 12;

  return _debugDoc(
    sections: [
      _debugSection('Chord Identity', [
        'Label: $chosenSymbol',
        'Name: $longLabel',
        'Members: ${members.isEmpty ? '(none)' : members.join(', ')}',
      ]),
      _debugContext(keyName: keyName),
      _debugInput(midis: midis),
      _debugSection('Details', [
        'Root pitch class: $rootPc',
        'Quality: $quality',
        'Extensions: ${_fmtList(extensions)}',
        'Bass pitch class: $realizedBassPc',
      ]),
      _debugApp(appVersion: appVersion),
    ],
  );
}

String _fmtList<T>(Iterable<T> items, {String empty = '(none)'}) {
  final list = items.toList();
  return list.isEmpty ? empty : '[${list.join(', ')}]';
}

String _debugSection(String title, List<String> lines) {
  return [title, ...lines.map((l) => '• $l')].join('\n');
}

String _debugContext({required String keyName}) {
  return _debugSection('Context', ['Key: $keyName']);
}

String _debugInput({required List<int> midis}) {
  final pcs = (midis.map((m) => m % 12).toSet().toList()..sort());

  return _debugSection('Input', [
    'MIDI notes: ${_fmtList(midis)}',
    'Note count: ${midis.length}',
    'Pitch classes: ${_fmtList(pcs)}',
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
