import 'package:flutter_test/flutter_test.dart';
import 'package:paco_bourse/domain/challenge_catalog.dart';
import 'package:paco_bourse/game/match_engine.dart';

ChallengeSpec spec({
  int score = 20000,
  int locks = 0,
  int perfect = 0,
  int collectType = -1,
  int collect = 0,
  int specials = 0,
}) => ChallengeSpec(
  score: score,
  moves: 40,
  seconds: 180,
  locks: locks,
  perfectMoves: perfect,
  collectType: collectType,
  collectCount: collect,
  specialUses: specials,
  themeIndex: 0,
);
List<int> stable() => List.generate(81, (i) => (i % 9 + (i ~/ 9) * 2) % 6);
void fourFixture(MatchEngine e) {
  e.board = stable();
  e.lockedCells.clear();
  e.specials.clear();
  e.board[0] = 0;
  e.board[1] = 0;
  e.board[2] = 1;
  e.board[3] = 0;
  e.board[11] = 0;
}

void main() {
  test('9x9 campaign and generated rounds start stable with legal moves', () {
    for (final level in [0, 1, 2, 3, 4, 5, 6, 29, 30, 100]) {
      final e = MatchEngine(level);
      expect(e.board.length, 81);
      expect(MatchEngine.findMatches(e.board), isEmpty);
      expect(e.hint(), isNotNull);
      expect(e.challenge.themeIndex, level);
      expect(e.lockedCells.length, e.challenge.locks);
    }
    expect(MatchEngine.adjacent(8, 9), false);
    expect(MatchEngine.adjacent(71, 80), true);
  });
  test(
    'locked pieces reject exchange and adjacent match unlocks real lock',
    () {
      final e = MatchEngine(0, specification: spec(locks: 1));
      fourFixture(e);
      e.lockedCells.add(3);
      final before = [...e.board];
      expect(e.swap(3, 12), false);
      expect(e.board, before);
      expect(e.moves, 40);
      expect(e.swap(2, 11), true);
      expect(e.locksRemaining, 0);
      expect(e.perfectMoves, 1);
      expect(e.specials, isNotEmpty);
    },
  );
  test(
    'perfect move is counted once for direct four and does not mean a triple',
    () {
      final e = MatchEngine(0, specification: spec(perfect: 7));
      fourFixture(e);
      expect(MatchEngine.findMatches(e.board), isEmpty);
      expect(e.swap(2, 11), true);
      expect(e.perfectMoves, 1);
      expect(e.won, false);
      final f = MatchEngine(0, specification: spec());
      f.board = stable();
      f.specials.clear();
      f.board[0] = 0;
      f.board[1] = 0;
      f.board[2] = 1;
      f.board[11] = 0;
      f.swap(2, 11);
      expect(f.perfectMoves, 0);
    },
  );
  test('each named special activates via a neighboring exchange without ordinary match', () {
    for (final kind in SpecialPiece.values) {
      final e = MatchEngine(0, specification: spec(specials: 1));
      e.board = stable();
      e.lockedCells.clear();
      e.specials
        ..clear()
        ..[0] = kind;
      expect(e.swap(0, 1), true);
      expect(e.specialUses, 1);
      expect(e.score, greaterThan(0));
      expect(e.lastTurn.any((f) => f.phase == TurnPhase.clear), true);
    }
  });
  test(
    'collections are actual removed sector tiles and snapshots match gravity',
    () {
      final e = MatchEngine(
        0,
        specification: spec(collectType: 0, collect: 30),
      );
      fourFixture(e);
      e.swap(2, 11);
      var total = 0;
      for (final frame in e.lastTurn) {
        if (frame.phase == TurnPhase.clear) {
          total += frame.cleared.where((i) => frame.before[i] == 0).length;
        }
        if (frame.phase == TurnPhase.fall) {
          expect(frame.motions.length, 81);
          expect(frame.motions.map((m) => m.to).toSet().length, 81);
          for (final m in frame.motions) {
            expect(frame.after[m.to], m.type);
          }
        }
      }
      expect(e.collected, total);
      expect(e.won, false);
      expect(MatchEngine.findMatches(e.board), isEmpty);
    },
  );
  test('score alone does not win an unfinished objective and repeated winning input has no effect', () {
    final e = MatchEngine(0, specification: spec(score: 100, perfect: 7));
    fourFixture(e);
    e.swap(2, 11);
    expect(e.score, greaterThan(100));
    expect(e.won, false);
    final f = MatchEngine(0, specification: spec(score: 100));
    fourFixture(f);
    f.swap(2, 11);
    expect(f.won, true);
    final score = f.score, moves = f.moves;
    expect(f.swap(4, 5), false);
    expect(f.score, score);
    expect(f.moves, moves);
  });
}
