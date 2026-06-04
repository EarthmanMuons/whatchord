import 'package:flutter/material.dart';

import 'package:whatchord/features/theory/theory.dart';

class ScaleDegreeChordList extends StatelessWidget {
  const ScaleDegreeChordList({
    super.key,
    required this.harmony,
    required this.tonality,
    required this.notation,
    required this.noteNameSystem,
    required this.showSevenths,
    required this.selectedOrdinal,
    required this.onDegreeTap,
    required this.onDegreePlay,
  });

  final ScaleHarmony harmony;
  final Tonality tonality;
  final ChordNotationStyle notation;
  final NoteNameSystem noteNameSystem;
  final bool showSevenths;
  final int? selectedOrdinal;
  final ValueChanged<ScaleDegreeHarmony> onDegreeTap;
  final ValueChanged<ScaleDegreeHarmony> onDegreePlay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final degree in harmony.degrees)
          _ScaleDegreeChordTile(
            roman: showSevenths ? degree.seventhRoman : degree.triadRoman,
            symbol: _chordSymbol(degree),
            memberNotes: _memberNotes(degree),
            selected: degree.ordinal == selectedOrdinal,
            onTap: () => onDegreeTap(degree),
            onPlay: () => onDegreePlay(degree),
          ),
      ],
    );
  }

  String _chordSymbol(ScaleDegreeHarmony degree) {
    final quality = showSevenths ? degree.seventhQuality : degree.triadQuality;
    final identity = ChordIdentity(
      rootPc: degree.rootPc,
      bassPc: degree.rootPc,
      quality: quality,
      presentIntervalsMask: quality.canonicalMask,
    );
    final symbol = ChordSymbolBuilder.fromIdentity(
      identity: identity,
      tonality: tonality,
      notation: notation,
      rootName: degree.rootName,
    );
    return chordSymbolDisplayParts(
      symbol,
      noteNameSystem: noteNameSystem,
    ).toString();
  }

  String _memberNotes(ScaleDegreeHarmony degree) {
    final n = harmony.toneNames.length;
    final root = degree.ordinal - 1;
    final indices = [
      root,
      (root + 2) % n,
      (root + 4) % n,
      if (showSevenths) (root + 6) % n,
    ];
    return [
      for (final index in indices)
        noteDisplayLabel(
          harmony.toneNames[index],
          noteNameSystem: noteNameSystem,
        ),
    ].join(' · ');
  }
}

class _ScaleDegreeChordTile extends StatelessWidget {
  const _ScaleDegreeChordTile({
    required this.roman,
    required this.symbol,
    required this.memberNotes,
    required this.selected,
    required this.onTap,
    required this.onPlay,
  });

  final String roman;
  final String symbol;
  final String memberNotes;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final romanColor = selected ? cs.onPrimaryContainer : cs.primary;
    final symbolColor = selected ? cs.onPrimaryContainer : cs.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Scale degree $roman, $symbol',
      hint: memberNotes,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: selected ? cs.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Text.rich(
                      TextSpan(children: scaleDegreeRomanSpans(roman)),
                      style: textTheme.titleMedium?.copyWith(
                        color: romanColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      symbol,
                      style: textTheme.titleLarge?.copyWith(color: symbolColor),
                    ),
                  ),
                  IconButton(
                    onPressed: onPlay,
                    tooltip: 'Play chord',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: Icon(
                      Icons.play_arrow,
                      color: selected ? cs.onPrimaryContainer : cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
