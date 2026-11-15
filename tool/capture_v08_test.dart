import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paco_bourse/game/paco_game.dart';
import 'package:paco_bourse/ui/paco_theme.dart';
import 'package:paco_bourse/ui/puzzle_page.dart';
import 'package:paco_bourse/ui/loading_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Nunito')..addFont(
          File('assets/fonts/Nunito.ttf')
              .readAsBytes()
              .then(ByteData.sublistView),
        ))
        .load();
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root != null) {
      await (FontLoader('MaterialIcons')..addFont(
            File(
              '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
            ).readAsBytes().then(ByteData.sublistView),
          ))
          .load();
    }
  });
  testWidgets('capture real loading and 9x9 challenge widgets', (tester) async {
    tester.view.physicalSize = const Size(540, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final key = GlobalKey();
    Future<void> capture(String name) async {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1.5);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory('docs/screenshots-0.8').createSync(recursive: true);
        File('docs/screenshots-0.8/$name.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
          theme: buildPacoTheme(),
          home: const Scaffold(body: PacoLoadingScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await capture('loading');
    await tester.runAsync(() async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildPacoTheme(),
            home: const PuzzlePage(level: 1),
          ),
        ),
      );
      await tester
          .widget<GameWidget<PacoGame>>(find.byType(GameWidget<PacoGame>))
          .game!
          .loaded;
    });
    await tester.pumpAndSettle();
    await capture('mission-locks');
    await tester.tap(find.text('C’est parti'));
    await tester.pump();
    await capture('puzzle-9x9');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
