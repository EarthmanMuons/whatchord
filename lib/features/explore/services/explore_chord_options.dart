import 'package:whatchord/features/theory/domain/theory_domain.dart';

class ExploreExtensionOption {
  const ExploreExtensionOption({
    required this.id,
    required this.label,
    required this.extensions,
  });

  final String id;
  final String label;
  final Set<ChordExtension> extensions;
}

List<ExploreExtensionOption> buildExploreExtensionOptions({
  required ChordQualityToken quality,
  required Set<ChordExtension> currentExtensions,
}) {
  final presets = <Set<ChordExtension>>[
    const <ChordExtension>{},
    ...switch (quality) {
      ChordQualityToken.major ||
      ChordQualityToken.minor ||
      ChordQualityToken.diminished ||
      ChordQualityToken.augmented ||
      ChordQualityToken.sus2 ||
      ChordQualityToken.sus4 ||
      ChordQualityToken.power5 => _triadLikeExtensionPresets,
      ChordQualityToken.major6 ||
      ChordQualityToken.minor6 => _sixFamilyExtensionPresets,
      ChordQualityToken.dominant7 ||
      ChordQualityToken.dominant7sus4 ||
      ChordQualityToken.major7 ||
      ChordQualityToken.minor7 ||
      ChordQualityToken.minorMajor7 ||
      ChordQualityToken.halfDiminished7 ||
      ChordQualityToken.diminished7 => _seventhFamilyExtensionPresets,
    },
  ];

  final normalizedCurrent = normalizeExtensionsForQuality(
    quality: quality,
    extensions: currentExtensions,
  );

  final seen = <String>{};
  final options = <ExploreExtensionOption>[];

  void addOption(Set<ChordExtension> extensions) {
    final normalized = normalizeExtensionsForQuality(
      quality: quality,
      extensions: extensions,
    );
    final id = extensionSetId(normalized);
    if (!seen.add(id)) return;

    options.add(
      ExploreExtensionOption(
        id: id,
        label: extensionSetLabel(normalized),
        extensions: normalized,
      ),
    );
  }

  addOption(normalizedCurrent);
  for (final preset in presets) {
    addOption(preset);
  }

  options.sort((a, b) {
    if (a.extensions.isEmpty && b.extensions.isNotEmpty) return -1;
    if (b.extensions.isEmpty && a.extensions.isNotEmpty) return 1;
    return a.label.compareTo(b.label);
  });

  return List<ExploreExtensionOption>.unmodifiable(options);
}

Set<ChordExtension> normalizeExtensionsForQuality({
  required ChordQualityToken quality,
  required Set<ChordExtension> extensions,
}) {
  final normalized = <ChordExtension>{};

  for (final extension in extensions) {
    switch (extension) {
      case ChordExtension.add9:
        normalized.add(
          quality.isSeventhFamily ? ChordExtension.nine : ChordExtension.add9,
        );
        break;
      case ChordExtension.add11:
        normalized.add(
          quality.isSeventhFamily
              ? ChordExtension.eleven
              : ChordExtension.add11,
        );
        break;
      case ChordExtension.add13:
        normalized.add(
          quality.isSeventhFamily
              ? ChordExtension.thirteen
              : ChordExtension.add13,
        );
        break;
      case ChordExtension.nine:
        normalized.add(
          quality.isSeventhFamily ? ChordExtension.nine : ChordExtension.add9,
        );
        break;
      case ChordExtension.eleven:
        normalized.add(
          quality.isSeventhFamily
              ? ChordExtension.eleven
              : ChordExtension.add11,
        );
        break;
      case ChordExtension.thirteen:
        normalized.add(
          quality.isSeventhFamily
              ? ChordExtension.thirteen
              : ChordExtension.add13,
        );
        break;
      case ChordExtension.flat9:
      case ChordExtension.sharp9:
      case ChordExtension.sharp11:
      case ChordExtension.flat13:
        if (quality.isSeventhFamily) {
          normalized.add(extension);
        }
        break;
    }
  }

  return Set<ChordExtension>.unmodifiable(normalized);
}

String extensionSetId(Set<ChordExtension> extensions) {
  if (extensions.isEmpty) return 'none';

  final ordered = extensions.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return ordered.map((extension) => extension.name).join('|');
}

String extensionSetLabel(Set<ChordExtension> extensions) {
  if (extensions.isEmpty) return 'None';

  final ordered = extensions.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return ordered.map((extension) => extension.shortLabel).join(', ');
}

const _triadLikeExtensionPresets = <Set<ChordExtension>>[
  {ChordExtension.add9},
  {ChordExtension.add11},
  {ChordExtension.add13},
  {ChordExtension.add9, ChordExtension.add11},
  {ChordExtension.add9, ChordExtension.add13},
  {ChordExtension.add11, ChordExtension.add13},
  {ChordExtension.add9, ChordExtension.add11, ChordExtension.add13},
];

const _sixFamilyExtensionPresets = <Set<ChordExtension>>[
  {ChordExtension.add9},
  {ChordExtension.add11},
  {ChordExtension.add9, ChordExtension.add11},
  {ChordExtension.add9, ChordExtension.add13},
];

const _seventhFamilyExtensionPresets = <Set<ChordExtension>>[
  {ChordExtension.nine},
  {ChordExtension.eleven},
  {ChordExtension.thirteen},
  {ChordExtension.flat9},
  {ChordExtension.sharp9},
  {ChordExtension.sharp11},
  {ChordExtension.flat13},
  {ChordExtension.nine, ChordExtension.sharp11},
  {ChordExtension.nine, ChordExtension.thirteen},
  {ChordExtension.nine, ChordExtension.eleven, ChordExtension.thirteen},
  {ChordExtension.flat9, ChordExtension.sharp11},
  {ChordExtension.flat9, ChordExtension.flat13},
  {ChordExtension.sharp9, ChordExtension.flat13},
  {ChordExtension.flat9, ChordExtension.sharp11, ChordExtension.flat13},
];
