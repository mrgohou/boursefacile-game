import 'dart:convert';
import 'dart:io';

import 'package:paco_bourse/game/match_engine.dart';

void main() {
  final e = MatchEngine(5);
  final turns = <Map<String, dynamic>>[];
  for (var i = 0; i < 8 && !e.won && !e.lost; i++) {
    final hint = e.hint();
    if (hint == null) break;
    final before = List<int>.of(e.board);
    e.swap(hint[0], hint[1]);
    turns.add({
      'swap': hint,
      'before': before,
      'after': e.board.toList(),
      'score': e.score,
      'moves': e.moves,
      'progress': e.progress,
    });
  }
  final data = {
    'schema': 'paco-match3-replay-1',
    'size': 9,
    'seed': 4701,
    'level': 5,
    'turns': turns,
  };
  File('docs/interop/reference-replay.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
}
