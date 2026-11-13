import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paco_bourse/data/player_repository.dart';
import 'package:paco_bourse/domain/player_state.dart';
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

void main() {
  testWidgets('mobile navigation and demo disclosure render without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(PacoApp(repository: TestRepository()));
    await tester.pumpAndSettle();
    expect(find.text('Démo locale · argent fictif'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
    await tester.tap(find.text('Ma ville'));
    await tester.pumpAndSettle();
    expect(find.text('Ta ville, tes décisions.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Carnet'));
    await tester.pumpAndSettle();
    expect(find.text('Ton carnet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('small screen and 200 percent text remain scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(PacoApp(repository: TestRepository()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Ma ville'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('closing a quiz does not unlock the next lesson', (tester) async {
    final repo = TestRepository()
      ..value = PlayerState.initial().completeLevel(0);
    await tester.pumpWidget(PacoApp(repository: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    expect(find.text('Une idée à emporter'), findsOneWidget);
    await tester.tap(find.byTooltip('Fermer et reprendre plus tard'));
    await tester.pumpAndSettle();
    expect(repo.value.unlockedLevel, 0);
    expect(repo.value.answered, isEmpty);
  });
}
