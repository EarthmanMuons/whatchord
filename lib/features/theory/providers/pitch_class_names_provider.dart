import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/note_spelling.dart';
import 'note_spelling_policy_provider.dart';

/// 12 pitch-class display names (0..11) based on the current spelling policy.
/// Recomputes only when the policy changes (i.e., when tonality/key signature changes).
final pitchClassNamesProvider = Provider<List<String>>((ref) {
  final policy = ref.watch(noteSpellingPolicyProvider);

  // Small and stable; List.generate is fine here.
  return List<String>.generate(
    12,
    (pc) => pcToName(pc, policy: policy),
    growable: false,
  );
});
