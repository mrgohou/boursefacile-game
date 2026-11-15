import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paco_bourse/domain/player_state.dart';
import 'package:paco_bourse/ui/market_list.dart';

void main() {
  test('all 45 archived quotations match the previous catalogue exactly', () {
    final raw = jsonDecode(
      File('assets/companion/market-snapshot.json').readAsStringSync(),
    ) as Map;
    expect(archivedCompanies.length, 45);
    expect(companies.length, 48);
    for (final r in raw['companies'] as List) {
      final c = companies.firstWhere((c) => c.id == r['symbol']);
      expect(c.price, r['price']);
      expect(c.name, r['name']);
      expect(c.family, r['family']);
      expect(File('assets/buildings/${c.family}-1.webp').existsSync(), true);
    }
  });
  test('all historical actions trade and persist, cards survive sale', () {
    var state = PlayerState.initial();
    for (var i = 0; i < 30; i++) {
      state = state.completeLevel(i).answerLesson(i);
    }
    for (final c in archivedCompanies) {
      final before = state.cash;
      state = state.buy(c.id);
      expect(state.holdings[c.id], 1);
      state = PlayerState.fromJson(state.toJson());
      expect(state.holdingsValue, c.price);
      state = state.sell(c.id);
      expect(state.cash, lessThan(before));
      expect(state.companyCards.contains(c.id), true);
    }
    expect(state.companyCards.length, 45);
    expect(state.holdingsValue, 0);
    expect(PlayerState.fromJson(state.toJson()).toJson(), state.toJson());
  });
  test('v4 migration adds zero positions without creating cash or cards', () {
    var state = PlayerState.initial()
        .completeLevel(0)
        .answerLesson(0)
        .completeLevel(1)
        .answerLesson(1)
        .buy('cacao');
    final raw = state.toJson()..['version'] = 4;
    raw['holdings'] = {
      for (final c in legacyCompanies) c.id: state.holdings[c.id],
    };
    raw['prices'] = {for (final c in legacyCompanies) c.id: state.prices[c.id]};
    final restored = PlayerState.fromJson(raw);
    expect(restored.cash, state.cash);
    expect(restored.companyCards, {'cacao'});
    expect(restored.holdings.length, 48);
    expect(restored.holdings['SNTS'], 0);
    expect(restored.prices['SNTS'], 4110);
    final invalid = restored.toJson();
    (invalid['prices'] as Map)['SNTS'] = 1;
    expect(() => PlayerState.fromJson(invalid), throwsFormatException);
  });
  testWidgets('market search opens the historical symbol', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MarketList(
              state: PlayerState.initial(),
              onCompany: (id) => selected = id,
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'SNTS');
    await tester.pump();
    expect(find.text('1 titres affichés'), findsOneWidget);
    await tester.tap(find.text('SNTS · Sonatel Sénégal'));
    expect(selected, 'SNTS');
    expect(tester.takeException(), isNull);
  });
}
