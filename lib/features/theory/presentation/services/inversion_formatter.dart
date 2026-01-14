import '../../domain/theory_domain.dart';
import 'chord_tone_role_token_labels.dart';

abstract final class InversionFormatter {
  static String? format(ChordIdentity id) {
    if (!id.hasSlashBass) return null;

    final bassInterval = _interval(id.bassPc, id.rootPc);

    // Only treat true chord-members as inversions (root/3rd/5th/7th).
    final isCoreMember = _coreMemberIntervals(
      id.quality,
    ).contains(bassInterval);

    if (!isCoreMember) {
      final role = id.toneRolesByInterval[bassInterval];
      return role == null ? 'non-root bass' : 'non-root bass: ${role.label}';
    }

    // Bass is a core chord tone -> classical inversion naming is appropriate.
    return id.quality.isSeventhFamily
        ? _seventhInversion(bassInterval)
        : _triadInversion(bassInterval);
  }

  static Set<int> _coreMemberIntervals(ChordQualityToken q) {
    switch (q) {
      // Triad-family
      case ChordQualityToken.major:
      case ChordQualityToken.major6:
        return const {0, 4, 7}; // 1, 3, 5

      case ChordQualityToken.minor:
      case ChordQualityToken.minor6:
        return const {0, 3, 7}; // 1, b3, 5

      case ChordQualityToken.diminished:
        return const {0, 3, 6}; // 1, b3, b5

      case ChordQualityToken.augmented:
        return const {0, 4, 8}; // 1, 3, #5

      case ChordQualityToken.sus2:
        return const {0, 2, 7}; // 1, 2, 5

      case ChordQualityToken.sus4:
        return const {0, 5, 7}; // 1, 4, 5

      case ChordQualityToken.power5:
        return const {0, 7}; // 1, 5

      // Seventh-family (include the seventh as core)
      case ChordQualityToken.dominant7:
        return const {0, 4, 7, 10}; // 1, 3, 5, b7

      case ChordQualityToken.dominant7sus4:
        return const {0, 5, 7, 10}; // 1, 4, 5, b7

      case ChordQualityToken.major7:
        return const {0, 4, 7, 11}; // 1, 3, 5, 7

      case ChordQualityToken.minor7:
        return const {0, 3, 7, 10}; // 1, b3, 5, b7

      case ChordQualityToken.minorMajor7:
        return const {0, 3, 7, 11}; // 1, b3, 5, 7

      case ChordQualityToken.halfDiminished7:
        return const {0, 3, 6, 10}; // 1, b3, b5, b7

      case ChordQualityToken.diminished7:
        return const {0, 3, 6, 9}; // 1, b3, b5, bb7(=6)
    }
  }

  static String? _triadInversion(int bassInterval) {
    return switch (bassInterval) {
      3 || 4 || 5 || 2 => '1st inversion', // 3rd-ish bass incl sus
      7 || 6 || 8 => '2nd inversion', // 5th-ish bass
      _ => null,
    };
  }

  static String? _seventhInversion(int bassInterval) {
    return switch (bassInterval) {
      3 || 4 || 5 || 2 => '1st inversion',
      7 || 6 || 8 => '2nd inversion',
      9 || 10 || 11 => '3rd inversion', // dim7=9, dom/min7=10, maj7=11
      _ => null,
    };
  }

  static int _interval(int pc, int rootPc) {
    final d = pc - rootPc;
    final m = d % 12;
    return m < 0 ? m + 12 : m;
  }
}
