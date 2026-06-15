import 'dart:convert';
import 'dart:io';

import 'package:whatchord/features/theory/domain/theory_domain.dart';

import 'src/chord_id_engine.dart';

void main() {
  stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
    if (line.trim().isEmpty) return;

    final request = jsonDecode(line) as Map<String, dynamic>;
    final pcMask = request['pcMask'] as int;
    final bassPc = request['bassPc'] as int;
    final noteCount = request['noteCount'] as int;
    final tonality = parseTonality(request['key'] as String);
    final keySignature = KeySignature.fromTonality(tonality);
    final context = AnalysisContext(
      tonality: tonality,
      keySignature: keySignature,
      spellingPolicy: NoteSpellingPolicy(
        preferFlats: keySignature.prefersFlats,
      ),
    );
    final candidates = ChordAnalyzer.analyze(
      ChordInput(pcMask: pcMask, bassPc: bassPc, noteCount: noteCount),
      context: context,
      take: 3,
    );

    stdout.writeln(
      jsonEncode(<String, Object?>{
        'id': request['id'],
        'candidates': [
          for (final candidate in candidates)
            <String, Object?>{
              'rootPc': candidate.identity.rootPc,
              'bassPc': candidate.identity.bassPc,
              'presentIntervalsMask': candidate.identity.presentIntervalsMask,
              'nearTie':
                  candidate != candidates.first &&
                  ChordCandidateRanking.isNearTie(
                    candidates.first.score,
                    candidate.score,
                  ),
            },
        ],
      }),
    );
  });
}
