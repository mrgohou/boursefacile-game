import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paco_bourse/game/paco_game.dart';
import 'package:paco_bourse/ui/paco_app.dart';
import 'package:paco_bourse/ui/paco_theme.dart';

void main() {
  testWidgets(
    'Flame board renders, exposes tile semantics and accepts a valid move',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late final PacoGame game;
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildPacoTheme(),
            home: const PuzzlePage(level: 0),
          ),
        );
        game = tester
            .widget<GameWidget<PacoGame>>(find.byType(GameWidget<PacoGame>))
            .game!;
        await game.loaded;
      });
      await tester.pump(const Duration(milliseconds: 100));
      expect(game.engine.board.length, 49);
      expect(
        find.bySemanticsLabel(RegExp('Ligne 1, colonne 1,')),
        findsOneWidget,
      );
      game.hint();
      await tester.pump();
      expect(find.bySemanticsLabel(RegExp(', indice')), findsNWidgets(2));
      final pair = game.engine.hint()!;
      final before = game.engine.moves;
      final rect = tester.getRect(find.byType(GameWidget<PacoGame>));
      for (final index in pair) {
        await tester.tapAt(
          Offset(
            rect.left + (index % 7 + .5) * rect.width / 7,
            rect.top + (index ~/ 7 + .5) * rect.height / 7,
          ),
        );
      }
      await tester.pump(const Duration(milliseconds: 300));
      expect(game.engine.moves, before - 1);
      expect(game.engine.score, greaterThan(0));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
  testWidgets('victory is persisted before leaving the result screen', (
    tester,
  ) async {
    var saves = 0;
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildPacoTheme(),
          home: PuzzlePage(
            level: 0,
            onCompleted: () async {
              saves++;
              return true;
            },
          ),
        ),
      );
      final game = tester
          .widget<GameWidget<PacoGame>>(find.byType(GameWidget<PacoGame>))
          .game!;
      await game.loaded;
    });
    await tester.pump();
    final game = tester
        .widget<GameWidget<PacoGame>>(find.byType(GameWidget<PacoGame>))
        .game!;
    game.engine.score = game.engine.target - 1;
    final pair = game.engine.hint()!;
    game.selectTile(pair[0]);
    game.selectTile(pair[1]);
    for (var i = 0; i < 180 && game.isAnimating; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump();
    expect(saves, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(saves, 1);
    expect(tester.takeException(), isNull);
  });
}
