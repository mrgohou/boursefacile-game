import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paco_bourse/domain/cultural_rewards.dart';
import 'package:paco_bourse/domain/player_state.dart';
import 'package:paco_bourse/game/paco_game.dart';
import 'package:paco_bourse/ui/reward_dialog.dart';
import 'package:paco_bourse/ui/city_map.dart';
import 'package:paco_bourse/ui/paco_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Nunito')..addFont(
          File('assets/fonts/Nunito.ttf')
              .readAsBytes()
              .then(ByteData.sublistView),
        ))
        .load();
    final sdk = Platform.environment['FLUTTER_ROOT'];
    if (sdk != null) {
      final root = '$sdk/bin/cache/artifacts/material_fonts';
      await (FontLoader('MaterialIcons')..addFont(
            File('$root/MaterialIcons-Regular.otf')
                .readAsBytes()
                .then(ByteData.sublistView),
          ))
          .load();
      await (FontLoader('Roboto')..addFont(
            File('$root/Roboto-Regular.ttf')
                .readAsBytes()
                .then(ByteData.sublistView),
          ))
          .load();
    }
  });
  void view(WidgetTester t) {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  Future<void> capture(WidgetTester t, GlobalKey key, String name) async {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    await t.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final im = await b.toImage(pixelRatio: 2);
      final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
      final d = Directory('/workspace/work/v09-previews')
        ..createSync(recursive: true);
      await File('${d.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      im.dispose();
    });
  }

  testWidgets('récompense native et collecte enregistrée avant fermeture', (
    t,
  ) async {
    view(t);
    final key = GlobalKey();
    var collected = false;
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildPacoTheme(),
          home: Scaffold(
            body: Builder(
              builder: (c) => TextButton(
                onPressed: () => showDialog<bool>(
                  context: c,
                  builder: (_) => RewardDialog(
                    reward: const CulturalReward(1, 'level10'),
                    onCollect: () async {
                      collected = true;
                      return true;
                    },
                  ),
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Ouvrir'));
    await t.pumpAndSettle();
    await capture(t, key, 'reward-level10');
    expect(t.takeException(), isNull);
    await t.ensureVisible(find.text('COLLECTER'));
    await t.tap(find.text('COLLECTER'));
    await t.pumpAndSettle();
    expect(collected, isTrue);
    expect(find.text('COLLECTER'), findsNothing);
  });
  testWidgets('collecte échouée reste disponible à grande taille de texte', (
    t,
  ) async {
    view(t);
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildPacoTheme(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const Scaffold(
            body: RewardDialog(
              reward: CulturalReward(1, 'quiz5'),
              onCollect: failCollection,
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('COLLECTER'));
    await t.tap(find.text('COLLECTER'));
    await t.pumpAndSettle();
    expect(find.textContaining('Collecte non enregistrée'), findsOneWidget);
    expect(find.text('COLLECTER'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('plateau tactile avec nouveaux spéciaux et motif textile', (
    t,
  ) async {
    view(t);
    final key = GlobalKey();
    final g = PacoGame(
      level: 4,
      reducedMotion: true,
      onUpdate: (_, _, _) {},
      onWin: () {},
      onLose: () {},
    );
    await t.runAsync(() async {
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildPacoTheme(),
            home: Scaffold(
              appBar: AppBar(title: const Text('Pano di Pinti · étape 5')),
              body: Center(
                child: SizedBox(
                  width: 390,
                  height: 390,
                  child: GameWidget(game: g),
                ),
              ),
            ),
          ),
        ),
      );
      await g.loaded;
    });
    await t.pump();
    await capture(t, key, 'puzzle-cultural');
    expect(g.engine.specials, isNotEmpty);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox.shrink());
    await t.pump();
  });
  testWidgets('ville moderne développée', (t) async {
    view(t);
    var s = PlayerState.initial();
    for (var i = 0; i < 10; i++) {
      s = s.completeLevel(i).answerLesson(i);
    }
    for (var i = 0; i < 6; i++) {
      s = s.buy('cacao');
    }
    s = s
        .buy('telecom')
        .buyLand('rive')
        .construct('rive', 'ferme')
        .placeCompany('cacao', 'centre', 3);
    final key = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildPacoTheme(),
          home: Scaffold(
            body: CityMap(state: s, reducedMotion: true, onBuildingTap: (_) {}),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await capture(t, key, 'city-modern');
    expect(s.cityTier, 2);
    expect(t.takeException(), isNull);
  });
}

Future<bool> failCollection() async => false;
