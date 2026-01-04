import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/home/widgets/components/chord_card.dart';

import '../engine/models/chord_extension.dart';
import '../engine/models/chord_identity.dart';
import '../models/chord_symbol.dart';
import '../providers/chord_analysis_provider.dart';

/// Renders the chord card using live analysis, and shows debug output beneath
/// the card in debug builds.
///
/// Keeps ChordCard itself stateless and UI-only.
class ChordCardPanel extends ConsumerWidget {
  const ChordCardPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final best = ref.watch(bestChordCandidateProvider);
    final debug = ref.watch(chordAnalysisDebugProvider);

    // Temporary mapping until Phase 3 formatter/spelling.
    // We intentionally keep it crude (pc0, pc1...) but preserves your
    // root/quality/bass split and bold-root rendering.
    final symbol = best == null
        ? const ChordSymbol(root: '— — —', quality: '', bass: null)
        : _symbolFromIdentity(best.identity);

    // Inversion label: for now we leave null (Phase 3 will add derived inversion
    // labels for triads/7ths if you want them).
    final inversion = best == null ? null : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChordCard(symbol: symbol, inversion: inversion),

        if (kDebugMode) ...[
          const SizedBox(height: 10),
          _ChordDebugLine(text: debug),
        ],
      ],
    );
  }
}

class _ChordDebugLine extends StatelessWidget {
  final String text;
  const _ChordDebugLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.labelSmall?.copyWith(fontFamily: 'monospace'),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Temporary: pitch-class integers to fixed note names.
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
  // Temporary: fixed sharp spelling (Phase 3+ will use tonality-aware spelling).
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
  // Phase 2: keep this very simple and stable.
  // Phase 3: replace with a real formatter using style + tonality spelling.
  switch (q) {
    case ChordQualityToken.major:
      return 'maj';
    case ChordQualityToken.minor:
      return 'min';
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
      return 'min7';
    case ChordQualityToken.halfDiminished7:
      return 'min7(b5)'; // common shorthand
    case ChordQualityToken.diminished7:
      return 'dim7';
  }
}
