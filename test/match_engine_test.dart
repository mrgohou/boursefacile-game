import 'package:flutter_test/flutter_test.dart';
import 'package:paco_bourse/game/match_engine.dart';

void main() {
  test('boards are deterministic, stable, and playable', () {
    for (var seed = 0; seed < 100; seed++) {
      final engine = MatchEngine(seed % 6, seed: seed);
      expect(engine.board, MatchEngine(seed % 6, seed: seed).board);
      expect(engine.board.length, 49);
      expect(MatchEngine.findMatches(engine.board), isEmpty);
      expect(engine.hint(), isNotNull);
    }
  });
  test('invalid swaps preserve every state value', () {
    final e = MatchEngine(0);
    final before = [...e.board];
    expect(e.swap(6, 7), isFalse);
    expect(e.swap(-1, 0), isFalse);
    expect(e.board, before);
    expect(e.moves, 24);
    expect(e.score, 0);
    for (var i = 0; i < 48; i++) {
      if (!MatchEngine.adjacent(i, i + 1)) continue;
      final probe = [...before];
      final t = probe[i];
      probe[i] = probe[i + 1];
      probe[i + 1] = t;
      if (MatchEngine.findMatches(probe).isEmpty) {
        expect(e.swap(i, i + 1), isFalse);
        expect(e.board, before);
        expect(e.moves, 24);
        break;
      }
    }
  });
  test(
    'valid moves resolve cascades, spend one move and remain deterministic',
    () {
      final a = MatchEngine(5), b = MatchEngine(5);
      while (!a.won && !a.lost) {
        final move = a.hint()!;
        final moves = a.moves, score = a.score;
        expect(a.swap(move[0], move[1]), isTrue);
        expect(b.swap(move[0], move[1]), isTrue);
        expect(a.moves, moves - 1);
        expect(a.score, greaterThan(score));
        expect(MatchEngine.findMatches(a.board), isEmpty);
        expect(a.board, b.board);
        expect(a.score, b.score);
        if (!a.won && !a.lost) expect(a.hint(), isNotNull);
      }
      final score = a.score, moves = a.moves;
      expect(a.swap(0, 1), isFalse);
      expect(a.score, score);
      expect(a.moves, moves);
      expect(a.hint(), isNull);
    },
  );
  test('cross matches count shared cell once', () {
    final board = List.generate(49, (i) => i);
    for (final i in [23, 24, 25, 17, 31]) {
      board[i] = 100;
    }
    expect(MatchEngine.findMatches(board), {23, 24, 25, 17, 31});
  });
}
