// Capture du plateau de puzzle (Flame). Informatif : lancé à part dans la CI.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paco_bourse/main.dart';
import 'package:paco_bourse/ui/level_page.dart';

import 'screens_test.dart' show loadFont, setup;

void main() {
  setUpAll(loadFont);

  for (final dark in [false, true]) {
    final mode = dark ? 'sombre' : 'clair';
    testWidgets('plateau du niveau 1 ($mode)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      final (game, settings) = await setup(tester, prefs: {'paco.theme': dark ? 'dark' : 'light'});
      game.seenIntro.addAll([0, 1]);
      await tester.pumpWidget(PacoApp(state: game, settings: settings));
      await tester.pump();
      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      nav.push(MaterialPageRoute<void>(builder: (_) => LevelPage(level: game.content.levels.first)));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 300));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      }
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      if (Platform.environment['PACO_SHOTS'] == '1') {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/10-niveau-$mode.png'));
      }
      expect(find.text('C’est parti !'), findsOneWidget);
      await tester.runAsync(game.flush);
    });
  }
}
