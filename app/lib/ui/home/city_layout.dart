// Plan de la ville (vue isométrique façon city-builder) : routes, quartiers par famille, terrains.
// Pur Dart, sans dessin : testable.
import 'dart:ui' show Offset;

import '../../engine/city.dart';

const tileW = 96.0, tileH = 48.0;
const blocks = 4, blockSize = 4;
const gridN = blocks * (blockSize + 1) + 1; // 21 cases de côté, routes comprises
const margin = 4.0; // cases d'eau et de berge autour de la ville
const topExtra = 140.0; // place pour les bâtiments hauts de la première rangée

const mapWidth = (gridN + 2 * margin) * tileW;
const mapHeight = (gridN + 2 * margin) * tileH + topExtra + 60;

/// Position à l'écran d'un point de la grille (coordonnées continues).
Offset iso(double i, double j) =>
    Offset((i - j) * tileW / 2 + (gridN + 2 * margin) * tileW / 2, (i + j) * tileH / 2 + margin * tileH + topExtra);

bool isRoad(int i, int j) => i % (blockSize + 1) == 0 || j % (blockSize + 1) == 0;

enum BlockKind { plaza, park, district }

class BlockPlan {
  const BlockPlan(this.bi, this.bj, this.kind, [this.family]);
  final int bi, bj;
  final BlockKind kind;
  final Family? family;
  int get i0 => bi * (blockSize + 1) + 1;
  int get j0 => bj * (blockSize + 1) + 1;
  Offset get center => iso(i0 + blockSize / 2, j0 + blockSize / 2);
}

/// Quartiers : la banque au centre-ville, la Place de la Bourse au cœur, deux parcs.
const blockPlans = <BlockPlan>[
  BlockPlan(0, 0, BlockKind.district, Family.banque),
  BlockPlan(0, 1, BlockKind.district, Family.banque),
  BlockPlan(1, 0, BlockKind.district, Family.banque),
  BlockPlan(0, 2, BlockKind.district, Family.banque),
  BlockPlan(0, 3, BlockKind.district, Family.industrie),
  BlockPlan(1, 3, BlockKind.district, Family.industrie),
  BlockPlan(2, 0, BlockKind.district, Family.agro),
  BlockPlan(3, 0, BlockKind.district, Family.agro),
  BlockPlan(3, 1, BlockKind.district, Family.distribution),
  BlockPlan(3, 2, BlockKind.district, Family.distribution),
  BlockPlan(2, 2, BlockKind.district, Family.services),
  BlockPlan(1, 2, BlockKind.district, Family.telecom),
  BlockPlan(2, 1, BlockKind.district, Family.energie),
  BlockPlan(1, 1, BlockKind.plaza),
  BlockPlan(2, 3, BlockKind.park),
  BlockPlan(3, 3, BlockKind.park),
];

BlockPlan get plaza => blockPlans.firstWhere((b) => b.kind == BlockKind.plaza);

/// Un terrain de 2 × 2 cases. company == null : terrain libre (jardin).
class Plot {
  const Plot(this.i, this.j, this.family, this.company);
  final int i, j;
  final Family family;
  final Company? company;
  Offset get center => iso(i + 1.0, j + 1.0);
  int get depth => i + j;
}

/// Attribue à chaque entreprise un terrain fixe dans le quartier de sa famille.
List<Plot> planPlots(List<Company> companies) {
  final plots = <Plot>[];
  for (final f in Family.values) {
    final list = companies.where((c) => c.family == f).toList()..sort((a, b) => a.symbol.compareTo(b.symbol));
    var k = 0;
    for (final b in blockPlans.where((b) => b.family == f)) {
      for (final (di, dj) in const [(0, 0), (0, 2), (2, 0), (2, 2)]) {
        plots.add(Plot(b.i0 + di, b.j0 + dj, f, k < list.length ? list[k] : null));
        k++;
      }
    }
  }
  return plots;
}
