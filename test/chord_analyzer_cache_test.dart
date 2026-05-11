import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/theory/theory.dart';

void main() {
  setUp(ChordAnalyzer.clearCache);
  tearDown(ChordAnalyzer.clearCache);

  test('analyzer cache is bounded to its configured capacity', () {
    final context = _context();

    for (var i = 0; i < ChordAnalyzer.cacheCapacity + 32; i++) {
      ChordAnalyzer.analyze(_inputFor(i), context: context);
    }

    expect(ChordAnalyzer.cacheSize, ChordAnalyzer.cacheCapacity);
  });

  test('cache hits promote entries before eviction', () {
    final context = _context();
    final first = _inputFor(0);

    final firstResult = ChordAnalyzer.analyze(first, context: context);

    for (var i = 1; i < ChordAnalyzer.cacheCapacity; i++) {
      ChordAnalyzer.analyze(_inputFor(i), context: context);
    }

    expect(ChordAnalyzer.cacheSize, ChordAnalyzer.cacheCapacity);
    expect(ChordAnalyzer.analyze(first, context: context), same(firstResult));

    ChordAnalyzer.analyze(
      _inputFor(ChordAnalyzer.cacheCapacity),
      context: context,
    );

    expect(ChordAnalyzer.cacheSize, ChordAnalyzer.cacheCapacity);
    expect(ChordAnalyzer.analyze(first, context: context), same(firstResult));
  });
}

AnalysisContext _context() {
  const tonality = Tonality('C', TonalityMode.major);
  final keySignature = KeySignature.fromTonality(tonality);
  return AnalysisContext(
    tonality: tonality,
    keySignature: keySignature,
    spellingPolicy: NoteSpellingPolicy(preferFlats: keySignature.prefersFlats),
  );
}

ChordInput _inputFor(int index) {
  final templates = [
    [0, 4, 7],
    [0, 3, 7],
    [0, 4, 7, 10],
    [0, 3, 7, 10],
    [0, 4, 7, 11],
    [0, 3, 6, 10],
    [0, 3, 6, 9],
    [0, 5, 7],
  ];
  final transposition = index % 12;
  final template = templates[(index ~/ 12) % templates.length];
  final noteCount = 3 + ((index ~/ (12 * templates.length)) % 8);
  final pcs = template.map((pc) => (pc + transposition) % 12).toList();
  final bassPc = pcs[(index ~/ (12 * templates.length * 8)) % pcs.length];

  var pcMask = 0;
  for (final pc in pcs) {
    pcMask |= 1 << pc;
  }

  return ChordInput(pcMask: pcMask, bassPc: bassPc, noteCount: noteCount);
}
