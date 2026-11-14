import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paco_bourse/engine/city.dart';
import 'package:paco_bourse/ui/home/city_layout.dart';

void main() {
  final companies = [
    for (final j in (jsonDecode(File('assets/data/market-snapshot.json').readAsStringSync())['companies'] as List))
      Company.fromJson((j as Map).cast()),
  ];

  test('chaque entreprise a un terrain dans le quartier de sa famille', () {
    final plots = planPlots(companies);
    final placed = plots.where((p) => p.company != null).map((p) => p.company!.symbol).toSet();
    expect(placed, {for (final c in companies) c.symbol});
    for (final p in plots.where((p) => p.company != null)) {
      expect(p.company!.family, p.family);
    }
  });

  test('aucun terrain sur une route ni deux terrains au même endroit', () {
    final plots = planPlots(companies);
    final cells = <(int, int)>{};
    for (final p in plots) {
      for (final (di, dj) in const [(0, 0), (0, 1), (1, 0), (1, 1)]) {
        expect(isRoad(p.i + di, p.j + dj), isFalse);
        expect(cells.add((p.i + di, p.j + dj)), isTrue);
      }
    }
  });

  test('la ville tient dans la carte', () {
    for (final (i, j) in [(-margin, -margin), (gridN + margin, gridN + margin), (-margin, gridN + margin), (gridN + margin, -margin)]) {
      final o = iso(i, j);
      expect(o.dx, inInclusiveRange(-0.1, mapWidth + 0.1));
      expect(o.dy, inInclusiveRange(0, mapHeight));
    }
  });
}
