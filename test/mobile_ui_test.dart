import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paco_bourse/audio/game_audio.dart';
import 'package:paco_bourse/data/player_repository.dart';
import 'package:paco_bourse/domain/player_state.dart';
import 'package:paco_bourse/ui/city_map.dart';
import 'package:paco_bourse/ui/paco_app.dart';

class TestRepository implements PlayerRepository {
  PlayerState value = PlayerState.initial();
  @override
  Future<PlayerState> load() async => value;
  @override
  Future<void> save(PlayerState state) async {
    value = state;
  }
}

void motionOff(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

void main() {
  testWidgets('home is the city and inventories open from the game dock', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    motionOff(tester);
    await tester.pumpWidget(
      PacoApp(repository: TestRepository(), audio: SilentGameAudio()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CityMap), findsOneWidget);
    expect(find.text('Ma ville'), findsOneWidget);
    expect(find.text('10\u202f000 FCFA-jeu'), findsOneWidget);
    await tester.tap(find.text('Propriétés'));
    await tester.pumpAndSettle();
    expect(find.text('Mes propriétés'), findsOneWidget);
    expect(find.text('Ta ville attend sa première propriété'), findsOneWidget);
    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mes cartes'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Une première acquisition débloque la carte.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('compact city and menus remain usable with 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    motionOff(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      PacoApp(repository: TestRepository(), audio: SilentGameAudio()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Menu et options'));
    await tester.pumpAndSettle();
    expect(find.text('Musique'), findsOneWidget);
    expect(find.text('Bruitages'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'quiz dismissed from puzzle map does not unlock the next lesson',
    (tester) async {
      motionOff(tester);
      final repo = TestRepository()
        ..value = PlayerState.initial().completeLevel(0);
      await tester.pumpWidget(
        PacoApp(repository: repo, audio: SilentGameAudio()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jouer'));
      await tester.pumpAndSettle();
      expect(find.text('Le chemin de Paco'), findsOneWidget);
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      expect(find.text('Une idée à emporter'), findsOneWidget);
      await tester.tap(find.byTooltip('Fermer et reprendre plus tard'));
      await tester.pumpAndSettle();
      expect(repo.value.unlockedLevel, 0);
      expect(repo.value.answered, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('an acquisition places the property in the home map', (
    tester,
  ) async {
    motionOff(tester);
    final repo = TestRepository()
      ..value = PlayerState.initial()
          .completeLevel(0)
          .answerLesson(0)
          .completeLevel(1)
          .answerLesson(1);
    await tester.pumpWidget(
      PacoApp(repository: repo, audio: SilentGameAudio()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dock-Guichet')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cacao des Lagunes'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Acquérir une part'));
    await tester.tap(find.text('Acquérir une part'));
    await tester.pumpAndSettle();
    expect(repo.value.holdings['cacao'], 1);
    expect(repo.value.companyCards, contains('cacao'));
    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();
    expect(find.text('Agroalimentaire · 1 part'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
