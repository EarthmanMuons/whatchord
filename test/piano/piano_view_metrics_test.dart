import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord_app/features/piano/piano.dart';

void main() {
  group('resolvePianoViewMetrics', () {
    PianoViewMetrics resolve({
      double viewportWidth = 360,
      int baseWhiteKeyCount = 21,
      double baseAspectRatio = 7.0,
      bool tightenForStatusBar = false,
      double maxHeight = 400,
      PianoViewSettings settings = const PianoViewSettings.defaults(),
    }) {
      return resolvePianoViewMetrics(
        viewportWidth: viewportWidth,
        baseWhiteKeyCount: baseWhiteKeyCount,
        baseAspectRatio: baseAspectRatio,
        tightenForStatusBar: tightenForStatusBar,
        maxHeight: maxHeight,
        settings: settings,
      );
    }

    test('defaults keep the full visible key count and base height', () {
      final m = resolve();
      expect(m.visibleWhiteKeyCount, 21);
      // 360 / 21 * 7 = 120
      expect(m.height, closeTo(120, 0.001));
      expect(m.baseHeight, closeTo(120, 0.001));
    });

    test('width scale reduces the visible key count (wider keys)', () {
      final m = resolve(
        settings: const PianoViewSettings(widthScale: 2.0, heightScale: 1.0),
      );
      // round(21 / 2) = 11 (well above the floor of 8)
      expect(m.visibleWhiteKeyCount, 11);
    });

    test('width scale never drops below the minimum visible count', () {
      final m = resolve(
        baseWhiteKeyCount: 21,
        settings: const PianoViewSettings(widthScale: 3.0, heightScale: 1.0),
      );
      // round(21 / 3) = 7 -> clamped up to 8
      expect(m.visibleWhiteKeyCount, 8);
    });

    test('width scale never exceeds the base visible count', () {
      final m = resolve(
        settings: const PianoViewSettings(widthScale: 1.0, heightScale: 1.0),
      );
      expect(m.visibleWhiteKeyCount, lessThanOrEqualTo(21));
    });

    test('height scale grows the keyboard up to the available ceiling', () {
      final m = resolve(
        maxHeight: 400,
        settings: const PianoViewSettings(widthScale: 1.0, heightScale: 2.0),
      );
      // base 120 * 2 = 240, below the 400 ceiling
      expect(m.height, closeTo(240, 0.001));
    });

    test('height is clamped to the available max height', () {
      final m = resolve(
        maxHeight: 150,
        settings: const PianoViewSettings(widthScale: 1.0, heightScale: 3.0),
      );
      expect(m.height, closeTo(150, 0.001));
    });

    test('a max height below the base floors the keyboard at base height', () {
      final m = resolve(
        maxHeight: 50, // less than the 120 base
        settings: const PianoViewSettings(widthScale: 1.0, heightScale: 3.0),
      );
      expect(m.height, closeTo(120, 0.001));
      expect(m.maxHeight, closeTo(120, 0.001));
    });

    test('tightenForStatusBar trims the base height', () {
      final tight = resolve(tightenForStatusBar: true);
      final normal = resolve(tightenForStatusBar: false);
      expect(tight.baseHeight, closeTo(normal.baseHeight - 4, 0.001));
    });

    test('base height stays stable as the keys are widened', () {
      final zoomed = resolve(
        settings: const PianoViewSettings(widthScale: 2.0, heightScale: 1.0),
      );
      final unzoomed = resolve();
      expect(zoomed.baseHeight, closeTo(unzoomed.baseHeight, 0.001));
    });
  });

  group('heightScaleForHeight', () {
    test('maps a target height to a clamped scale', () {
      expect(heightScaleForHeight(height: 240, baseHeight: 120), 2.0);
      expect(heightScaleForHeight(height: 120, baseHeight: 120), 1.0);
    });

    test('never returns below the minimum scale', () {
      expect(heightScaleForHeight(height: 60, baseHeight: 120), 1.0);
    });

    test('guards against a non-positive base height', () {
      expect(heightScaleForHeight(height: 200, baseHeight: 0), 1.0);
    });
  });
}
