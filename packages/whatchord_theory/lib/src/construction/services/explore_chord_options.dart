import '../../formatting/services/note_display_formatter.dart';
import '../../models/chord_extension.dart';
import '../../models/chord_identity.dart';
import 'explore_extension_rules.dart';

enum ExploreExtensionControlRole { highestExtension, addedTones, alterations }

class ExploreExtensionControlGroup {
  const ExploreExtensionControlGroup({
    required this.label,
    required this.role,
    required this.allowsMultiple,
    required this.choices,
  });

  final String label;
  final ExploreExtensionControlRole role;
  final bool allowsMultiple;
  final List<ExploreExtensionChoice> choices;
}

class ExploreExtensionChoice {
  const ExploreExtensionChoice({
    required this.label,
    required this.semanticLabel,
    this.extension,
  });

  final String label;
  final String semanticLabel;
  final ChordExtension? extension;
}

List<ExploreExtensionControlGroup> buildExploreExtensionControlGroups(
  ChordQualityToken quality,
) {
  return quality.isSeventhFamily
      ? _seventhExtensionGroups(quality)
      : _triadLikeExtensionGroups(quality);
}

Set<ChordExtension> selectExploreExtensionChoice({
  required ChordQualityToken quality,
  required Set<ChordExtension> currentExtensions,
  required ExploreExtensionControlGroup group,
  required ExploreExtensionChoice choice,
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
        group.role == ExploreExtensionControlRole.addedTones) {
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

ExploreExtensionChoice _choice(ChordExtension extension) {
  return ExploreExtensionChoice(
    label: theoryTokenDisplayLabel(extension.shortLabel),
    semanticLabel: extension.longLabel,
    extension: extension,
  );
}

List<ExploreExtensionControlGroup> _seventhExtensionGroups(
  ChordQualityToken quality,
) {
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
    ExploreExtensionControlGroup(
      label: 'Stacked extension',
      role: ExploreExtensionControlRole.highestExtension,
      allowsMultiple: false,
      choices: [
        const ExploreExtensionChoice(
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
      ExploreExtensionControlGroup(
        label: 'Added tones',
        role: ExploreExtensionControlRole.addedTones,
        allowsMultiple: true,
        choices: addToneChoices,
      ),
    if (alterationChoices.isNotEmpty)
      ExploreExtensionControlGroup(
        label: 'Alterations',
        role: ExploreExtensionControlRole.alterations,
        allowsMultiple: true,
        choices: alterationChoices,
      ),
  ];
}

List<ExploreExtensionControlGroup> _triadLikeExtensionGroups(
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
      ExploreExtensionControlGroup(
        label: 'Added tones',
        role: ExploreExtensionControlRole.addedTones,
        allowsMultiple: true,
        choices: addToneChoices,
      ),
    if (alterationChoices.isNotEmpty)
      ExploreExtensionControlGroup(
        label: 'Alterations',
        role: ExploreExtensionControlRole.alterations,
        allowsMultiple: true,
        choices: alterationChoices,
      ),
  ];
}

List<ExploreExtensionChoice> _choicesInOrder(
  Set<ChordExtension> available,
  List<ChordExtension> order, {
  ExploreExtensionChoice Function(ChordExtension extension) choiceFor = _choice,
}) {
  return [
    for (final extension in order)
      if (available.contains(extension)) choiceFor(extension),
  ];
}

ExploreExtensionChoice _alterationChoice(ChordExtension extension) {
  return switch (extension) {
    ChordExtension.flat9 => ExploreExtensionChoice(
      label: theoryTokenDisplayLabel('b9'),
      semanticLabel: 'Flat ninth',
      extension: ChordExtension.flat9,
    ),
    ChordExtension.sharp9 => ExploreExtensionChoice(
      label: theoryTokenDisplayLabel('#9'),
      semanticLabel: 'Sharp ninth',
      extension: ChordExtension.sharp9,
    ),
    ChordExtension.sharp11 => ExploreExtensionChoice(
      label: theoryTokenDisplayLabel('#11'),
      semanticLabel: 'Sharp eleventh',
      extension: ChordExtension.sharp11,
    ),
    ChordExtension.flat13 => ExploreExtensionChoice(
      label: theoryTokenDisplayLabel('b13'),
      semanticLabel: 'Flat thirteenth',
      extension: ChordExtension.flat13,
    ),
    _ => _choice(extension),
  };
}

ExploreExtensionChoice _triadLikeAlterationChoice(ChordExtension extension) {
  if (extension == ChordExtension.addSharp9) {
    return ExploreExtensionChoice(
      label: theoryTokenDisplayLabel('#9'),
      semanticLabel: 'Sharp ninth',
      extension: ChordExtension.addSharp9,
    );
  }

  if (extension == ChordExtension.addFlat9) {
    return ExploreExtensionChoice(
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
