import 'dart:io';

import 'package:paco_bourse/domain/challenge_catalog.dart';

import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paco_bourse/audio/game_audio.dart';
import 'package:paco_bourse/data/player_repository.dart';
import 'package:paco_bourse/domain/player_state.dart';
import 'package:paco_bourse/game/paco_game.dart';
import 'package:paco_bourse/ui/paco_app.dart';

class LastStageRepository implements PlayerRepository {
  PlayerState value = PlayerState.initial();
  LastStageRepository() {
    for (var i = 0; i < 29; i++) {
      value = value.completeLevel(i).answerLesson(i);
    }
  }
  @override
  Future<PlayerState> load() async => value;
  @override
  Future<void> save(PlayerState state) async {
    value = state;
  }
}

void main() {
  testWidgets('stage 30 is accessible from the map and opens its own mission', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final key = GlobalKey();
    final repo = LastStageRepository();
    Future<void> capture(String name) async {
      final path = Platform.environment['PACO_PREVIEW_DIR'];
      if (path == null) return;
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory(path).createSync(recursive: true);
        File('$path/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: PacoApp(repository: repo, audio: SilentGameAudio()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jouer'));
    await tester.pumpAndSettle();
    expect(find.text('29 / 30 étapes'), findsOneWidget);
    await capture('flutter-map-30');
    await tester.runAsync(() async {
      await tester.tap(find.text('Continuer · étape 30'));
      await tester.pumpAndSettle();
      await tester
          .widget<GameWidget<PacoGame>>(find.byType(GameWidget<PacoGame>))
          .game!
          .loaded;
    });
    await tester.pumpAndSettle();
    expect(find.text('C’est parti'), findsOneWidget);
    final game = tester
        .widget<GameWidget<PacoGame>>(find.byType(GameWidget<PacoGame>))
        .game!;
    expect(game.engine.target, challengeFor(29).score);
    expect(game.engine.moves, challengeFor(29).moves);
    await capture('flutter-stage-30');
    expect(repo.value.cash, 53500);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
