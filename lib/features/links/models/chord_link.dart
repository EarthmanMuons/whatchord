import 'package:meta/meta.dart';

import 'package:whatchord/features/theory/theory.dart';

/// Canonical website link grammar, shared by link building and deep-link
/// parsing so the two can never drift.
///
/// Shape: `https://whatchord.earthmanmuons.com/try?notes=<n>&key=<Root>:<maj|min>`
/// where `notes` is space-separated note names (C, F#, Bb) or MIDI numbers, and
/// the first note is the bass. This matches the /try web page. Notation style is
/// intentionally not carried; the app applies its own.
class ChordLink {
  const ChordLink._();

  static const host = 'whatchord.earthmanmuons.com';
  static const path = '/try';

  /// Mirrors the web page cap; oversized links are ignored rather than parsed.
  static const _maxNotesCharacters = 512;

  static final _separator = RegExp(r'[\s,\-]+');

  /// Builds a shareable link for [orderedNotes] (ascending MIDI numbers, first
  /// entry is the bass) in [tonality]. Returns null when there are no notes.
  static Uri? build({
    required List<int> orderedNotes,
    required Tonality tonality,
  }) {
    if (orderedNotes.isEmpty) return null;
    return Uri.https(host, path, {
      'notes': orderedNotes.join(' '),
      'key': _formatKey(tonality),
    });
  }

  /// Parses an incoming link, or returns null when [uri] is not a recognized
  /// `/try` link or carries no usable notes.
  static ChordLinkSeed? parse(Uri uri) {
    if (!_isTryLink(uri)) return null;

    final rawNotes = uri.queryParameters['notes'];
    if (rawNotes == null || rawNotes.length > _maxNotesCharacters) return null;

    final pitchClasses = _parseNotes(rawNotes);
    if (pitchClasses.isEmpty) return null;

    return ChordLinkSeed(
      pitchClasses: pitchClasses,
      tonality: _parseKey(uri.queryParameters['key']),
    );
  }

  static bool _isTryLink(Uri uri) {
    if (uri.host.toLowerCase() != host) return false;
    return uri.path == path || uri.path == '$path/';
  }

  static String _formatKey(Tonality tonality) =>
      '${tonality.tonic.label}:${tonality.isMajor ? 'maj' : 'min'}';

  /// Parses ordered pitch classes (first is the bass) from a `notes` value,
  /// accepting MIDI numbers and note names and skipping unrecognized tokens.
  static List<int> _parseNotes(String raw) {
    final result = <int>[];
    for (final token in raw.split(_separator)) {
      if (token.isEmpty) continue;
      final pc = _parseToken(token);
      if (pc != null) result.add(pc);
    }
    return result;
  }

  static int? _parseToken(String token) {
    final midi = int.tryParse(token);
    if (midi != null) return midi % 12 + (midi < 0 ? 12 : 0);

    final label =
        token[0].toUpperCase() +
        token
            .substring(1)
            .toLowerCase()
            .replaceAll('♯', '#') // sharp glyph
            .replaceAll('♭', 'b'); // flat glyph
    return Tonic.tryFromLabel(label)?.pitchClass;
  }

  static Tonality? _parseKey(String? key) {
    if (key == null) return null;
    final parts = key.split(':');
    if (parts.length != 2) return null;

    final tonic = Tonic.tryFromLabel(parts[0].trim());
    if (tonic == null) return null;

    final mode = switch (parts[1].toLowerCase()) {
      'maj' => TonalityMode.major,
      'min' => TonalityMode.minor,
      _ => null,
    };
    if (mode == null) return null;

    return Tonality(tonic, mode);
  }
}

/// The app state a [ChordLink] seeds: an ordered lookup selection and, when the
/// link names one, the tonality to apply.
@immutable
class ChordLinkSeed {
  const ChordLinkSeed({required this.pitchClasses, this.tonality});

  /// Entered pitch classes in order; the first entry is the bass.
  final List<int> pitchClasses;

  /// Tonality to apply, or null to leave the current selection unchanged.
  final Tonality? tonality;
}
