import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/theory/theory.dart';

void main() {
  late int productionCapacity;

  setUp(() {
    productionCapacity = ChordAnalyzer.cacheCapacity;
    ChordAnalyzer.cacheCapacity = 16;
    ChordAnalyzer.clearCache();
  });

  tearDown(() {
    ChordAnalyzer.cacheCapacity = productionCapacity;
    ChordAnalyzer.clearCache();
  });

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
  const tonality = Tonality(Tonic.c, TonalityMode.major);
  final keySignature = KeySignature.fromTonality(tonality);
  return AnalysisContext(
    tonality: tonality,
    keySignature: keySignature,
    spellingPolicy: NoteSpellingPolicy(preferFlats: keySignature.prefersFlats),
  );
}

ChordInput _inputFor(int index) {
  // Each index maps to a distinct (pcMask, bassPc) and therefore a distinct
  // cache key, so the eviction assertions exercise capacity directly. pcMask
  // keeps bit 0 set (a valid root) and otherwise encodes the index.
  final pcMask = ((index << 1) | 0x1) & 0xFFF;
  final bassPc = index % 12;
  return ChordInput(pcMask: pcMask, bassPc: bassPc, noteCount: 4);
}
