import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:paco_bourse/domain/player_state.dart';
import 'package:paco_bourse/ui/collection_sheets.dart';
import 'package:paco_bourse/ui/paco_theme.dart';

PlayerState _owner() => PlayerState.initial()
    .completeLevel(0)
    .answerLesson(0)
    .completeLevel(1)
    .answerLesson(1)
    .buy('cacao');

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  double scale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildPacoTheme(),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 800),
          textScaler: TextScaler.linear(scale),
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('propriétés : état vide et guichet, aucune propriété inventée', (
    tester,
  ) async {
    var opened = false;
    await _show(
      tester,
      PropertiesSheet(
        state: PlayerState.initial(),
        onCompanyTap: (_) {},
        onOpenGuichet: () => opened = true,
      ),
    );
    expect(find.text('Cacao des Lagunes'), findsNothing);
    await tester.ensureVisible(find.text('Découvrir le guichet'));
    await tester.tap(find.text('Découvrir le guichet'));
    expect(opened, isTrue);
  });

  testWidgets(
    'propriétés : seules les parts détenues, callback sans mutation',
    (tester) async {
      final state = _owner();
      String? selected;
      await _show(
        tester,
        PropertiesSheet(state: state, onCompanyTap: (id) => selected = id),
      );
      expect(find.text('Cacao des Lagunes'), findsOneWidget);
      expect(find.text('Télécom Horizon'), findsNothing);
      await tester.ensureVisible(find.text('Voir cette entreprise →'));
      await tester.tap(find.text('Voir cette entreprise →'));
      expect(selected, 'cacao');
      expect(state.holdings['cacao'], 1);
    },
  );

  testWidgets('cartes : collection conservée après vente et leçons acquises', (
    tester,
  ) async {
    String? selected;
    await _show(
      tester,
      CompanyCardsSheet(state: _owner(), onCompanyTap: (id) => selected = id),
    );
    expect(find.text('Voir la fiche'), findsOneWidget);
    await tester.ensureVisible(find.text('Voir la fiche'));
    await tester.tap(find.text('Voir la fiche'));
    expect(selected, 'cacao');
    expect(find.byType(ExpansionTile), findsNWidgets(2));
    selected = null;
    await _show(
      tester,
      CompanyCardsSheet(
        state: _owner().sell('cacao'),
        onCompanyTap: (id) => selected = id,
      ),
    );
    expect(find.text('Voir la fiche'), findsOneWidget);
    expect(
      find.textContaining('Elle reste dans ta collection après la vente.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Voir la fiche'));
    await tester.tap(find.text('Voir la fiche'));
    expect(selected, 'cacao');
    await _show(
      tester,
      CompanyCardsSheet(state: PlayerState.initial(), onCompanyTap: (_) {}),
    );
    expect(find.text('Voir la fiche'), findsNothing);
  });

  testWidgets('cartes lisibles à 200 % sans débordement', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _show(
      tester,
      CompanyCardsSheet(state: _owner(), onCompanyTap: (_) {}),
      scale: 2,
    );
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -1200),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
