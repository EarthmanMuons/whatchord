import 'dart:convert';
import 'dart:io';

import 'package:whatchord/whatchord.dart';

import '../src/chord_id_engine.dart';

void main() {
  stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
    if (line.trim().isEmpty) return;

    final request = jsonDecode(line) as Map<String, dynamic>;
    final pcMask = request['pcMask'] as int;
    final bassPc = request['bassPc'] as int;
    final noteCount = request['noteCount'] as int;
    final expectedRootPc = request['expectedRootPc'] as int;
    final tonality = parseTonality(request['key'] as String);
    final keySignature = KeySignature.fromTonality(tonality);
    final context = AnalysisContext(
      tonality: tonality,
      keySignature: keySignature,
      spellingPolicy: NoteSpellingPolicy(
        preferFlats: keySignature.prefersFlats,
      ),
    );
    final allCandidates = ChordAnalyzer.analyze(
      ChordInput(pcMask: pcMask, bassPc: bassPc, noteCount: noteCount),
      context: context,
      take: 10000,
    );
    final candidates = allCandidates.take(3).toList(growable: false);
    final expectedRootIndex = allCandidates.indexWhere(
      (candidate) => candidate.identity.rootPc == expectedRootPc,
    );
    final alternativeCount = ChordCandidateRanking.alternativeCount(
      allCandidates,
    );

    stdout.writeln(
      jsonEncode(<String, Object?>{
        'id': request['id'],
        'expectedRootGenerated': expectedRootIndex >= 0,
        'expectedRootRank': expectedRootIndex < 0
            ? null
            : expectedRootIndex + 1,
        'expectedRootAlternative':
            expectedRootIndex > 0 && expectedRootIndex <= alternativeCount,
        'candidates': [
          for (var i = 0; i < candidates.length; i++)
            <String, Object?>{
              'rootPc': candidates[i].identity.rootPc,
              'bassPc': candidates[i].identity.bassPc,
              'quality': candidates[i].identity.quality.name,
              'cost': candidates[i].cost,
              'presentIntervalsMask':
                  candidates[i].identity.presentIntervalsMask,
              'alternative': i > 0 && i <= alternativeCount,
            },
        ],
      }),
    );
  });
}
