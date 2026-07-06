import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chord_history_notifier.dart';

/// Keeps chord-history capture alive for the app session.
final appChordHistoryLifecycleProvider = Provider<void>((ref) {
  ref.watch(chordHistoryProvider);
});
