// Fixture, manifest, and split loading for the WhatKey harness.
//
// Label isolation is structural (see research/whatkey/PROTOCOL.md): a loaded
// fixture separates the label-free `ChordEvent` list detectors consume from
// the parallel `EventLabels` list only the scorer reads.

import 'dart:convert';
import 'dart:io';

import 'package:whatchord/whatchord.dart';
import 'package:whatkey/whatkey.dart';

import '../chord_id_engine.dart';

class FixtureSet {
  final Directory directory;
  final Map<String, dynamic> manifest;
  final List<LabeledFixture> fixtures;

  FixtureSet._(this.directory, this.manifest, this.fixtures);

  String get name => manifest['set'] as String;

  Map<String, dynamic> get source =>
      (manifest['source'] as Map).cast<String, dynamic>();

  static FixtureSet load(Directory directory) {
    final manifest =
        jsonDecode(File('${directory.path}/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    final context = parseTonality(manifest['context'] as String);
    final fixtures = <LabeledFixture>[
      for (final entry in (manifest['fixtures'] as List).cast<Map>())
        LabeledFixture._load(
          File('${directory.path}/${entry['file']}'),
          context,
        ),
    ]..sort((a, b) => a.id.compareTo(b.id));
    return FixtureSet._(directory, manifest, fixtures);
  }
}

class LabeledFixture {
  final String id;
  final String title;
  final Map<String, dynamic> fixtureLabels;

  /// Label-free observations, the only thing detectors may see.
  final List<ChordEvent> events;

  /// Scorer-only ground truth, parallel to [events].
  final List<EventLabels> labels;

  LabeledFixture._(
    this.id,
    this.title,
    this.fixtureLabels,
    this.events,
    this.labels,
  );

  static LabeledFixture _load(File file, Tonality context) {
    final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final events = <ChordEvent>[];
    final labels = <EventLabels>[];
    for (final entry in (raw['events'] as List).cast<Map>()) {
      final event = entry.cast<String, dynamic>();
      events.add(_chordEvent(event, context));
      labels.add(EventLabels._parse(event['labels'] as Map?));
    }
    return LabeledFixture._(
      raw['id'] as String,
      raw['title'] as String? ?? raw['id'] as String,
      (raw['labels'] as Map? ?? const {}).cast<String, dynamic>(),
      events,
      labels,
    );
  }

  static ChordEvent _chordEvent(Map<String, dynamic> event, Tonality context) {
    final midiNotes = (event['midiNotes'] as List).cast<int>();
    return ChordEvent(
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        event['timestampMs'] as int,
      ),
      input: ChordInput(
        pcMask: event['pcMask'] as int,
        bassPc: event['bassPc'] as int,
        noteCount: event['noteCount'] as int,
      ),
      voicing: ObservedVoicing.fromMidi(midiNotes),
      candidates: [
        for (final candidate in (event['candidates'] as List).cast<Map>())
          _chordCandidate(candidate.cast<String, dynamic>()),
      ],
      tonality: context,
      duration: Duration(milliseconds: event['durationMs'] as int),
    );
  }

  /// Rebuilds a candidate from fixture fields. Tone roles are not serialized,
  /// so identities here carry an empty role map; detectors must not rely on
  /// them.
  static ChordCandidate _chordCandidate(Map<String, dynamic> candidate) {
    return ChordCandidate(
      identity: ChordIdentity(
        rootPc: candidate['rootPc'] as int,
        bassPc: candidate['bassPc'] as int,
        quality: ChordQualityToken.values.byName(
          candidate['quality'] as String,
        ),
        extensions: {
          for (final name in (candidate['extensions'] as List).cast<String>())
            ChordExtension.values.byName(name),
        },
        presentIntervalsMask: candidate['presentIntervalsMask'] as int,
      ),
      cost: (candidate['cost'] as num).toDouble(),
    );
  }
}

/// Ground truth for one event: the annotated local key (null on deliberately
/// ambiguous passages), acceptable keys for those passages, and the annotated
/// figure.
class EventLabels {
  final KeyLabel? localKey;
  final List<KeyLabel> acceptableKeys;
  final String? figure;

  EventLabels._(this.localKey, this.acceptableKeys, this.figure);

  static EventLabels _parse(Map? raw) {
    final labels = (raw ?? const {}).cast<String, dynamic>();
    final localKey = labels['localKey'] as String?;
    return EventLabels._(localKey == null ? null : KeyLabel.parse(localKey), [
      for (final key in (labels['acceptableKeys'] as List? ?? const []))
        KeyLabel.parse(key as String),
    ], labels['figure'] as String?);
  }
}

/// A key reduced to what scoring compares: tonic pitch class and mode.
class KeyLabel {
  final int tonicPc;
  final bool isMinor;

