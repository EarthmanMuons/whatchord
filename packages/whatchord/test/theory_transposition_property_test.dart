import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:kiri_check/kiri_check.dart';

import 'package:whatchord/src/analysis/chord_templates.dart';
import 'package:whatchord/whatchord.dart';

import 'package:whatchord/testing.dart';

const _supportedExtensionIntervals = <int>[1, 2, 3, 5, 6, 8, 9];
const _analysisTake = 256;

final List<Tonality> _supportedTonalities = <Tonality>[
  for (final keySignature in keySignatures) keySignature.relativeMajor,
  for (final keySignature in keySignatures) keySignature.relativeMinor,
];

class _GeneratedChordCase {
  final Tonality tonality;
  final ChordInput input;
  final int transposeBy;

  const _GeneratedChordCase({
    required this.tonality,
    required this.input,
    required this.transposeBy,
  });
}

void main() {
  property(
    'ChordAnalyzer is transposition-invariant for structured inputs',
    () {
      forAll<_GeneratedChordCase>(
        _generatedChordCaseArbitrary(),
        maxExamples: 200,
        (testCase) {
          final originalContext = makeAnalysisContext(
            tonality: testCase.tonality,
          );
          final originalResults = ChordAnalyzer.analyze(
            testCase.input,
            context: originalContext,
            take: _analysisTake,
          );

          expect(originalResults, isNotEmpty);

          final transposedInput = _transposeInput(
            testCase.input,
            testCase.transposeBy,
          );
          final transposedTonality = _transposeTonality(
            testCase.tonality,
            testCase.transposeBy,
          );
          final transposedContext = makeAnalysisContext(
            tonality: transposedTonality,
          );
          final transposedResults = ChordAnalyzer.analyze(
            transposedInput,
            context: transposedContext,
            take: _analysisTake,
          );

          expect(transposedResults, isNotEmpty);

          final originalNormalized = originalResults
              .map((candidate) => _normalizedCandidateSignature(candidate, 0))
              .toSet();
          final transposedNormalized = transposedResults
              .map(
                (candidate) => _normalizedCandidateSignature(
                  candidate,
                  testCase.transposeBy,
                ),
              )
              .toSet();

          expect(transposedNormalized, originalNormalized);

          if (_hasClearTopWinner(originalResults) &&
              _hasClearTopWinner(transposedResults)) {
            expect(
              _normalizedCandidateSignature(originalResults.first, 0),
              _normalizedCandidateSignature(
                transposedResults.first,
                testCase.transposeBy,
              ),
            );
          }
        },
      );
    },
  );
}

Arbitrary<_GeneratedChordCase> _generatedChordCaseArbitrary() {
  return combine4(
    integer(min: 0, max: 11),
    constantFrom(chordTemplates),
    constantFrom(_supportedTonalities),
    integer(min: 1, max: 11),
  ).flatMap((value) {
    final rootPc = value.$1;
    final template = value.$2;
    final tonality = value.$3;
    final transposeBy = value.$4;

    final candidateExtraIntervals = _supportedExtensionIntervals
        .where((interval) {
          final bit = 1 << interval;
          final usedByTemplate =
              ((template.requiredMask |
                      template.optionalMask |
                      template.penaltyMask) &
                  bit) !=
              0;
          return !usedByTemplate;
        })
        .toList(growable: false);

    final extrasArbitrary = candidateExtraIntervals.isEmpty
        ? constant(<int>{})
        : set<int>(
            constantFrom(candidateExtraIntervals),
            maxLength: math.min(3, candidateExtraIntervals.length),
          );

    return combine2(boolean(), extrasArbitrary).flatMap((selection) {
      final includeOptional = selection.$1;
      final extras = selection.$2;

      final relMask =
          0x1 |
          template.requiredMask |
          (includeOptional ? template.optionalMask : 0) |
          _maskFromIntervals(extras);
      final presentIntervals = _intervalsFromMask(relMask);

      return constantFrom(presentIntervals).map((bassInterval) {
        return _GeneratedChordCase(
          tonality: tonality,
          input: ChordInput(
            pcMask: _transposeMask(relMask, rootPc),
            bassPc: _transposePc(rootPc, bassInterval),
            noteCount: _popCount(relMask),
          ),
          transposeBy: transposeBy,
        );
      });
    });
  });
}

ChordInput _transposeInput(ChordInput input, int semitones) {
  return ChordInput(
    pcMask: _transposeMask(input.pcMask, semitones),
    bassPc: _transposePc(input.bassPc, semitones),
    noteCount: input.noteCount,
  );
}

Tonality _transposeTonality(Tonality tonality, int semitones) {
  final tonicPc = _transposePc(tonality.tonicPitchClass, semitones);
  return _supportedTonalities.firstWhere(
    (candidate) =>
        candidate.mode == tonality.mode && candidate.tonicPitchClass == tonicPc,
  );
}

String _normalizedCandidateSignature(
  ChordCandidate candidate,
  int untransposeBy,
) {
  final identity = candidate.identity;
  final normalizedRoot = _transposePc(identity.rootPc, -untransposeBy);
  final normalizedBass = _transposePc(identity.bassPc, -untransposeBy);
  final normalizedExtensions = identity.extensions.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final normalizedRoles = identity.toneRolesByInterval.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  return [
    'root=$normalizedRoot',
    'bass=$normalizedBass',
    'quality=${identity.quality.name}',
    'mask=${identity.presentIntervalsMask}',
    'ext=${normalizedExtensions.map((extension) => extension.name).join(",")}',
    'roles=${normalizedRoles.map((entry) => '${entry.key}:${entry.value.name}').join(",")}',
    'cost=${candidate.cost.toStringAsFixed(6)}',
  ].join('|');
}

bool _hasClearTopWinner(List<ChordCandidate> results) {
  if (results.length < 2) return true;
  final gap = results[1].cost - results.first.cost;
  return gap > ChordCandidateRanking.nearTieWindow;
}

int _maskFromIntervals(Iterable<int> intervals) {
  var mask = 0;
  for (final interval in intervals) {
    mask |= 1 << (interval % 12);
  }
  return mask;
}

List<int> _intervalsFromMask(int mask) {
  final intervals = <int>[];
  for (var interval = 0; interval < 12; interval++) {
    if ((mask & (1 << interval)) != 0) {
      intervals.add(interval);
    }
  }
  return intervals;
}

int _transposeMask(int mask, int semitones) {
  var out = 0;
  for (var pc = 0; pc < 12; pc++) {
    if ((mask & (1 << pc)) == 0) continue;
    out |= 1 << _transposePc(pc, semitones);
  }
  return out;
}

int _transposePc(int pc, int semitones) {
  final value = (pc + semitones) % 12;
  return value < 0 ? value + 12 : value;
}

int _popCount(int value) {
  var count = 0;
  var current = value;
  while (current != 0) {
    current &= current - 1;
    count++;
  }
  return count;
}
