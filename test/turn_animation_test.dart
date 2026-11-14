import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flame/game.dart';

import 'package:paco_bourse/game/paco_game.dart';

import 'package:paco_bourse/game/match_engine.dart';

void main() {
  testWidgets(
    'swipe starts one animated turn, locks input and emits completion once',
    (tester) async {
      var wins = 0, losses = 0;
      final audio = <String>[];
      final game = PacoGame(
        level: 0,
        onUpdate: (_, _, _) {},
        onWin: () => wins++,
        onLose: () => losses++,
        onAudio: (event, chain) => audio.add(event),
      );
      await tester.runAsync(() async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: 350,
                height: 350,
                child: GameWidget(game: game),
              ),
            ),
          ),
        );
        await game.loaded;
      });
      await tester.pump();
      game.engine.score = game.engine.target - 90;
      final pair = game.engine.hint()!;
      final rect = tester.getRect(find.byType(GameWidget<PacoGame>));
      Offset center(int i) =>
          Offset(rect.left + (i % 7 + .5) * 50, rect.top + (i ~/ 7 + .5) * 50);
      await tester.timedDragFrom(
        center(pair[0]),
        center(pair[1]) - center(pair[0]),
        const Duration(milliseconds: 80),
      );
      expect(game.engine.moves, 23);
      expect(game.isAnimating, isTrue);
      expect(wins, 0);
      final moves = game.engine.moves;
      game.selectTile(0);
      game.selectTile(1);
      expect(game.engine.moves, moves);
      for (var i = 0; i < 180 && game.isAnimating; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(game.isAnimating, isFalse);
      expect(game.visibleBoard, game.engine.board);
      expect(wins, 1);
      expect(losses, 0);
      expect(audio, containsAllInOrder(['swap', 'match', 'win']));
      await tester.pump(const Duration(seconds: 1));
      expect(wins, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  test('timeline snapshots are immutable and join each successive phase', () {
    final e = MatchEngine(0);
    final initial = [...e.board];
    final move = e.hint()!;
    expect(e.swap(move[0], move[1]), isTrue);
    final steps = e.lastTurn;
    expect(steps.first.phase, TurnPhase.swap);
    expect(steps.first.before, initial);
    expect(steps.last.after, e.board);
    for (var i = 1; i < steps.length; i++) {
      expect(steps[i].before, steps[i - 1].after);
    }
    expect(() => steps.first.before[0] = 9, throwsUnsupportedError);
    expect(() => steps.clear(), throwsUnsupportedError);
    expect(steps.where((s) => s.phase == TurnPhase.clear), isNotEmpty);
  });
  test('gravity maps every destination once, retaining surviving pieces and column order', () {
    for (var seed = 0; seed < 30; seed++) {
      final e = MatchEngine(5, seed: seed);
      final move = e.hint()!;
      e.swap(move[0], move[1]);
      for (final step in e.lastTurn.where((s) => s.phase == TurnPhase.fall)) {
        expect(step.motions.map((m) => m.to).toSet().length, 49);
        final sources = step.motions
            .where((m) => m.from >= 0)
            .map((m) => m.from)
            .toSet();
        expect(sources, {
          for (var i = 0; i < 49; i++)
            if (step.before[i] >= 0) i,
        });
        for (final m in step.motions) {
          expect(m.type, step.after[m.to]);
          if (m.from >= 0) {
            expect(m.from % 7, m.to % 7);
            expect(m.to, greaterThanOrEqualTo(m.from));
            expect(m.type, step.before[m.from]);
          } else {
            expect((m.from - m.to % 7) % 7, 0);
            expect(m.type, inInclusiveRange(0, 5));
          }
        }
      }
    }
  });
  test('invalid adjacent exchange has forward and return animations with no expense', () {
    final e = MatchEngine(0);
    final original = [...e.board];
    for (var a = 0; a < 49; a++) {
      for (final b in [a + 1, a + 7]) {
        if (!MatchEngine.adjacent(a, b)) continue;
        if (!e.swap(a, b)) {
          expect(e.lastTurn.map((s) => s.phase), [
            TurnPhase.swap,
            TurnPhase.revert,
          ]);
          expect(e.board, original);
          expect(e.score, 0);
          expect(e.moves, 24);
          return;
        }
        // Restart if this candidate happened to be valid.
        e.board = List.of(original);
        e.score = 0;
        e.moves = 24;
      }
    }
    fail('Expected an invalid adjacent move');
  });
  test('terminal engine produces no further animation or reward', () {
    final e = MatchEngine(0);
    e.score = e.target;
    expect(e.swap(0, 1), isFalse);
    expect(e.lastTurn, isEmpty);
    expect(e.moves, 24);
  });
}
