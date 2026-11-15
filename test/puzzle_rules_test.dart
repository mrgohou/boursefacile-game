import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paco_bourse/domain/puzzle_clock.dart';
import 'package:paco_bourse/game/paco_game.dart';
import 'package:paco_bourse/ui/puzzle_page.dart';
import 'package:paco_bourse/ui/paco_theme.dart';
import 'package:paco_bourse/ui/clay_heading.dart';

void main() {
  test('difficulty budgets and deadline start are explicit', () {
    expect(List.generate(6, puzzleSeconds), [120, 120, 120, 180, 120, 180]);
    var now = DateTime.utc(2026);
    final clock = PuzzleClock(60, now: () => now);
    now = now.add(const Duration(hours: 1));
    expect(clock.remaining, 60);
    clock.start();
    now = now.add(const Duration(milliseconds: 59500));
    expect(clock.remaining, 1);
    clock.start();
    now = now.add(const Duration(milliseconds: 500));
    expect(clock.remaining, 0);
    now = now.add(const Duration(days: 1));
    expect(clock.remaining, 0);
  });
  testWidgets(
    'instructions block play and timeout cannot reward or accept more moves',
    (tester) async {
      var now = DateTime.utc(2026), rewards = 0;
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildPacoTheme(),
            home: PuzzlePage(
              level: 0,
              now: () => now,
              onCompleted: () async {
                rewards++;
                return true;
              },
            ),
          ),
        );
        await tester
            .widget<GameWidget<PacoGame>>(find.byType(GameWidget<PacoGame>))
            .game!
            .loaded;
      });
      await tester.pump();
      final game = tester
          .widget<GameWidget<PacoGame>>(find.byType(GameWidget<PacoGame>))
          .game!;
      final moves = game.engine.moves;
      final hint = game.engine.hint()!;
      game.selectTile(hint[0]);
      game.selectTile(hint[1]);
      expect(game.engine.moves, moves);
      now = now.add(const Duration(minutes: 5));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ClayHeading), findsNothing);
      await tester.tap(find.text('C’est parti'));
      await tester.pump();
      expect(game.inputEnabled, isTrue);
      now = now.add(Duration(seconds: puzzleSeconds(0)));
      game.selectTile(hint[0]);
      game.selectTile(hint[1]);
      expect(game.engine.moves, moves);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('PAS DE CHANCE'), findsOneWidget);
      expect(find.text('Le temps est écoulé.'), findsOneWidget);
      expect(rewards, 0);
      expect(game.inputEnabled, isFalse);
      game.selectTile(hint[0]);
      game.selectTile(hint[1]);
      expect(game.engine.moves, moves);
      await tester.tap(find.text('Rejouer'));
      await tester.pumpAndSettle();
      expect(find.text('C’est parti'), findsOneWidget);
      expect(find.byType(ClayHeading), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'deadline wins for an already solved move; home leaves result route',
    (tester) async {
      var now = DateTime.utc(2026), rewards = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildPacoTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => PuzzlePage(
                      level: 0,
                      now: () => now,
                      onCompleted: () async {
                        rewards++;
                        return true;
                      },
                    ),
                  ),
                ),
                child: const Text('Accueil'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Accueil'));
      await tester.pump();
      await tester.runAsync(() async {
        await tester.pump(const Duration(milliseconds: 400));
        await tester
            .widget<GameWidget<PacoGame>>(find.byType(GameWidget<PacoGame>))
            .game!
            .loaded;
      });
      await tester.pumpAndSettle();
      await tester.tap(find.text('C’est parti'));
      await tester.pump();
      final game = tester
          .widget<GameWidget<PacoGame>>(find.byType(GameWidget<PacoGame>))
          .game!;
      game.engine.score = game.engine.target - 1;
      final pair = game.engine.hint()!;
      game.selectTile(pair[0]);
      game.selectTile(pair[1]);
      expect(game.engine.won, isTrue);
      now = now.add(Duration(seconds: puzzleSeconds(0)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('GAGNE'), findsOneWidget);
      expect(rewards, 1);
      await tester.tap(find.text('Menu principal'));
      await tester.pumpAndSettle();
      expect(find.text('Accueil'), findsOneWidget);
      expect(find.byType(PuzzlePage), findsNothing);
      expect(rewards, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
