import '../models/chord_extension.dart';
import '../models/chord_identity.dart';
import '../models/chord_tone_role.dart';

/// Builds chord-tone roles for tones present in the voicing, relative to the root.
/// This is the key mechanism that enables "#11 vs b5" spelling decisions.
abstract final class ChordToneRoles {
  static Map<int, ChordToneRole> build({
    required ChordQualityToken quality,
    required Set<ChordExtension> extensions,
    required int
    relMask, // 12-bit mask of intervals above root present in voicing
  }) {
    final out = <int, ChordToneRole>{};

    bool hasInterval(int i) => (relMask & (1 << (i % 12))) != 0;

    // Always include root if present (it should be, by analyzer invariant).
    if (hasInterval(0)) out[0] = ChordToneRole.root;

    // ---- Base chord tones (quality) -----------------------------------------
    void addBase(int interval, ChordToneRole role) {
      if (hasInterval(interval)) out[interval] = role;
    }

    switch (quality) {
      case ChordQualityToken.major:
        addBase(4, ChordToneRole.major3);
        addBase(7, ChordToneRole.perfect5);
        break;

      case ChordQualityToken.minor:
        addBase(3, ChordToneRole.minor3);
        addBase(7, ChordToneRole.perfect5);
        break;

      case ChordQualityToken.diminished:
        addBase(3, ChordToneRole.minor3);
        addBase(6, ChordToneRole.flat5);
        break;

      case ChordQualityToken.augmented:
        addBase(4, ChordToneRole.major3);
        addBase(8, ChordToneRole.sharp5);
        break;

      case ChordQualityToken.sus2:
        addBase(2, ChordToneRole.sus2);
        addBase(7, ChordToneRole.perfect5);
        break;

      case ChordQualityToken.sus4:
        addBase(5, ChordToneRole.sus4);
        addBase(7, ChordToneRole.perfect5);
        break;

      case ChordQualityToken.power5:
        addBase(7, ChordToneRole.perfect5);
        break;

      case ChordQualityToken.major6:
        addBase(4, ChordToneRole.major3);
        addBase(7, ChordToneRole.perfect5);
        addBase(9, ChordToneRole.sixth);
        break;

      case ChordQualityToken.minor6:
        addBase(3, ChordToneRole.minor3);
        addBase(7, ChordToneRole.perfect5);
        addBase(9, ChordToneRole.sixth);
        break;

      case ChordQualityToken.dominant7:
        addBase(4, ChordToneRole.major3);
        addBase(7, ChordToneRole.perfect5);
        addBase(10, ChordToneRole.flat7);
        break;

      case ChordQualityToken.major7:
        addBase(4, ChordToneRole.major3);
        addBase(7, ChordToneRole.perfect5);
        addBase(11, ChordToneRole.major7);
        break;

      case ChordQualityToken.minor7:
        addBase(3, ChordToneRole.minor3);
        addBase(7, ChordToneRole.perfect5);
        addBase(10, ChordToneRole.flat7);
        break;

      case ChordQualityToken.halfDiminished7:
        addBase(3, ChordToneRole.minor3);
        addBase(6, ChordToneRole.flat5);
        addBase(10, ChordToneRole.flat7);
        break;

      case ChordQualityToken.diminished7:
        addBase(3, ChordToneRole.minor3);
        addBase(6, ChordToneRole.flat5);
        // Fully diminished seventh is "bb7" (interval 9 above root).
        addBase(9, ChordToneRole.dim7);
        break;
    }

    // ---- Extensions / add-tones --------------------------------------------
    void addExt(int interval, ChordToneRole role) {
      // If the interval is already claimed by the base chord tone,
      // prefer the base role. This avoids b13 vs #5 conflicts in augmented triads,
      // and keeps diminished chords' 6 as b5 rather than #11.
      if (!hasInterval(interval)) return;
      if (out.containsKey(interval)) return;
      out[interval] = role;
    }

    for (final e in extensions) {
      switch (e) {
        case ChordExtension.flat9:
          addExt(1, ChordToneRole.flat9);
          break;
        case ChordExtension.nine:
          addExt(2, ChordToneRole.nine);
          break;
        case ChordExtension.sharp9:
          addExt(3, ChordToneRole.sharp9);
          break;
        case ChordExtension.eleven:
          addExt(5, ChordToneRole.eleven);
          break;
        case ChordExtension.sharp11:
          addExt(6, ChordToneRole.sharp11);
          break;
        case ChordExtension.flat13:
          addExt(8, ChordToneRole.flat13);
          break;
        case ChordExtension.thirteen:
          addExt(9, ChordToneRole.thirteenth);
          break;

        case ChordExtension.add9:
          addExt(2, ChordToneRole.add9);
          break;
        case ChordExtension.add11:
          addExt(5, ChordToneRole.add11);
          break;
        case ChordExtension.add13:
          addExt(9, ChordToneRole.add13);
          break;
      }
    }

    return out;
  }
}
