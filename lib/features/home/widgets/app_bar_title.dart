import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/demo/demo.dart';

class AppBarTitle extends ConsumerWidget {
  const AppBarTitle({super.key});

  // Set to true for ad-hoc demo builds (e.g. iOS device untethered from Xcode).
  static const bool kForceDemoSupport = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'What'),
          const TextSpan(
            text: 'Chord',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    final enableGestures = kDebugMode || kForceDemoSupport;
    if (!enableGestures) return title;

    final demoEnabled = ref.watch(demoModeProvider);
    final modeNotifier = ref.read(demoModeProvider.notifier);
    final seqNotifier = ref.read(demoSequenceProvider.notifier);

    Future<void> toggleDemo() async {
      modeNotifier.setEnabled(!demoEnabled);
      await HapticFeedback.selectionClick();
    }

    void prev() {
      if (!demoEnabled) return;
      seqNotifier.prev();
      modeNotifier.applyCurrentStep();
    }

    void next() {
      if (!demoEnabled) return;
      seqNotifier.next();
      modeNotifier.applyCurrentStep();
    }

    Widget word({
      required String text,
      required TextStyle style,
      required VoidCallback onTap,
      required Future<void> Function() onLongPress,
    }) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        onLongPress: () => onLongPress(),
        child: Text(text, style: style),
      );
    }

    final baseStyle = DefaultTextStyle.of(context).style;

    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: word(
              text: 'What',
              style: baseStyle,
              onTap: prev,
              onLongPress: toggleDemo,
            ),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: word(
              text: 'Chord',
              style: baseStyle.copyWith(fontWeight: FontWeight.w600),
              onTap: next,
              onLongPress: toggleDemo,
            ),
          ),
        ],
      ),
    );
  }
}