  const KeyLabel(this.tonicPc, {required this.isMinor});

  static KeyLabel parse(String wire) {
    final tonality = parseTonality(wire);
    return KeyLabel(tonality.tonicPitchClass, isMinor: tonality.isMinor);
  }

  static KeyLabel of(Tonality tonality) =>
      KeyLabel(tonality.tonicPitchClass, isMinor: tonality.isMinor);

  bool matches(KeyLabel other) =>
      tonicPc == other.tonicPc && isMinor == other.isMinor;

  @override
  String toString() {
    const names = [
      'C', 'C#', 'D', 'Eb', 'E', 'F', //
      'F#', 'G', 'Ab', 'A', 'Bb', 'B',
    ];
    return '${names[tonicPc]}:${isMinor ? 'min' : 'maj'}';
  }
}

/// Externally produced key claims (see tool/whatkey_external_baseline.py):
/// one global key per fixture, scored as a constant claim on every event so
/// offline, non-abstaining baselines run through the same metrics as our
/// detectors.
class ClaimsFile {
  final Map<String, dynamic> detector;
  final Map<String, String> _globalByFixtureId;

  ClaimsFile._(this.detector, this._globalByFixtureId);

  static ClaimsFile load(File file) {
    final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return ClaimsFile._((raw['detector'] as Map).cast<String, dynamic>(), {
      for (final entry in (raw['claims'] as Map).entries)
        entry.key as String: (entry.value as Map)['global'] as String,
    });
  }

  List<KeyEstimateFrame> framesFor(LabeledFixture fixture) {
    final wire = _globalByFixtureId[fixture.id];
    if (wire == null) {
      throw StateError('Claims file has no claim for ${fixture.id}');
    }
    final estimate = KeyEstimate(tonality: parseTonality(wire), confidence: 1);
    final frame = KeyEstimateFrame(ranked: [estimate], claim: estimate);
    return List.filled(fixture.events.length, frame);
  }
}

/// Which events a previous run claimed on, loaded from the per-event
/// `claims.json` artifact the harness writes next to every report. Used for
/// matched-coverage comparisons: scoring one detector restricted to exactly
/// the events another one claimed on.
class ClaimMask {
  final Map<String, List<bool>> _byFixtureId;

  ClaimMask._(this._byFixtureId);

  static ClaimMask load(File file) {
    final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return ClaimMask._({
      for (final entry in (raw['claims'] as Map).entries)
        entry.key as String: [
          for (final wire in (entry.value as Map)['events'] as List)
            wire != null,
        ],
    });
  }

  List<bool> maskFor(LabeledFixture fixture) {
    final mask = _byFixtureId[fixture.id];
    if (mask == null) {
      throw StateError('Claim mask has no entry for ${fixture.id}');
    }
    if (mask.length != fixture.events.length) {
      throw StateError(
        'Claim mask length ${mask.length} does not match '
        '${fixture.events.length} events for ${fixture.id}',
      );
    }
    return mask;
  }
}

class SplitFile {
  final Map<String, dynamic> raw;

  SplitFile._(this.raw);

  static SplitFile load(File file) =>
      SplitFile._(jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);

  List<String> pieceTitles(String split) => [
    for (final piece in ((raw['splits'] as Map)[split] as List).cast<Map>())
      piece['id'] as String,
  ];

  /// Enforces the protocol's harness discipline: split pins must match the
  /// fixture manifest, and the fixture set must contain exactly the split's
  /// pieces. Throws with a full diff on any mismatch.
  void validateAgainst(FixtureSet fixtureSet) {
    final source = (raw['source'] as Map).cast<String, dynamic>();
    // Every commit pin the split records must match the fixture manifest.
    for (final entry in source.entries) {
      if (!entry.key.endsWith('Commit')) continue;
      final manifestPin = fixtureSet.source[entry.key];
      if (entry.value != manifestPin) {
        throw StateError(
          'Split/fixture version skew on ${entry.key}: '
          'split=${entry.value} fixtures=$manifestPin',
        );
      }
    }

    final splitTitles = {...pieceTitles('development'), ...pieceTitles('test')};
    final fixtureTitles = {
      for (final fixture in fixtureSet.fixtures) fixture.title,
    };
    final missing = splitTitles.difference(fixtureTitles);
    final extra = fixtureTitles.difference(splitTitles);
    if (missing.isNotEmpty || extra.isNotEmpty) {
      throw StateError(
        'Fixture set does not match split. '
        'Missing from fixtures: ${missing.toList()..sort()}. '
        'Not in split: ${extra.toList()..sort()}.',
      );
    }
  }
}
