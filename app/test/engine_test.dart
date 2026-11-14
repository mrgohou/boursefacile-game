import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paco_bourse/engine/board.dart';
import 'package:paco_bourse/engine/city.dart';

List<LevelDef> loadLevels() => (jsonDecode(File('assets/data/levels.json').readAsStringSync()) as List)
    .map((l) => LevelDef.fromJson((l as Map).cast()))
    .toList();

List<Company> loadCompanies() =>
    ((jsonDecode(File('assets/data/market-snapshot.json').readAsStringSync()) as Map)['companies'] as List)
        .map((c) => Company.fromJson((c as Map).cast()))
        .toList();

List<List<int>> types(Board b) => [for (final row in b.grid) [for (final t in row) t!.type]];

void main() {
  group('parité avec la version web', () {
    test('même hasard que mulberry32 (TypeScript)', () {
      final r = Rng(42);
      expect(r.next(), closeTo(0.6011037519201636, 1e-12));
      expect(r.next(), closeTo(0.44829055899754167, 1e-12));
      expect(r.next(), closeTo(0.8524657934904099, 1e-12));
    });

    test('même grille de départ que le web pour le niveau 1 et le niveau 31', () {
      final levels = loadLevels();
      expect(types(Board.forLevel(levels[0])), [
        [3, 3, 2, 3, 0, 1, 1], [0, 3, 2, 2, 0, 3, 2], [2, 0, 0, 1, 2, 3, 1], [1, 3, 1, 0, 0, 2, 1],
        [3, 1, 3, 2, 0, 1, 2], [1, 0, 0, 2, 2, 3, 2], [0, 3, 3, 0, 0, 2, 3],
      ]);
      expect(types(Board.forLevel(levels[30])), [
        [3, 1, 4, 1, 1, 4, 0], [4, 3, 2, 3, 0, 3, 2], [3, 1, 4, 3, 2, 2, 3], [4, 3, 4, 2, 4, 4, 1],
        [1, 1, 3, 2, 3, 0, 3], [2, 2, 0, 4, 0, 0, 4], [2, 4, 1, 4, 1, 2, 0],
      ]);
    });
  });

  group('puzzle', () {
    test('45 niveaux, tous jouables au départ, sans alignement initial', () {
      final levels = loadLevels();
      expect(levels, hasLength(45));
      for (final l in levels) {
        final b = Board.forLevel(l);
        expect(b.findGroups(), isEmpty, reason: l.id);
        expect(b.hasMove(), isTrue, reason: l.id);
      }
    });

    test('un coup valide marque des points et laisse une grille pleine et stable', () {
      final l = loadLevels().first;
      final b = Board.forLevel(l);
      List<Step>? steps;
      outer:
      for (var r = 0; r < boardSize; r++) {
        for (var c = 0; c < boardSize - 1; c++) {
          steps = b.play(Pos(r, c), Pos(r, c + 1));
          if (steps != null) break outer;
        }
      }
      expect(steps, isNotNull);
      final p = applySteps(emptyProgress(l), steps!);
      expect(p.score, greaterThan(0));
      expect(p.movesLeft, l.moves - 1);
      expect(b.grid.every((row) => row.every((t) => t != null)), isTrue);
      expect(b.findGroups(), isEmpty);
    });

    test('l’indice de Paco propose toujours un coup accepté', () {
      for (final l in loadLevels()) {
        final b = Board.forLevel(l);
        final m = b.findMove();
        expect(m, isNotNull, reason: l.id);
        expect(b.play(m!.$1, m.$2), isNotNull, reason: l.id);
      }
    });

    test('4 alignées créent une tuile Dividende', () {
      final b = Board(tiles: tileTypes, seed: 42);
      final g = b.grid;
      for (var c = 0; c < boardSize; c++) {
        for (var r = 0; r < boardSize; r++) {
          g[r][c]!.type = (r * 2 + c * 3) % 5;
        }
      }
      g[0][0]!.type = 5;
      g[0][1]!.type = 5;
      g[0][2]!.type = 1;
      g[0][3]!.type = 5;
      g[1][2]!.type = 5;
      g[0][4]!.type = 2;
      g[2][2]!.type = 3;
      final steps = b.play(const Pos(0, 2), const Pos(1, 2));
      expect(steps, isNotNull);
      expect(steps!.first.created.any((x) => x.tile.special == Special.dividende), isTrue);
    });

    test('cadenas : 2 touches, non échangeable', () {
      final b = Board(tiles: tileTypes, seed: 7, locks: const [Pos(3, 3)]);
      expect(b.grid[3][3]!.lock, 2);
      expect(b.canSwap(const Pos(3, 3), const Pos(3, 4)), isFalse);
    });

    test('étoiles et épargne suivent le GDD', () {
      final l = loadLevels().first;
      final p = Progress(movesLeft: (l.moves * 0.5).round(), collected: {'cacao': 999});
      expect(stars(l, p), 3);
      expect(savingsEarned(const Progress(movesLeft: 10)), 3000);
    });
  });

  group('Ma Ville', () {
    final companies = loadCompanies();
    test('vrais cours et symboles officiels', () {
      final s = CityState.fresh(companies);
      expect(s.prices['SNTS'], 4110);
      expect(companies.any((c) => c.symbol == 'TTLC'), isTrue);
      expect(companies.any((c) => c.symbol == 'TTLCI'), isFalse);
    });

    test('achat, vente, frais et plus-value', () {
      final s0 = CityState.fresh(companies);
      final b = buy(s0, 'SNTS', 2, 10000)!;
      expect(b.cash, 10000 - buyCost(s0, 'SNTS', 2));
      expect(buy(s0, 'SLBC', 1, 10000), isNull);
      final higher = b.state.copyWith(prices: {...b.state.prices, 'SNTS': 5000});
      final s = sell(higher, 'SNTS', 2, b.cash)!;
      expect(s.gain, greaterThan(0));
      expect(s.state.holdings.containsKey('SNTS'), isFalse);
      expect(s.state.quickSales, 1);
    });

    test('AGO : dividende seulement pour les parts gardées avant le sablier', () {
      var s = buy(CityState.fresh(companies), 'SNTS', 10, 100000)!.state;
      var gained = 0.0;
      for (var i = 0; i < 10; i++) {
        final r = advance(s, companies, 1);
        s = r.state;
        gained += r.cashGained;
      }
      final div = companies.firstWhere((c) => c.symbol == 'SNTS').lastDividend!;
      expect(gained, (div * 10).roundToDouble());
      var t = CityState.fresh(companies);
      for (var i = 0; i < 9; i++) {
        t = advance(t, companies, 2).state;
      }
      t = buy(t, 'SNTS', 10, 100000)!.state;
      expect(advance(t, companies, 2).cashGained, 0);
    });

    test('prix bornés à ±15 % du vrai cours ; le bâtiment grandit', () {
      var s = buy(CityState.fresh(companies), 'ETIT', 5, 10000)!.state;
      for (var i = 0; i < 60; i++) {
        s = advance(s, companies, 3).state;
      }
      for (final c in companies) {
        expect(s.prices[c.symbol]!, inInclusiveRange((c.price * 0.85).floorToDouble(), (c.price * 1.15).ceilToDouble()));
      }
      expect(buildingLevel(s, 'ETIT'), 4);
    });

    test('le Score PACO récompense la diversification', () {
      final s0 = CityState.fresh(companies);
      final one = buy(s0, 'ETIT', 30, 100000)!.state;
      var many = s0;
      for (final sym in ['ETIT', 'SNTS', 'FTSC', 'CIEC', 'CFAC', 'PALC']) {
        many = buy(many, sym, 1, 100000)!.state;
      }
      expect(scorePaco(many, companies, 3), greaterThan(scorePaco(one, companies, 3)));
    });

    test('Paco ne dit jamais « achète » ou « vends »', () {
      final tip = pacoTip(CityState.fresh(companies), companies, 0)!;
      expect(tip.text.toLowerCase(), isNot(matches(RegExp(r'\b(achète|vends)\b'))));
    });
  });
}
