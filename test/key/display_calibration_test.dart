import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/key/key.dart';

void main() {
  List<KeyEstimate> posterior(Map<int, double> byIndex) => [
    for (var k = 0; k < 24; k++)
      KeyEstimate(
        tonality: KeySpace.canonicalTonalities[k],
        confidence:
            byIndex[k] ??
            (1 - byIndex.values.fold(0.0, (a, b) => a + b)) /
                (24 - byIndex.length),
      ),
  ]..sort((a, b) => b.confidence.compareTo(a.confidence));

  test('calibration preserves order and normalization', () {
    final raw = posterior({0: 0.9, 14: 0.05});
    final calibrated = DisplayCalibration.calibrate(raw);
    expect(calibrated.length, 24);
    final total = calibrated.fold(0.0, (sum, e) => sum + e.confidence);
    expect(total, closeTo(1.0, 1e-9));
    for (var i = 0; i < raw.length; i++) {
      expect(calibrated[i].tonality, raw[i].tonality);
    }
    for (var i = 1; i < calibrated.length; i++) {
      expect(
        calibrated[i].confidence,
        lessThanOrEqualTo(calibrated[i - 1].confidence),
      );
    }
  });

  test('the shipped temperature flattens overconfidence', () {
    final raw = posterior({0: 0.93});
    final calibrated = DisplayCalibration.calibrate(raw);
    expect(calibrated.first.confidence, lessThan(raw.first.confidence));
    expect(calibrated.first.confidence, greaterThan(0.5));
  });

  test('temperature one is the identity', () {
    final raw = posterior({0: 0.6, 1: 0.2});
    final calibrated = DisplayCalibration.calibrate(raw, temperature: 1);
    expect(identical(calibrated, raw), isTrue);
  });
}
