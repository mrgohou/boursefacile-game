// Parcours des écrans + captures (clair et sombre) pour la revue de design.
// Les captures sont écrites dans test/goldens/ avec : flutter test --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paco_bourse/data/content.dart';
import 'package:paco_bourse/main.dart';
import 'package:paco_bourse/services/game_state.dart';
import 'package:paco_bourse/services/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> loadFont() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final loader = FontLoader('Manrope')..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
  await loader.load();
}

Content? _content;

Future<(GameState, Settings)> setup(WidgetTester tester, {Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  // Chargement réel (hors horloge simulée des tests) pour éviter tout blocage.
  return (await tester.runAsync(() async {
    final p = await SharedPreferences.getInstance();
    _content ??= await Content.load(rootBundle);
    return (GameState(_content!, p), Settings(p));
  }))!;
}

Future<void> precacheAll(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final e in tester.allElements.toList()) {
      final w = e.widget;
      if (w is Image) await precacheImage(w.image, e);
    }
  });
  await tester.pump();
}

Future<void> shot(WidgetTester tester, String name) async {
  await precacheAll(tester);
  await tester.pumpAndSettle();
  if (Platform.environment['PACO_SHOTS'] == '1') {
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
  }
}

void main() {
  setUpAll(loadFont);

  for (final dark in [false, true]) {
    final mode = dark ? 'sombre' : 'clair';
    testWidgets('parcours principal ($mode)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      final (game, settings) = await setup(tester, prefs: {'paco.theme': dark ? 'dark' : 'light'});

      await tester.pumpWidget(PacoApp(state: game, settings: settings));
      await tester.pump();
      expect(find.text('Apprends la bourse en jouant'), findsOneWidget);
      await shot(tester, '01-accueil-$mode');

      await tester.tap(find.text('Jouer'));
      await tester.pumpAndSettle();
      expect(find.text('Abidjan'), findsOneWidget);
      await shot(tester, '02-carte-$mode');

      // Simule une partie avancée pour montrer Ma Ville et les cartes.
      for (var c = 1; c <= 3; c++) {
        for (var l = 1; l <= 3; l++) {
          game.stars['c$c-l$l'] = 3;
        }
        game.quiz[c] = 3;
        game.seenIntro.add(c);
      }
      game.savings = 60000;
      for (final s in ['SNTS', 'ETIT', 'FTSC', 'CIEC', 'PALC']) {
        game.buyOne(s);
      }
      for (var i = 0; i < 12; i++) {
        game.winLevel(game.content.levels.first, 3, 0);
      }
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ma Ville').last);
      await tester.pumpAndSettle();
      expect(find.text('Score PACO'), findsWidgets);
      await shot(tester, '03-ma-ville-$mode');

      await tester.tap(find.text('Guichet SGI'));
      await tester.pumpAndSettle();
      await shot(tester, '04-guichet-sgi-$mode');

      await tester.tap(find.text('Cartes'));
      await tester.pumpAndSettle();
      await shot(tester, '05-cartes-$mode');

      await tester.tap(find.text('Moi'));
      await tester.pumpAndSettle();
      await shot(tester, '06-reglages-$mode');

      await tester.tap(find.text('Jouer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cotonou'));
      await tester.pumpAndSettle();
      await shot(tester, '07-ville-$mode');

      await tester.runAsync(game.flush);
    });
  }

  testWidgets('le quiz valide une ville avec 2 bonnes réponses', (tester) async {
    final (game, settings) = await setup(tester);
    game.seenIntro.addAll([0, 1]);
    for (var l = 1; l <= 3; l++) {
      game.stars['c1-l$l'] = 2;
    }
    await tester.pumpWidget(PacoApp(state: game, settings: settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abidjan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quiz de Paco'));
    await tester.pumpAndSettle();
    for (final good in ['8', 'Le franc CFA', 'Abidjan']) {
      await tester.tap(find.text(good).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
    }
    expect(find.text('3 / 3'), findsOneWidget);
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(game.cityValidated(1), isTrue);
    expect(game.cards, hasLength(1));
    expect(find.text('Ton avis sur Abidjan'), findsOneWidget);
    await tester.runAsync(game.flush);
  });
}
