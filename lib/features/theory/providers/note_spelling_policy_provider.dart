import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/theory_domain.dart';
import 'selected_key_signature_provider.dart';

final noteSpellingPolicyProvider = Provider<NoteSpellingPolicy>((ref) {
  final ks = ref.watch(selectedKeySignatureProvider);
  return NoteSpellingPolicy(preferFlats: ks.prefersFlats);
});
