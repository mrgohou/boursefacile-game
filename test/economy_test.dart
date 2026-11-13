import 'package:flutter_test/flutter_test.dart';

import 'package:paco_bourse/domain/player_state.dart';

PlayerState through(int last) {
  var state = PlayerState.initial();
  for (var i = 0; i <= last; i++) {
    state = state.completeLevel(i).answerLesson(i);
  }
  return state;
}

void main() {
  test('progression séquentielle et récompense unique', () {
    final start = PlayerState.initial();
    expect(() => start.completeLevel(1), throwsStateError);
    expect(() => start.answerLesson(0), throwsStateError);
    final won = start.completeLevel(0);
    expect(won.cash, 11500);
    expect(identical(won.completeLevel(0), won), isTrue);
    expect(won.unlockedLevel, 0);
    expect(won.answerLesson(0).unlockedLevel, 1);
    expect(through(5).unlockedLevel, 6);
    expect(start.cash, 10000);
    expect(() => won.holdings['cacao'] = 9, throwsUnsupportedError);
  });
  test(
    'transactions fermées avant apprentissage, frais et absence de parts',
    () {
      expect(() => PlayerState.initial().buy('cacao'), throwsStateError);
      final start = through(1);
      expect(() => start.sell('cacao'), throwsStateError);
      final bought = start.buy('cacao');
      expect(bought.totalValue, start.totalValue - 25);
      expect(bought.sell('cacao').cash, start.cash - 50);
      var poor = start;
      while (poor.cash >= 2025) {
        poor = poor.buy('cacao');
      }
      expect(() => poor.buy('cacao'), throwsStateError);
      expect(() => start.buy('unknown'), throwsArgumentError);
    },
  );
  test('baisse et dividende uniques et détachement neutre', () {
    expect(() => through(1).dropMarket(), throwsStateError);
    var state = through(4).buy('cacao').buy('cacao');
    expect(() => state.payDividend(), throwsStateError);
    final beforeDrop = state.totalValue;
    state = state.dropMarket();
    expect(state.totalValue, beforeDrop - 600);
    expect(identical(state.dropMarket(), state), isTrue);
    final paid = state.payDividend();
    expect(paid.cash, state.cash + 200);
    expect(paid.totalValue, state.totalValue);
    expect(paid.prices['cacao'], 1600);
    expect(identical(paid.payDividend(), paid), isTrue);
    expect(() => through(4).dropMarket().payDividend(), throwsStateError);
  });
  test('sérialisation et données corrompues', () {
    final state = through(4).buy('cacao').dropMarket().payDividend();
    expect(PlayerState.fromJson(state.toJson()).toJson(), state.toJson());
    for (final bad in <Map<String, dynamic>>[
      {},
      {...state.toJson(), 'cash': -1},
      {...state.toJson(), 'cash': 1.5},
      {
        ...state.toJson(),
        'completed': [0, 0],
      },
      {
        ...state.toJson(),
        'answered': [5],
      },
      {
        ...state.toJson(),
        'prices': {'cacao': 0, 'telecom': 2500, 'banque': 1500},
      },
      {
        ...state.toJson(),
        'holdings': {'cacao': -1, 'telecom': 0, 'banque': 0},
      },
    ]) {
      expect(() => PlayerState.fromJson(bad), throwsFormatException);
    }
    var repeated = through(1);
    for (var i = 0; i < 30; i++) {
      repeated = repeated.buy('cacao').sell('cacao');
    }
    expect(repeated.history.length, 50);
  });
}
