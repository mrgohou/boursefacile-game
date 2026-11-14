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
      expect(find.text('Place de la Bourse'), findsOneWidget);
      await shot(tester, '02-ville-debut-$mode');

      // Simule une partie avancée : bâtiments, cartes, quartiers débloqués.
      for (var c = 1; c <= 3; c++) {
        for (var l = 1; l <= 3; l++) {
          game.stars['c$c-l$l'] = 3;
        }
        game.quiz[c] = 3;
        game.seenIntro.add(c);
      }
      game.savings = 90000;
      for (final s in ['SNTS', 'ETIT', 'FTSC', 'CIEC', 'PALC', 'SGBC', 'SIBC', 'NTLC']) {
        game.buyOne(s);
      }
      for (var i = 0; i < 12; i++) {
        game.winLevel(game.content.levels.first, 3, 0);
      }
      await tester.pumpAndSettle();
      await shot(tester, '03-ville-$mode');

      Future<void> visit(Finder button, String name) async {
        await tester.tap(button);
        await tester.pumpAndSettle();
        await shot(tester, name);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      await visit(find.text('Propriétés'), '04-proprietes-$mode');
      await visit(find.text('Guichet'), '05-guichet-sgi-$mode');
      await visit(find.text('Cartes'), '06-cartes-$mode');
      await visit(find.text('Moi'), '07-reglages-$mode');

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pumpAndSettle();
      expect(find.text('La route des villes'), findsOneWidget);
      await shot(tester, '08-route-$mode');

      await tester.ensureVisible(find.text('Cotonou'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cotonou'));
      await tester.pumpAndSettle();
      await shot(tester, '09-ville-cotonou-$mode');

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
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Abidjan'));
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
