import '../models/chord_extension.dart';
import '../models/chord_identity.dart';
import '../models/chord_tone_role.dart';
import 'interval_constants.dart';

/// Builds chord-tone roles for tones present in the voicing, relative to the root.
/// This is the key mechanism that enables "#11 vs b5" spelling decisions.
abstract final class ChordToneRoles {
  static Map<int, ChordToneRole> build({
    required ChordQuality quality,
    required Set<ChordExtension> extensions,
    required int
    relMask, // 12-bit mask of intervals above root present in voicing
  }) {
    final out = <int, ChordToneRole>{};

    bool hasInterval(int i) => (relMask & (1 << (i % 12))) != 0;

    // Always include root if present (it should be, by analyzer invariant).
    if (hasInterval(chordRootInterval)) {
      out[chordRootInterval] = ChordToneRole.root;
    }

    // ---- Base chord tones (quality) -----------------------------------------
    void addBase(int interval, ChordToneRole role) {
      if (hasInterval(interval)) out[interval] = role;
    }

    switch (quality) {
      case ChordQuality.major:
        addBase(majorThirdInterval, ChordToneRole.major3);
        addBase(perfectFifthInterval, ChordToneRole.perfect5);
        break;

      case ChordQuality.majorFlat5:
        addBase(majorThirdInterval, ChordToneRole.major3);
        addBase(diminishedFifthInterval, ChordToneRole.flat5);
        break;

      case ChordQuality.minor:
        addBase(minorThirdInterval, ChordToneRole.minor3);
        addBase(perfectFifthInterval, ChordToneRole.perfect5);
        break;

      case ChordQuality.minorSharp5:
        addBase(minorThirdInterval, ChordToneRole.minor3);
        addBase(augmentedFifthInterval, ChordToneRole.sharp5);
        break;

      case ChordQuality.diminished:
        addBase(minorThirdInterval, ChordToneRole.minor3);
        addBase(diminishedFifthInterval, ChordToneRole.flat5);
        break;

      case ChordQuality.augmented:
        addBase(majorThirdInterval, ChordToneRole.major3);
        addBase(augmentedFifthInterval, ChordToneRole.sharp5);
        break;

      case ChordQuality.power:
        addBase(perfectFifthInterval, ChordToneRole.perfect5);
        break;

      case ChordQuality.sus2:
        addBase(majorSecondInterval, ChordToneRole.sus2);
        addBase(perfectFifthInterval, ChordToneRole.perfect5);
        break;

      case ChordQuality.sus4:
        addBase(perfectFourthInterval, ChordToneRole.sus4);
        addBase(perfectFifthInterval, ChordToneRole.perfect5);
        break;

      case ChordQuality.sus2sus4:
        addBase(majorSecondInterval, ChordToneRole.sus2);
        addBase(perfectFourthInterval, ChordToneRole.sus4);
        addBase(perfectFifthInterval, ChordToneRole.perfect5);
        break;

      case ChordQuality.major6:
        addBase(majorThirdInterval, ChordToneRole.major3);
        addBase(perfectFifthInterval, ChordToneRole.perfect5);
        addBase(majorSixthInterval, ChordToneRole.sixth);
        break;

      case ChordQuality.minor6:
        addBase(minorThirdInterval, ChordToneRole.minor3);
        addBase(perfectFifthInterval, ChordToneRole.perfect5);
        addBase(majorSixthInterval, ChordToneRole.sixth);
        break;

      case ChordQuality.dominant7:
        addBase(majorThirdInterval, ChordToneRole.major3);
        addBase(perfectFifthInterval, ChordToneRole.perfect5);
        addBase(minorSeventhInterval, ChordToneRole.flat7);
        break;

      case ChordQuality.dominant7sus2:
        addBase(majorSecondInterval, ChordToneRole.sus2);
        addBase(perfectFifthInterval, ChordToneRole.perfect5);
        addBase(minorSeventhInterval, ChordToneRole.flat7);
        break;

      case ChordQuality.dominant7sus4:
        addBase(perfectFourthInterval, ChordToneRole.sus4);
        addBase(perfectFifthInterval, ChordToneRole.perfect5);
        addBase(minorSeventhInterval, ChordToneRole.flat7);
        break;

      case ChordQuality.dominant7Flat5:
        addBase(majorThirdInterval, ChordToneRole.major3);
        addBase(diminishedFifthInterval, ChordToneRole.flat5);
        addBase(minorSeventhInterval, ChordToneRole.flat7);
        break;

      case ChordQuality.dominant7Sharp5:
        addBase(majorThirdInterval, ChordToneRole.major3);
        addBase(augmentedFifthInterval, ChordToneRole.sharp5);
        addBase(minorSeventhInterval, ChordToneRole.flat7);
        break;

      case ChordQuality.major7:
        addBase(majorThirdInterval, ChordToneRole.major3);
        addBase(perfectFifthInterval, ChordToneRole.perfect5);
        addBase(majorSeventhInterval, ChordToneRole.major7);
        break;

      case ChordQuality.major7sus2:
        addBase(majorSecondInterval, ChordToneRole.sus2);
        addBase(perfectFifthInterval, ChordToneRole.perfect5);
        addBase(majorSeventhInterval, ChordToneRole.major7);
        break;

      case ChordQuality.major7sus4:
        addBase(perfectFourthInterval, ChordToneRole.sus4);
        addBase(perfectFifthInterval, ChordToneRole.perfect5);
        addBase(majorSeventhInterval, ChordToneRole.major7);
        break;

      case ChordQuality.major7Flat5:
        addBase(majorThirdInterval, ChordToneRole.major3);
        addBase(diminishedFifthInterval, ChordToneRole.flat5);
        addBase(majorSeventhInterval, ChordToneRole.major7);
        break;

      case ChordQuality.major7Sharp5:
        addBase(majorThirdInterval, ChordToneRole.major3);
        addBase(augmentedFifthInterval, ChordToneRole.sharp5);
        addBase(majorSeventhInterval, ChordToneRole.major7);
        break;

      case ChordQuality.minor7:
        addBase(minorThirdInterval, ChordToneRole.minor3);
        addBase(perfectFifthInterval, ChordToneRole.perfect5);
        addBase(minorSeventhInterval, ChordToneRole.flat7);
        break;

      case ChordQuality.minor7Sharp5:
        addBase(minorThirdInterval, ChordToneRole.minor3);
        addBase(augmentedFifthInterval, ChordToneRole.sharp5);
        addBase(minorSeventhInterval, ChordToneRole.flat7);
        break;

      case ChordQuality.minorMajor7:
        addBase(minorThirdInterval, ChordToneRole.minor3);
        addBase(perfectFifthInterval, ChordToneRole.perfect5);
        addBase(majorSeventhInterval, ChordToneRole.major7);
        break;

      case ChordQuality.halfDiminished7:
        addBase(minorThirdInterval, ChordToneRole.minor3);
        addBase(diminishedFifthInterval, ChordToneRole.flat5);
        addBase(minorSeventhInterval, ChordToneRole.flat7);
        break;

      case ChordQuality.diminished7:
        addBase(minorThirdInterval, ChordToneRole.minor3);
        addBase(diminishedFifthInterval, ChordToneRole.flat5);
        // Fully diminished seventh is "bb7" (interval 9 above root).
        addBase(majorSixthInterval, ChordToneRole.dim7);
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
        case ChordExtension.addFlat9:
          addExt(minorSecondInterval, ChordToneRole.flat9);
          break;
        case ChordExtension.nine:
          addExt(majorSecondInterval, ChordToneRole.nine);
          break;
        case ChordExtension.sharp9:
          addExt(minorThirdInterval, ChordToneRole.sharp9);
          break;
        case ChordExtension.addSharp9:
          addExt(minorThirdInterval, ChordToneRole.splitMinor3);
          break;
        case ChordExtension.eleven:
          addExt(perfectFourthInterval, ChordToneRole.eleven);
          break;
        case ChordExtension.sharp11:
          addExt(sharpEleventhInterval, ChordToneRole.sharp11);
          break;
        case ChordExtension.flat13:
          addExt(minorSixthInterval, ChordToneRole.flat13);
          break;
        case ChordExtension.thirteen:
          addExt(majorSixthInterval, ChordToneRole.thirteen);
          break;

        case ChordExtension.add9:
          addExt(majorSecondInterval, ChordToneRole.add9);
          break;
        case ChordExtension.add11:
          addExt(perfectFourthInterval, ChordToneRole.add11);
          break;
        case ChordExtension.add13:
          addExt(majorSixthInterval, ChordToneRole.add13);
          break;
      }
    }

    return out;
  }
}
