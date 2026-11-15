import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paco_bourse/game/paco_game.dart';
import 'package:paco_bourse/ui/knowledge_page.dart';
import 'package:paco_bourse/ui/puzzle_page.dart';
import 'package:paco_bourse/ui/paco_theme.dart';

void main() {
  testWidgets(
    'knowledge base loads forty exercises and records an attempted answer',
    (tester) async {
      String? topic;
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: KnowledgePage(
              topic: 'budget',
              onAttempt: (t, correct) => topic = t,
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      expect(find.textContaining('40 exercices pratiques'), findsOneWidget);
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(OutlinedButton).first);
      await tester.pumpAndSettle();
      expect(topic, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'narrow phone keeps 48dp cells and can reveal rightmost columns without swapping',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildPacoTheme(),
            home: const PuzzlePage(level: 37, mastery: 2),
          ),
        );
        await tester
            .widget<GameWidget<PacoGame>>(find.byType(GameWidget<PacoGame>))
            .game!
            .loaded;
      });
      await tester.pump();
      await tester.tap(find.text('C’est parti'));
      await tester.pump();
      final rect = tester.getRect(find.byType(GameWidget<PacoGame>));
      expect(rect.width / 9, greaterThanOrEqualTo(48));
      final game = tester
          .widget<GameWidget<PacoGame>>(find.byType(GameWidget<PacoGame>))
          .game!;
      final moves = game.engine.moves;
      await tester.ensureVisible(find.byTooltip('Voir les colonnes de droite'));
      await tester.tap(find.byTooltip('Voir les colonnes de droite'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(game.engine.moves, moves);
      expect(
        tester.getRect(find.byType(GameWidget<PacoGame>)).left,
        lessThan(rect.left),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
