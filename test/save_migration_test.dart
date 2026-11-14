import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:paco_bourse/domain/player_state.dart';

// Hand-built v0.1/v1 payload: no companyCards field exists in the old format.
Map<String, dynamic> legacyOwned() => {
  'version': 1,
  'cash': 9450,
  'holdings': {'cacao': 1, 'telecom': 0, 'banque': 1},
  'prices': {'cacao': 2000, 'telecom': 2500, 'banque': 1500},
  'completed': [0, 1],
  'answered': [0, 1],
  'marketDropped': false,
  'dividendPaid': false,
  'history': ['Achat : 2000 + 25 FCFA-jeu de frais.'],
};

void main() {
  test('ancien JSON v1 migre les seules cartes prouvées par les positions', () {
    final old = legacyOwned();
    expect(old.containsKey('companyCards'), isFalse);
    final migrated = PlayerState.fromJson(jsonDecode(jsonEncode(old)));
    expect(migrated.companyCards, {'cacao', 'banque'});
    expect(migrated.cash, old['cash']);
    expect(migrated.holdings, old['holdings']);
    expect(migrated.prices, old['prices']);
    expect(migrated.completed, {0, 1});
    expect(migrated.answered, {0, 1});
    expect(migrated.unlockedLevel, 2);
    final encoded = migrated.toJson();
    expect(encoded['version'], 2);
    expect(encoded['companyCards'], ['banque', 'cacao']);
    expect(PlayerState.fromJson(encoded).toJson(), encoded);
  });

  test('v1 vide et anciennes ventes ne fabriquent aucune carte', () {
    final sold = legacyOwned()
      ..['holdings'] = {'cacao': 0, 'telecom': 0, 'banque': 0}
      ..['history'] = [
        'Achat : 2500 + 25 FCFA-jeu de frais.',
        'Vente : 2500 − 25 FCFA-jeu de frais.',
      ];
    expect(PlayerState.fromJson(sold).companyCards, isEmpty);
    final oldInitial = PlayerState.initial().toJson()
      ..['version'] = 1
      ..remove('companyCards');
    expect(PlayerState.fromJson(oldInitial).companyCards, isEmpty);
  });

  test('achat déverrouille définitivement, vente et sauvegarde préservent', () {
    final start = PlayerState.fromJson(legacyOwned());
    final bought = start.buy('telecom');
    final sold = bought.sell('telecom');
    expect(start.companyCards, {'banque', 'cacao'});
    expect(bought.companyCards, {'banque', 'cacao', 'telecom'});
    expect(sold.holdings['telecom'], 0);
    expect(sold.companyCards, bought.companyCards);
    final restored = PlayerState.fromJson(
      jsonDecode(jsonEncode(sold.toJson())),
    );
    expect(restored.companyCards, sold.companyCards);
    expect(() => restored.companyCards.add('other'), throwsUnsupportedError);
    expect(() => restored.companyCards.remove('cacao'), throwsUnsupportedError);
  });

  test('les autres changements conservent les cartes et les gardes métier', () {
    var state = PlayerState.fromJson(legacyOwned());
    for (var i = 2; i <= 4; i++) {
      state = state.completeLevel(i).answerLesson(i);
      expect(state.companyCards, {'cacao', 'banque'});
    }
    final changed = state.dropMarket().payDividend();
    expect(changed.companyCards, state.companyCards);
    expect(changed.cash, state.cash + 100);
    expect(changed.prices['cacao'], 1600);
    expect(identical(changed.completeLevel(4), changed), isTrue);
    expect(() => PlayerState.initial().buy('cacao'), throwsStateError);
    expect(PlayerState.initial().companyCards, isEmpty);
    expect(PlayerState.initial().toJson()['companyCards'], isEmpty);
  });

  test(
    'v2 refuse cartes manquantes, inconnues, doublons et types invalides',
    () {
      final valid = PlayerState.fromJson(legacyOwned()).toJson();
      final missing = Map<String, dynamic>.from(valid)..remove('companyCards');
      for (final bad in <Map<String, dynamic>>[
        missing,
        {...valid, 'companyCards': null},
        {...valid, 'companyCards': 'cacao'},
        {
          ...valid,
          'companyCards': [1],
        },
        {
          ...valid,
          'companyCards': ['cacao', 'cacao', 'banque'],
        },
        {
          ...valid,
          'companyCards': ['cacao', 'banque', 'unknown'],
        },
        {
          ...valid,
          'companyCards': ['cacao'],
        },
        {...valid, 'companyCards': []},
        {
          ...valid,
          'companyCards': ['cacao', 'banque', 'telecom', 'unknown'],
        },
        {...valid, 'version': 3},
      ]) {
        expect(() => PlayerState.fromJson(bad), throwsFormatException);
      }
    },
  );
}
