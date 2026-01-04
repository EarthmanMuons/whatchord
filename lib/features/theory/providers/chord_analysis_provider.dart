import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/midi/midi.dart';

import '../engine/engine.dart';
import '../models/chord_analysis.dart';
import '../models/chord_symbol.dart';
import '../models/scale_degree.dart';
import '../providers/tonality_provider.dart';

final chordAnalysisProvider = Provider<ChordAnalysis>((ref) {
  final best = ref.watch(bestChordCandidateProvider);

  if (best == null) {
    return const ChordAnalysis(
      symbol: ChordSymbol(root: '—', quality: '', bass: null),
      inversion: null,
    );
  }

  final symbol = _symbolFromIdentity(best.identity);

  // Phase 2: keep inversion null. Phase 3 can derive “1st inversion” for triads/7ths.
  return ChordAnalysis(symbol: symbol, inversion: null);
});

ChordSymbol _symbolFromIdentity(ChordIdentity identity) {
  final root = _pcToSharpName(identity.rootPc);
  final quality = _qualityTokenToShortLabel(
    identity.quality,
    identity.extensions,
  );
  final bass = identity.hasSlashBass ? _pcToSharpName(identity.bassPc) : null;

  return ChordSymbol(root: root, quality: quality, bass: bass);
}

String _pcToSharpName(int pc) {
  const names = <String>[
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];
  return names[pc % 12];
}

String _qualityTokenToShortLabel(
  ChordQualityToken q,
  Set<ChordExtension> extensions,
) {
  switch (q) {
    case ChordQualityToken.major:
      return 'maj';
    case ChordQualityToken.minor:
      return 'm';
    case ChordQualityToken.diminished:
      return 'dim';
    case ChordQualityToken.augmented:
      return 'aug';
    case ChordQualityToken.sus2:
      return 'sus2';
    case ChordQualityToken.sus4:
      return 'sus4';
    case ChordQualityToken.dominant7:
      return '7';
    case ChordQualityToken.major7:
      return 'maj7';
    case ChordQualityToken.minor7:
      return 'm7';
    case ChordQualityToken.halfDiminished7:
      return 'm7(b5)';
    case ChordQualityToken.diminished7:
      return 'dim7';
  }
}

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

  final tonality = ref.watch(selectedTonalityProvider);
  return ChordAnalyzer.analyze(input, tonality: tonality);
});

final bestChordCandidateProvider = Provider<ChordCandidate?>((ref) {
  final candidates = ref.watch(chordCandidatesProvider);
  return candidates.isNotEmpty ? candidates.first : null;
});

@immutable
class ChordCardViewModel {
  final String title;
  final String? subtitle;

  const ChordCardViewModel({required this.title, this.subtitle});
}

final chordCardViewModelProvider = Provider<ChordCardViewModel>((ref) {
  final best = ref.watch(bestChordCandidateProvider);

  if (best == null) {
    return const ChordCardViewModel(
      title: '—',
      subtitle: 'Play notes to identify a chord',
    );
  }

  final id = best.identity;

  // Temporary display until Phase 3 formatter:
  // - show pitch classes as integers
  // - quality token name
  // - slash bass if different
  //
  // Once we add note spelling + standard/jazz formatting, this becomes
  // a proper symbol like "Cmaj7/G".
  final root = 'pc${id.rootPc}';
  final qual = id.quality.name;
  final bass = id.hasSlashBass ? ' / pc${id.bassPc}' : '';

  final title = '$root $qual$bass';

  // Helpful subtitle while tuning: extensions + score
  final ext = (id.extensions.toList()..sort()).join(',');
  final subtitle = 'ext=[$ext] score=${best.score.toStringAsFixed(2)}';

  return ChordCardViewModel(title: title, subtitle: subtitle);
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

  final ext = id.extensions.toList()..sort();

  return 'Chord: rootPc=${id.rootPc} '
      'quality=${id.quality.name} '
      'bassPc=${id.bassPc} '
      'ext=$ext '
      'score=${best.score.toStringAsFixed(2)} '
      '| $inputDebug';
});
