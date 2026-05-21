import 'package:whatchord/features/theory/theory.dart';

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
  if (quality.isSeventhFamily) {
    final stack = seventhStackExtensions(quality);
    final addTones = seventhAddTones(quality);
    final alterations = seventhAlterations(quality);
    final stackChoices = <ExploreExtensionChoice>[
      const ExploreExtensionChoice(
        label: 'None',
        semanticLabel: 'No highest extension',
      ),
      if (stack.contains(ChordExtension.nine)) _choice(ChordExtension.nine),
      if (stack.contains(ChordExtension.eleven)) _choice(ChordExtension.eleven),
      if (stack.contains(ChordExtension.thirteen))
        _choice(ChordExtension.thirteen),
    ];
    final addToneChoices = <ExploreExtensionChoice>[
      if (addTones.contains(ChordExtension.add9)) _choice(ChordExtension.add9),
      if (addTones.contains(ChordExtension.add11))
        _choice(ChordExtension.add11),
      if (addTones.contains(ChordExtension.add13))
        _choice(ChordExtension.add13),
    ];
    final alterationChoices = <ExploreExtensionChoice>[
      if (alterations.contains(ChordExtension.flat9))
        ExploreExtensionChoice(
          label: theoryTokenDisplayLabel('b9'),
          semanticLabel: 'Flat ninth',
          extension: ChordExtension.flat9,
        ),
      if (alterations.contains(ChordExtension.sharp9))
        ExploreExtensionChoice(
          label: theoryTokenDisplayLabel('#9'),
          semanticLabel: 'Sharp ninth',
          extension: ChordExtension.sharp9,
        ),
      if (alterations.contains(ChordExtension.sharp11))
        ExploreExtensionChoice(
          label: theoryTokenDisplayLabel('#11'),
          semanticLabel: 'Sharp eleventh',
          extension: ChordExtension.sharp11,
        ),
      if (alterations.contains(ChordExtension.flat13))
        ExploreExtensionChoice(
          label: theoryTokenDisplayLabel('b13'),
          semanticLabel: 'Flat thirteenth',
          extension: ChordExtension.flat13,
        ),
    ];

    return [
      ExploreExtensionControlGroup(
        label: 'Stacked extension',
        role: ExploreExtensionControlRole.highestExtension,
        allowsMultiple: false,
        choices: stackChoices,
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

  final addTones = triadLikeAddTones(quality);
  final alterations = triadLikeAlterations(quality);
  return [
    if (addTones.isNotEmpty)
      ExploreExtensionControlGroup(
        label: 'Added tones',
        role: ExploreExtensionControlRole.addedTones,
        allowsMultiple: true,
        choices: [
          if (addTones.contains(ChordExtension.add9))
            _choice(ChordExtension.add9),
          if (addTones.contains(ChordExtension.add11))
            _choice(ChordExtension.add11),
          if (addTones.contains(ChordExtension.add13))
            _choice(ChordExtension.add13),
        ],
      ),
    if (alterations.isNotEmpty)
      ExploreExtensionControlGroup(
        label: 'Alterations',
        role: ExploreExtensionControlRole.alterations,
        allowsMultiple: true,
        choices: [
          if (alterations.contains(ChordExtension.flat9))
            _choice(ChordExtension.flat9),
          if (alterations.contains(ChordExtension.sharp11))
            _choice(ChordExtension.sharp11),
        ],
      ),
  ];
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
