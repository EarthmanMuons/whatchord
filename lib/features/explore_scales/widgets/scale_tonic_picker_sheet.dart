import 'dart:async';

import 'package:flutter/material.dart';

import 'package:whatchord/core/core.dart';
import 'package:whatchord/features/theory/theory.dart';

const _canonicalTonics = <Tonic>[
  Tonic.c,
  Tonic.dFlat,
  Tonic.d,
  Tonic.eFlat,
  Tonic.e,
  Tonic.f,
  Tonic.gFlat,
  Tonic.g,
  Tonic.aFlat,
  Tonic.a,
  Tonic.bFlat,
  Tonic.b,
];

Future<void> openTonicPicker(
  BuildContext context, {
  required Tonic selected,
  required NoteNameSystem noteNameSystem,
  required ValueChanged<Tonic> onSelected,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    ModalBottomSheetRoute<void>(
      builder: (_) => ScaleTonicPickerSheet(
        selected: selected,
        noteNameSystem: noteNameSystem,
        onSelected: onSelected,
      ),
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    ),
  );
}

class ScaleTonicPickerSheet extends StatelessWidget {
  const ScaleTonicPickerSheet({
    super.key,
    required this.selected,
    required this.noteNameSystem,
    required this.onSelected,
  });

  final Tonic selected;
  final NoteNameSystem noteNameSystem;
  final ValueChanged<Tonic> onSelected;

  @override
  Widget build(BuildContext context) {
    // Preserve the current spelling (e.g. F#) when it differs from the
    // flat-leaning default for that pitch class.
    final choices = [
      for (final tonic in _canonicalTonics)
        tonic.pitchClass == selected.pitchClass ? selected : tonic,
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModalPanelHeader(title: 'Tonic'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tonic in choices)
                  ChoiceChip(
                    label: Text(
                      noteDisplayLabel(
                        tonic.label,
                        noteNameSystem: noteNameSystem,
                      ),
                    ),
                    selected: tonic == selected,
                    showCheckmark: false,
                    onSelected: (_) {
                      onSelected(tonic);
                      unawaited(Navigator.of(context).maybePop());
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
