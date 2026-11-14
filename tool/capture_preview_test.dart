import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paco_bourse/audio/game_audio.dart';
import 'package:paco_bourse/data/player_repository.dart';
import 'package:paco_bourse/domain/player_state.dart';
import 'package:paco_bourse/game/paco_game.dart';
import 'package:paco_bourse/ui/paco_app.dart';
import 'package:paco_bourse/ui/paco_theme.dart';

class PreviewRepository implements PlayerRepository {
  PlayerState state = PlayerState.initial()
      .completeLevel(0)
      .answerLesson(0)
      .completeLevel(1)
      .answerLesson(1)
      .buy('cacao')
      .buy('telecom')
      .buy('banque');
  @override
  Future<PlayerState> load() async => state;
  @override
  Future<void> save(PlayerState next) async {
    state = next;
  }
}

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
      final font = FontLoader('Roboto');
      for (final file in ['Roboto-Regular.ttf', 'Roboto-Bold.ttf']) {
        font.addFont(
          File('$sdk/bin/cache/artifacts/material_fonts/$file')
              .readAsBytes()
              .then(ByteData.sublistView),
        );
      }
      await font.load();
      await (FontLoader('MaterialIcons')..addFont(
            File(
              '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
            ).readAsBytes().then(ByteData.sublistView),
          ))
          .load();
    }
  });
  void viewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory(
        Platform.environment['PACO_PREVIEW_DIR'] ?? 'build/previews',
      );
      dir.createSync(recursive: true);
      await File('${dir.path}/$name.png')
          .writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('capture city home', (tester) async {
    viewport(tester);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: PacoApp(
          repository: PreviewRepository(),
          audio: SilentGameAudio(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    await capture(tester, key, 'city-home');
    expect(tester.takeException(), isNull);
  });
  testWidgets('capture animated puzzle layout', (tester) async {
    viewport(tester);
    final key = GlobalKey();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildPacoTheme(),
            home: const PuzzlePage(level: 2),
          ),
        ),
      );
      final game = tester
          .widget<GameWidget<PacoGame>>(find.byType(GameWidget<PacoGame>))
          .game!;
      await game.loaded;
    });
    await tester.pump(const Duration(milliseconds: 200));
    await capture(tester, key, 'puzzle');
    expect(tester.takeException(), isNull);
  });
}
