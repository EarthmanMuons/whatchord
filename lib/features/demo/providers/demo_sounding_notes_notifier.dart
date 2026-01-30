import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'demo_mode_notifier.dart';
import 'demo_sequence_notifier.dart';

final demoSoundingNotesProvider = Provider<Set<int>>((ref) {
  final enabled = ref.watch(demoModeProvider);
  if (!enabled) return const <int>{};

  final seq = ref.watch(demoSequenceProvider);
  final step = DemoSequenceNotifier.steps[seq.index];

  return step.notes ?? const <int>{};
});
