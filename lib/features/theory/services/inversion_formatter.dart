import '../domain/models/chord_identity.dart';

abstract final class InversionFormatter {
  static String? format(ChordIdentity id) {
    if (!id.hasSlashBass) return null;

    final bassInterval = _interval(id.bassPc, id.rootPc);

    return id.quality.isSeventhFamily
        ? _seventhInversion(bassInterval)
        : _triadInversion(bassInterval);
  }

  static String? _triadInversion(int bassInterval) {
    return switch (bassInterval) {
      3 ||
      4 ||
      5 ||
      2 => '1st inversion', // covers minor/major third and sus variants
      7 || 6 || 8 => '2nd inversion', // perfect/dim/aug fifth
      _ => null, // non-chord-tone bass or extension bass
    };
  }

  static String? _seventhInversion(int bassInterval) {
    return switch (bassInterval) {
      3 || 4 || 5 || 2 => '1st inversion',
      7 || 6 || 8 => '2nd inversion',
      9 ||
      10 ||
      11 => '3rd inversion', // dim7 uses 9; dom7 uses 10; maj7 uses 11
      _ => null,
    };
  }

  static int _interval(int pc, int rootPc) {
    final d = pc - rootPc;
    final m = d % 12;
    return m < 0 ? m + 12 : m;
  }
}
