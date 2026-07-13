import '../../formatting/services/note_display_formatter.dart';
import '../../models/chord_extension.dart';
import '../../models/chord_identity.dart';
import 'extension_rules.dart';

/// How a group of extension choices behaves for a quality.
enum ExtensionControlRole { highestExtension, addedTones, alterations }

/// A labeled group of extension choices that are valid together on a quality.
class ExtensionControlGroup {
  const ExtensionControlGroup({
    required this.label,
    required this.role,
    required this.allowsMultiple,
    required this.choices,
  });

  /// Display heading for the group (e.g. "Alterations").
  final String label;

  /// The group's selection behavior.
  final ExtensionControlRole role;

  /// Whether multiple choices may be selected at once.
  final bool allowsMultiple;

  /// The selectable choices, in display order.
  final List<ExtensionChoice> choices;
}

/// One selectable extension option, or the "none" option when [extension] is
/// null.
class ExtensionChoice {
  const ExtensionChoice({
    required this.label,
    required this.semanticLabel,
    this.extension,
  });

  /// Compact display label (e.g. "#11").
  final String label;

  /// Spoken/accessibility label (e.g. "sharp eleven").
  final String semanticLabel;

  /// The extension this choice selects, or null for "none".
  final ChordExtension? extension;
}

/// The extension choice groups that make musical sense on [quality].
List<ExtensionControlGroup> buildExtensionControlGroups(
  ChordQualityToken quality,
) {
  return quality.isSeventhFamily
      ? _seventhExtensionGroups(quality)
      : _triadLikeExtensionGroups(quality);
}

/// Applies picking [choice] from [group] to [currentExtensions], resolving
/// conflicts so the result stays musically coherent on [quality].
Set<ChordExtension> selectExtensionChoice({
  required ChordQualityToken quality,
  required Set<ChordExtension> currentExtensions,
  required ExtensionControlGroup group,
  required ExtensionChoice choice,
}) {
  final next = normalizeExtensionsForQuality(
    quality: quality,
    extensions: currentExtensions,
  ).toSet();

  if (group.allowsMultiple) {
    final extension = choice.extension;
    if (extension == null) return Set<ChordExtension>.unmodifiable(next);

    var selected = false;
    if (next.contains(extension)) {
      next.remove(extension);
    } else {
      removeTriadLikeConflicts(next, extension);
      removeSeventhConflicts(next, extension);
      next.add(extension);
      selected = true;
    }

    if (selected &&
        quality.isSeventhFamily &&
        group.role == ExtensionControlRole.addedTones) {
      promoteAddedToneToStack(next, extension);
    }
  } else {
    for (final option in group.choices) {
      final extension = option.extension;
      if (extension != null) next.remove(extension);
    }

    final extension = choice.extension;
    if (extension != null) {
      removeSeventhConflicts(next, extension);
      next.add(extension);
    }
  }

  return normalizeExtensionsForQuality(quality: quality, extensions: next);
}

ExtensionChoice _choice(ChordExtension extension) {
  return ExtensionChoice(
    label: theoryTokenDisplayLabel(extension.shortLabel),
    semanticLabel: extension.longLabel,
    extension: extension,
  );
}

List<ExtensionControlGroup> _seventhExtensionGroups(ChordQualityToken quality) {
  final addToneChoices = _choicesInOrder(
    seventhAddTones(quality),
    _seventhAddToneChoiceOrder,
  );
  final alterationChoices = _choicesInOrder(
    seventhAlterations(quality),
    _seventhAlterationChoiceOrder,
    choiceFor: _alterationChoice,
  );

  return [
    ExtensionControlGroup(
      label: 'Stacked extension',
      role: ExtensionControlRole.highestExtension,
      allowsMultiple: false,
      choices: [
        const ExtensionChoice(
          label: 'None',
          semanticLabel: 'No highest extension',
        ),
        ..._choicesInOrder(
          seventhStackExtensions(quality),
          _seventhStackChoiceOrder,
        ),
      ],
    ),
    if (addToneChoices.isNotEmpty)
      ExtensionControlGroup(
        label: 'Added tones',
        role: ExtensionControlRole.addedTones,
        allowsMultiple: true,
        choices: addToneChoices,
      ),
    if (alterationChoices.isNotEmpty)
      ExtensionControlGroup(
        label: 'Alterations',
        role: ExtensionControlRole.alterations,
        allowsMultiple: true,
        choices: alterationChoices,
      ),
  ];
}

