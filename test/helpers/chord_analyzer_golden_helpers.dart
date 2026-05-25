import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/theory/theory.dart';

import 'theory_test_helpers.dart';

class GoldenCase {
  final String description;

  /// Pitch names like ["C", "E", "G", "Bb", "D"] (order is irrelevant for the mask).
  final List<String> pcs;

  /// Optional bass pitch name; defaults to first element of [pcs].
  final String? bass;

  /// Optional override; defaults to pcs.length.
  ///
  /// Use this to simulate octave duplications.
  final int? noteCount;

  /// Optional per-case tonality override (defaults to C major).
  final Tonality? tonality;

  /// Expected rendered symbol.
  final String expectedSymbol;

  /// Expected winning root pitch name.
  final String? expectedRoot;

  /// Expected winning bass pitch name. Defaults to [bass] when omitted.
  final String? expectedBass;

  /// Expected winning quality.
  final ChordQualityToken? expectedQuality;

  /// Extensions that must appear on the winning identity.
  final Set<ChordExtension> expectedExtensions;

  /// Whether the winning identity must have no extensions.
  final bool expectNoExtensions;

  /// Extensions that must not appear on the winning identity.
  final Set<ChordExtension> unexpectedExtensions;

  /// Tone roles that must appear at specific intervals on the winning identity.
  final Map<int, ChordToneRole> expectedToneRolesByInterval;

  const GoldenCase({
    required this.description,
    required this.expectedSymbol,
    required this.pcs,
    this.bass,
    this.noteCount,
    this.tonality,
    this.expectedRoot,
    this.expectedBass,
    this.expectedQuality,
    this.expectedExtensions = const {},
    this.expectNoExtensions = false,
    this.unexpectedExtensions = const {},
    this.expectedToneRolesByInterval = const {},
  });
}

/// Small helper so each case keeps purpose separate from notes and assertions.
GoldenCase golden({
  required String description,
  required String expectedSymbol,
  required List<String> pcs,
  String? bass,
  int? noteCount,
  Tonality? tonality,
  String? expectedRoot,
  String? expectedBass,
  ChordQualityToken? expectedQuality,
  Set<ChordExtension> expectedExtensions = const {},
  bool expectNoExtensions = false,
  Set<ChordExtension> unexpectedExtensions = const {},
  Map<int, ChordToneRole> expectedToneRolesByInterval = const {},
}) {
  return GoldenCase(
    description: description,
    expectedSymbol: expectedSymbol,
    pcs: pcs,
    bass: bass,
    noteCount: noteCount,
    tonality: tonality,
    expectedRoot: expectedRoot,
    expectedBass: expectedBass,
    expectedQuality: expectedQuality,
    expectedExtensions: expectedExtensions,
    expectNoExtensions: expectNoExtensions,
    unexpectedExtensions: unexpectedExtensions,
    expectedToneRolesByInterval: expectedToneRolesByInterval,
  );
}

void runChordAnalyzerGoldenCases(Iterable<GoldenCase> cases) {
  // Keep notation pinned for golden stability.
  const testNotation = ChordNotationStyle.textual;

  for (final c in cases) {
    test(_testName(c), () {
      final input = chordInputFromNames(
        names: c.pcs,
        bass: c.bass,
        noteCount: c.noteCount,
      );

      final count = input.noteCount;
      final tonality = c.tonality ?? defaultTestTonality;
      final ctx = makeAnalysisContext(tonality: tonality);
      final results = ChordAnalyzer.analyze(input, context: ctx);

      expect(results, isNotEmpty, reason: 'No candidates returned');
      final top = results.first.identity;

      final actualSymbol = ChordSymbolBuilder.fromIdentity(
        identity: top,
        tonality: tonality,
        notation: testNotation,
      ).toString();

      expect(
        actualSymbol,
        c.expectedSymbol,
        reason: 'Rendered symbol mismatch',
      );

      try {
        expectTopIdentity(top, c);
      } on TestFailure catch (e) {
        fail(
          [
            'Expected chord: ${c.expectedSymbol}',
            '  Actual chord: $actualSymbol',
            '      Tonality: ${tonality.tonic} ${tonality.mode.name}',
            '         Notes: ${c.pcs.join(" ")}',
            '          Bass: ${c.bass ?? c.pcs.first}',
            '     NoteCount: $count',
            '',
            'Original failure:',
            e.message ?? e.toString(),
          ].join('\n'),
        );
      }
    });
  }
}

String _testName(GoldenCase c) {
  final parts = <String>[
    c.description,
    '${c.pcs.join(" ")} -> ${c.expectedSymbol}',
  ];
  final bass = c.bass;
  if (bass != null) {
    parts.add('bass $bass');
  }
  final tonality = c.tonality;
  if (tonality != null) {
    parts.add('key ${tonality.displayName}');
  }
  if (c.noteCount != null) {
    parts.add('note count ${c.noteCount}');
  }

  return parts.join(' | ');
}

void expectTopIdentity(ChordIdentity top, GoldenCase c) {
  if (c.expectedRoot != null) {
    expect(top.rootPc, pc(c.expectedRoot!));
  }
  final expectedBass = c.expectedBass ?? c.bass;
  if (expectedBass != null) {
    expect(top.bassPc, pc(expectedBass));
  }
  if (c.expectedQuality != null) {
    expect(top.quality, c.expectedQuality);
  }
  if (c.expectNoExtensions) {
    expect(top.extensions, isEmpty);
  }
  for (final extension in c.expectedExtensions) {
    expect(top.extensions, contains(extension));
  }
  for (final extension in c.unexpectedExtensions) {
    expect(top.extensions, isNot(contains(extension)));
  }
  for (final entry in c.expectedToneRolesByInterval.entries) {
    expect(top.toneRolesByInterval[entry.key], entry.value);
  }
}
