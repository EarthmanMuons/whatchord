import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const canonicalization = 'whatkey-canonical-json-v1';

/// The scored report fields locked for reproduction. Kept identical to
/// Python `REPORT_DATA_KEYS` and the lock's `resultDataFields`; the
/// reproduction-lock test asserts this list matches the lock so the three
/// cannot drift.
const resultDataFields = <String>[
  'schema',
  'fixtures',
  'split',
  'detector',
  'restrictedTo',
  'summary',
  'perPiece',
];

String canonicalJsonSha256(Object? value) =>
    sha256.convert(utf8.encode(jsonEncode(_canonicalize(value)))).toString();

String fixtureSetSha256(Directory directory, Map<String, dynamic> manifest) {
  // Duplicate keys collapse, matching Python's per-file dict: a basename
  // collision hashes to the same aggregate on both sides.
  final contents = <String, Object?>{
    for (final entry in (manifest['fixtures'] as List).cast<Map>())
      entry['file'] as String: jsonDecode(
        File('${directory.path}/${entry['file'] as String}').readAsStringSync(),
      ),
  };
  return fixtureSetSha256FromContents(contents);
}

/// Aggregate hash over already-parsed fixture files, keyed by file name, so
/// callers that have decoded the corpus once need not re-read it from disk.
String fixtureSetSha256FromContents(Map<String, Object?> contentsByFile) {
  final names = contentsByFile.keys.toList()..sort();
  final payload = <Map<String, String>>[
    for (final name in names)
      {'file': name, 'sha256': canonicalJsonSha256(contentsByFile[name])},
  ];
  return canonicalJsonSha256(payload);
}

Map<String, String> resultArtifactHashes(
  Map<String, Object?> report,
  Map<String, Object?> claims,
) {
  // Hash the scored paper data, not additive diagnostics or run metadata.
  final reportData = <String, Object?>{
    for (final key in resultDataFields) key: report[key],
  };
  final fixtures = (reportData['fixtures'] as Map?)?.cast<String, Object?>();
  if (fixtures != null) {
    reportData['fixtures'] = {'set': fixtures['set']};
  }
  if (reportData['restrictedTo'] != null) {
    reportData['restrictedTo'] = true;
  }
  return {
    'claimsSha256': canonicalJsonSha256(claims),
    'resultDataSha256': canonicalJsonSha256(reportData),
  };
}

Object? _canonicalize(Object? value) {
  if (value is Map) {
    return SplayTreeMap<String, Object?>.from({
      for (final entry in value.entries)
        entry.key as String: _canonicalize(entry.value),
    });
  }
  if (value is List) return [for (final item in value) _canonicalize(item)];
  if (value is double) _assertCanonicalDouble(value);
  return value;
}

// Dart and Python emit identical plain-decimal text only for finite
// non-integer magnitudes in [1e-4, 1e16); outside that band one side switches
// to exponent notation (e.g. 1e-05 vs 0.00001) and the shared SHA-256 diverges.
// Reject such values loudly at hash time rather than let a set hash
// differently across the two implementations. All current fixtures and results
// stay well inside the band.
const _canonicalDoubleMin = 1e-4;
const _canonicalDoubleMax = 1e16;

void _assertCanonicalDouble(double value) {
  if (!value.isFinite) {
    throw StateError('Non-finite number is not canonically hashable: $value');
  }
  final magnitude = value.abs();
  if (magnitude != 0 &&
      (magnitude < _canonicalDoubleMin || magnitude >= _canonicalDoubleMax)) {
    throw StateError(
      'Number $value is outside the canonical-JSON range '
      '[$_canonicalDoubleMin, $_canonicalDoubleMax); Dart and Python would '
      'format it differently and hash to different digests.',
    );
  }
}
