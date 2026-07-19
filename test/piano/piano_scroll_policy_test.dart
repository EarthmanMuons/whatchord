import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord_app/features/piano/piano.dart';

void main() {
  group('PianoScrollPolicy', () {
    // Full 88-key span at 100px white keys: content 5200px, viewport 1040px
    // (10.4 white keys). Key positions used below: C2 (36) at [900, 1000],
    // C3 (48) at [1600, 1700], C4 (60) at [2300, 2400], C7 (96) at
    // [4400, 4500].
    final geometry = PianoGeometry(
      firstWhiteMidi: PianoGeometry.fullKeyboardLowestMidi,
      whiteKeyCount: PianoGeometry.fullKeyboardWhiteKeyCount,
    );
    const viewportWidth = 1040.0;

    KeyboardViewport viewportAt(double offset, {double whiteKeyWidth = 100}) =>
        KeyboardViewport(
          geometry: geometry,
          whiteKeyWidth: whiteKeyWidth,
          width: viewportWidth,
          offset: offset,
          maxScrollExtent:
              whiteKeyWidth * PianoGeometry.fullKeyboardWhiteKeyCount -
              viewportWidth,
        );

    double leftOf(int midi) => viewportAt(0).rectFor(midi).left;
    double rightOf(int midi) => viewportAt(0).rectFor(midi).right;
    double centerOn(KeyboardViewport v, double centerX) =>
        v.clampOffset(centerX - viewportWidth / 2);

    group('indicatorState', () {
      test('nothing highlighted shows no indicators', () {
        expect(
          PianoScrollPolicy.indicatorState(
            viewportAt(1000),
            highlighted: const {},
            previous: ScrollIndicatorState.none,
          ),
          ScrollIndicatorState.none,
        );
      });

      test('an offscreen note on each side shows both cues with reveal '
          'targets', () {
        final viewport = viewportAt(2000);
        final state = PianoScrollPolicy.indicatorState(
          viewport,
          highlighted: const {36, 96},
          previous: ScrollIndicatorState.none,
        );
        expect(state.showLeft, isTrue);
        expect(state.showRight, isTrue);
        expect(
          state.leftTarget,
          leftOf(36) - PianoScrollPolicy.showMargin,
          reason: 'parks the left note just inside the left edge',
        );
        expect(
          state.rightTarget,
          rightOf(96) - viewportWidth + PianoScrollPolicy.showMargin,
          reason: 'parks the right note just inside the right edge',
        );
      });

      test('fully visible notes show no indicators even when previously '
          'shown', () {
        final viewport = viewportAt(centerOn(viewportAt(0), leftOf(60) + 50));
        final state = PianoScrollPolicy.indicatorState(
          viewport,
          highlighted: const {60, 62},
          previous: const ScrollIndicatorState(showLeft: true, showRight: true),
        );
        expect(state, ScrollIndicatorState.none);
      });
    });

    group('centerTarget', () {
      test('centers the highlighted range midpoint', () {
        final viewport = viewportAt(0);
        final target = PianoScrollPolicy.centerTarget(viewport, const {60, 64});
        expect(target, centerOn(viewport, (leftOf(60) + rightOf(64)) / 2));
      });

      test('centers middle C when nothing is highlighted', () {
        final viewport = viewportAt(0);
        final target = PianoScrollPolicy.centerTarget(viewport, const {});
        expect(target, centerOn(viewport, (leftOf(60) + rightOf(60)) / 2));
      });

      test('clamps to the scrollable range at the keyboard ends', () {
        expect(PianoScrollPolicy.centerTarget(viewportAt(2000), const {21}), 0);
        expect(
          PianoScrollPolicy.centerTarget(viewportAt(2000), const {108}),
          viewportAt(0).maxScrollExtent,
        );
      });
    });

    group('autoCenterTarget', () {
      test('stays put while the range is comfortably visible', () {
        final viewport = viewportAt(
          centerOn(viewportAt(0), (leftOf(60) + rightOf(67)) / 2),
        );
        expect(
          PianoScrollPolicy.autoCenterTarget(
            viewport,
            highlighted: const {60, 64, 67},
            added: const {67},
            removed: const {},
          ),
          isNull,
        );
      });

      test('centers a fitting range that drifted offscreen', () {
        final viewport = viewportAt(0);
        final target = PianoScrollPolicy.autoCenterTarget(
          viewport,
          highlighted: const {60, 64, 67},
          added: const {},
          removed: const {},
        );
        expect(target, centerOn(viewport, (leftOf(60) + rightOf(67)) / 2));
      });

      test('skips scrolls smaller than the meaningful delta unless forced', () {
        // At 98px keys, C4..E5 spans 980px: it fits (usable 992px), but the
        // centering delta can sit inside the 12px floor while the range edge
        // is already inside the 24px auto-center margin.
        const w = 98.0;
        final v0 = viewportAt(0, whiteKeyWidth: w);
        final minX = v0.rectFor(60).left;
        final maxX = v0.rectFor(76).right;
        final fitTarget = (minX + maxX) / 2 - viewportWidth / 2;

        final viewport = viewportAt(fitTarget + 8, whiteKeyWidth: w);
        expect(
          minX,
          lessThan(viewport.offset + PianoScrollPolicy.autoCenterEdgeMargin),
          reason: 'sanity: the range must read as offscreen-left',
        );
        expect(
          PianoScrollPolicy.autoCenterTarget(
            viewport,
            highlighted: const {60, 76},
            added: const {},
            removed: const {},
          ),
          isNull,
        );
        expect(
          PianoScrollPolicy.autoCenterTarget(
            viewport,
            highlighted: const {60, 76},
            added: const {},
            removed: const {},
            force: true,
          ),
          fitTarget,
          reason: 'force ignores the delta floor',
        );
      });

      test(
        'prefers revealing newly added notes when the range does not fit',
        () {
          // C2 fully visible on the left, added C7 offscreen right; the range
          // spread far exceeds the viewport.
          final viewport = viewportAt(800);
          final target = PianoScrollPolicy.autoCenterTarget(
            viewport,
            highlighted: const {36, 96},
            added: const {96},
            removed: const {},
          );
          expect(
            target,
            rightOf(96) - viewportWidth + PianoScrollPolicy.showMargin,
          );
        },
      );

      test('holds steady when both sides are offscreen with no additions', () {
        expect(
          PianoScrollPolicy.autoCenterTarget(
            viewportAt(2000),
            highlighted: const {36, 96},
            added: const {},
            removed: const {},
          ),
          isNull,
        );
      });

      test('reanchors toward the nearer end after a removal empties the '
          'view', () {
        // The view sits over the removed middle voice; all survivors are
        // offscreen, and the C7 end is nearer the view center than C2.
        final viewport = viewportAt(2600);
        final target = PianoScrollPolicy.autoCenterTarget(
          viewport,
          highlighted: const {36, 48, 96},
          added: const {},
          removed: const {60},
        );
        expect(
          target,
          rightOf(96) - viewportWidth + PianoScrollPolicy.showMargin,
        );
      });
    });

    group('chevronTarget', () {
      test('centers the range when it fits', () {
        final viewport = viewportAt(0);
        final target = PianoScrollPolicy.chevronTarget(
          viewport,
          highlighted: const {60, 64, 67},
          towardLeft: false,
          indicator: ScrollIndicatorState.none,
        );
        expect(target, centerOn(viewport, (leftOf(60) + rightOf(67)) / 2));
      });

      test('falls back to the indicator target for the tapped side', () {
        final viewport = viewportAt(2000);
        final indicator = PianoScrollPolicy.indicatorState(
          viewport,
          highlighted: const {36, 96},
          previous: ScrollIndicatorState.none,
        );
        expect(
          PianoScrollPolicy.chevronTarget(
            viewport,
            highlighted: const {36, 96},
            towardLeft: true,
            indicator: indicator,
          ),
          indicator.leftTarget,
        );
        expect(
          PianoScrollPolicy.chevronTarget(
            viewport,
            highlighted: const {36, 96},
            towardLeft: false,
            indicator: indicator,
          ),
          indicator.rightTarget,
        );
      });
    });
  });
}
