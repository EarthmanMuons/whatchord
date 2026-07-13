import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord_theory/analysis/chord_templates.dart';
import 'package:whatchord/features/theory/theory.dart';

void main() {
  test('canonical interval definitions cover every chord quality', () {
    expect(
      chordQualityIntervalSets.map((intervals) => intervals.quality).toSet(),
      ChordQualityToken.values.toSet(),
    );
  });

  test(
    'analysis templates derive their base tones from canonical intervals',
    () {
      for (final template in chordTemplates) {
        final intervals = template.quality.intervals;

        expect(
          template.requiredMask | template.optionalMask,
          intervals.templateBaseMask,
          reason: template.quality.name,
        );
        expect(
          template.requiredMask,
          intervals.templateRequiredMask,
          reason: template.quality.name,
        );
        expect(
          template.optionalMask,
          intervals.omittableMask,
          reason: template.quality.name,
        );
      }
    },
  );
}