List<ExtensionControlGroup> _triadLikeExtensionGroups(
  ChordQualityToken quality,
) {
  final addToneChoices = _choicesInOrder(
    triadLikeAddTones(quality),
    _triadLikeAddToneChoiceOrder,
  );
  final alterationChoices = _choicesInOrder(
    triadLikeAlterations(quality),
    _triadLikeAlterationChoiceOrder,
    choiceFor: _triadLikeAlterationChoice,
  );

  return [
    if (addToneChoices.isNotEmpty)
      ExtensionControlGroup(
        label: 'Added tones',
        role: ExtensionControlRole.addedTones,
        allowsMultiple: true,
        choices: addToneChoices,
      ),
    if (alterationChoices.isNotEmpty)
      ExtensionControlGroup(
        label: 'Alterations',
        role: ExtensionControlRole.alterations,
        allowsMultiple: true,
        choices: alterationChoices,
      ),
  ];
}

List<ExtensionChoice> _choicesInOrder(
  Set<ChordExtension> available,
  List<ChordExtension> order, {
  ExtensionChoice Function(ChordExtension extension) choiceFor = _choice,
}) {
  return [
    for (final extension in order)
      if (available.contains(extension)) choiceFor(extension),
  ];
}

ExtensionChoice _alterationChoice(ChordExtension extension) {
  return switch (extension) {
    ChordExtension.flat9 => ExtensionChoice(
      label: theoryTokenDisplayLabel('b9'),
      semanticLabel: 'Flat ninth',
      extension: ChordExtension.flat9,
    ),
    ChordExtension.sharp9 => ExtensionChoice(
      label: theoryTokenDisplayLabel('#9'),
      semanticLabel: 'Sharp ninth',
      extension: ChordExtension.sharp9,
    ),
    ChordExtension.sharp11 => ExtensionChoice(
      label: theoryTokenDisplayLabel('#11'),
      semanticLabel: 'Sharp eleventh',
      extension: ChordExtension.sharp11,
    ),
    ChordExtension.flat13 => ExtensionChoice(
      label: theoryTokenDisplayLabel('b13'),
      semanticLabel: 'Flat thirteenth',
      extension: ChordExtension.flat13,
    ),
    _ => _choice(extension),
  };
}

ExtensionChoice _triadLikeAlterationChoice(ChordExtension extension) {
  if (extension == ChordExtension.addSharp9) {
    return ExtensionChoice(
      label: theoryTokenDisplayLabel('#9'),
      semanticLabel: 'Sharp ninth',
      extension: ChordExtension.addSharp9,
    );
  }

  if (extension == ChordExtension.addFlat9) {
    return ExtensionChoice(
      label: theoryTokenDisplayLabel('b9'),
      semanticLabel: 'Flat ninth',
      extension: ChordExtension.addFlat9,
    );
  }

  return _alterationChoice(extension);
}

const _seventhStackChoiceOrder = [
  ChordExtension.nine,
  ChordExtension.eleven,
  ChordExtension.thirteen,
];

const _seventhAddToneChoiceOrder = [ChordExtension.add11];

const _seventhAlterationChoiceOrder = [
  ChordExtension.flat9,
  ChordExtension.sharp9,
  ChordExtension.sharp11,
  ChordExtension.flat13,
];

const _triadLikeAddToneChoiceOrder = [
  ChordExtension.add9,
  ChordExtension.add11,
  ChordExtension.add13,
];

const _triadLikeAlterationChoiceOrder = [
  ChordExtension.flat9,
  ChordExtension.addFlat9,
  ChordExtension.addSharp9,
  ChordExtension.sharp11,
  ChordExtension.flat13,
];
