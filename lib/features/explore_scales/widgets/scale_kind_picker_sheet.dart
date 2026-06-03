import 'dart:async';

import 'package:flutter/material.dart';

import 'package:whatchord/core/core.dart';
import 'package:whatchord/features/theory/theory.dart';

Future<void> openScaleKindPicker(
  BuildContext context, {
  required ScaleKind selected,
  required ValueChanged<ScaleKind> onSelected,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    ModalBottomSheetRoute<void>(
      builder: (_) =>
          ScaleKindPickerSheet(selected: selected, onSelected: onSelected),
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    ),
  );
}

class ScaleKindPickerSheet extends StatelessWidget {
  const ScaleKindPickerSheet({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ScaleKind selected;
  final ValueChanged<ScaleKind> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModalPanelHeader(title: 'Scale'),
          for (final kind in ScaleKind.values)
            ListTile(
              title: Text(kind.displayLabel),
              selected: kind == selected,
              trailing: kind == selected
                  ? Icon(Icons.check, color: cs.primary)
                  : null,
              onTap: () {
                onSelected(kind);
                unawaited(Navigator.of(context).maybePop());
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
