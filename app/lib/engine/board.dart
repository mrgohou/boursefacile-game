// Moteur du puzzle PACO Bourse (match-3). Logique pure, sans Flutter : testable.
// Portage fidèle de src/engine/board.ts (version web).

const int boardSize = 7;

/// 6 tuiles de base, liées aux secteurs de la BRVM.
const List<String> tileTypes = ['cacao', 'telephone', 'billet', 'bidon', 'ampoule', 'engrenage'];

/// Spéciales : noms = notions de bourse.
enum Special { dividende, ago, diversif }

class Tile {
  Tile(this.id, this.type, {this.special, this.lock});
  final int id;
  int type; // index dans tileTypes
  Special? special;
  int? lock; // cadenas « Frais » : touches restantes

  String get name => tileTypes[type];
}

class Pos {
  const Pos(this.r, this.c);
  final int r;
  final int c;
  int get key => r * boardSize + c;
  bool get inside => r >= 0 && c >= 0 && r < boardSize && c < boardSize;
  @override
  bool operator ==(Object other) => other is Pos && other.r == r && other.c == c;
  @override
  int get hashCode => key;
  @override
  String toString() => '($r,$c)';
}

sealed class Objective {
  const Objective();
  factory Objective.fromJson(Map<String, dynamic> j) => switch (j['kind']) {
        'collect' => CollectObjective(j['tile'] as String, j['count'] as int),
        'score' => ScoreObjective(j['target'] as int),
        _ => UnlockObjective(j['count'] as int),
      };
}

class CollectObjective extends Objective {
  const CollectObjective(this.tile, this.count);
  final String tile;
  final int count;
}

class ScoreObjective extends Objective {
  const ScoreObjective(this.target);
  final int target;
}

class UnlockObjective extends Objective {
  const UnlockObjective(this.count);
  final int count;
}

class LevelDef {
  const LevelDef({
    required this.id,
    required this.city,
    required this.index,
    required this.moves,
    required this.tiles,
    required this.objectives,
    required this.locks,
    required this.seed,
    required this.pacoBefore,
    required this.pacoHint,
  });

  factory LevelDef.fromJson(Map<String, dynamic> j) => LevelDef(
        id: j['id'] as String,
        city: j['city'] as int,
        index: j['index'] as int,
        moves: j['moves'] as int,
        tiles: (j['tiles'] as List).cast<String>(),
        objectives: (j['objectives'] as List).map((o) => Objective.fromJson(o as Map<String, dynamic>)).toList(),
        locks: ((j['locks'] as List?) ?? const []).map((p) => Pos((p as List)[0] as int, p[1] as int)).toList(),
        seed: j['seed'] as int,
        pacoBefore: j['pacoBefore'] as String,
        pacoHint: j['pacoHint'] as String,
      );

  final String id;
  final int city;
  final int index;
  final int moves;
  final List<String> tiles;
  final List<Objective> objectives;
  final List<Pos> locks;
  final int seed;
  final String pacoBefore;
  final String pacoHint;
}

class Placed {
  const Placed(this.tile, this.pos);
  final Tile tile;
  final Pos pos;
}

class LockHit {
  const LockHit(this.tile, this.pos, this.opened);
  final Tile tile;
  final Pos pos;
  final bool opened;
}

/// Une étape de résolution (pour l'animation).
class Step {
  final List<Placed> cleared = [];
  final List<Placed> created = [];
  final List<LockHit> lockHits = [];
  final List<Tile> spawned = [];
  late List<List<Tile?>> grid;
  int points = 0;
}

class Progress {
  const Progress({required this.movesLeft, this.score = 0, this.collected = const {}, this.unlocked = 0});
  final int movesLeft;
  final int score;
  final Map<String, int> collected;
  final int unlocked;
}

/// Hasard reproductible (mulberry32, identique à la version web).
class Rng {
  Rng(int seed) : _a = seed & 0xffffffff;
  int _a;

  /// Math.imul sur 32 bits, sans dépasser 2^53 : identique sur mobile et sur le web.
  static int _imul(int a, int b) {
    final ah = (a >>> 16) & 0xffff, al = a & 0xffff;
    final bh = (b >>> 16) & 0xffff, bl = b & 0xffff;
    return (al * bl + ((((ah * bl + al * bh) & 0xffff) << 16) & 0xffffffff)) & 0xffffffff;
  }

  double next() {
    _a = (_a + 0x6d2b79f5) & 0xffffffff;
    var t = _imul(_a ^ (_a >>> 15), 1 | _a);
    t = ((t + _imul(t ^ (t >>> 7), 61 | t)) & 0xffffffff) ^ t;
    return ((t ^ (t >>> 14)) & 0xffffffff) / 4294967296.0;
  }
}

class Board {
  Board({required List<String> tiles, required int seed, List<Pos> locks = const []})
      : _rand = Rng(seed),
        _allowed = tiles.map(tileTypes.indexOf).toList() {
    grid = List.generate(boardSize, (_) => List<Tile?>.filled(boardSize, null));
    for (var r = 0; r < boardSize; r++) {
      for (var c = 0; c < boardSize; c++) {
        int type;
        do {
          type = _randomType();
        } while ((c >= 2 && grid[r][c - 1]!.type == type && grid[r][c - 2]!.type == type) ||
            (r >= 2 && grid[r - 1][c]!.type == type && grid[r - 2][c]!.type == type));
        grid[r][c] = _newTile(type);
      }
    }
    for (final p in locks) {
      grid[p.r][p.c]?.lock = 2;
    }
    if (!hasMove()) shuffle();
  }

  factory Board.forLevel(LevelDef l) => Board(tiles: l.tiles, seed: l.seed, locks: l.locks);

  late List<List<Tile?>> grid;
  final Rng _rand;
  final List<int> _allowed;
  int _nextId = 1;

  int _randomType() => _allowed[(_rand.next() * _allowed.length).floor()];
  Tile _newTile(int type, [Special? special]) => Tile(_nextId++, type, special: special);

  static bool adjacent(Pos a, Pos b) => (a.r - b.r).abs() + (a.c - b.c).abs() == 1;

  Tile? at(Pos p) => p.inside ? grid[p.r][p.c] : null;

  bool canSwap(Pos a, Pos b) {
    final ta = at(a), tb = at(b);
    return ta != null && tb != null && ta.lock == null && tb.lock == null && adjacent(a, b);
  }

  /// Groupes alignés (≥ 3), fusionnés quand ils se croisent (formes L / T).
  List<List<Pos>> findGroups() {
    final runs = <List<Pos>>[];
    for (var r = 0; r < boardSize; r++) {
      var c = 0;
      while (c < boardSize) {
        final t = grid[r][c];
        var e = c + 1;
        while (t != null && e < boardSize && grid[r][e]?.type == t.type) {
          e++;
        }
        if (t != null && e - c >= 3) runs.add([for (var i = c; i < e; i++) Pos(r, i)]);
        c = e;
      }
    }
    for (var c = 0; c < boardSize; c++) {
      var r = 0;
      while (r < boardSize) {
        final t = grid[r][c];
        var e = r + 1;
        while (t != null && e < boardSize && grid[e][c]?.type == t.type) {
          e++;
        }
        if (t != null && e - r >= 3) runs.add([for (var i = r; i < e; i++) Pos(i, c)]);
        r = e;
      }
    }
    final groups = <List<Pos>>[];
    for (final run in runs) {
      final keys = run.map((p) => p.key).toSet();
      final hit = groups.where((g) => g.any((p) => keys.contains(p.key))).toList();
      final merged = <int, Pos>{};
      for (final g in hit) {
        for (final p in g) {
          merged[p.key] = p;
        }
      }
      for (final p in run) {
        merged[p.key] = p;
      }
      for (final g in hit) {
        groups.remove(g);
      }
      groups.add(merged.values.toList());
    }
    return groups;
  }

  bool hasMove() {
    for (var r = 0; r < boardSize; r++) {
      for (var c = 0; c < boardSize; c++) {
        final t = grid[r][c];
        if (t?.special == Special.diversif && t?.lock == null) return true;
        for (final d in const [Pos(0, 1), Pos(1, 0)]) {
          final a = Pos(r, c), b = Pos(r + d.r, c + d.c);
          if (!b.inside || !canSwap(a, b)) continue;
          _rawSwap(a, b);
          final ok = findGroups().isNotEmpty;
          _rawSwap(a, b);
          if (ok) return true;
        }
      }
    }
    return false;
  }

  void shuffle() {
    for (var tries = 0; tries < 50; tries++) {
      final free = <Tile>[];
      for (final row in grid) {
        for (final t in row) {
          if (t != null && t.lock == null) free.add(t);
        }
      }
      for (var i = free.length - 1; i > 0; i--) {
        final j = (_rand.next() * (i + 1)).floor();
        final x = free[i];
        free[i] = free[j];
        free[j] = x;
      }
      var k = 0;
      for (var r = 0; r < boardSize; r++) {
        for (var c = 0; c < boardSize; c++) {
          if (grid[r][c] != null && grid[r][c]!.lock == null) grid[r][c] = free[k++];
        }
      }
      if (findGroups().isEmpty && hasMove()) return;
    }
  }

  void _rawSwap(Pos a, Pos b) {
    final t = grid[a.r][a.c];
    grid[a.r][a.c] = grid[b.r][b.c];
    grid[b.r][b.c] = t;
  }

  /// Joue un échange. Renvoie les étapes, ou null si le coup est refusé.
  List<Step>? play(Pos a, Pos b) {
    if (!canSwap(a, b)) return null;
    final ta = at(a)!, tb = at(b)!;
    _rawSwap(a, b);

    if (ta.special == Special.diversif || tb.special == Special.diversif) {
      final color = ta.special == Special.diversif ? tb : ta;
      final self = ta.special == Special.diversif ? b : a;
      final targets = <Pos>[self];
      for (var r = 0; r < boardSize; r++) {
        for (var c = 0; c < boardSize; c++) {
          if (grid[r][c]?.type == color.type) targets.add(Pos(r, c));
        }
      }
      final steps = [_clearAndFall(targets, const [], 1), ..._cascade(2)];
      if (!hasMove()) shuffle();
      return steps;
    }

    if (findGroups().isEmpty) {
      _rawSwap(a, b);
      return null;
    }
    final steps = _cascade(1, [a, b]);
    if (!hasMove()) shuffle();
    return steps;
  }

  List<Step> _cascade(int startMult, [List<Pos> swapped = const []]) {
    final steps = <Step>[];
    var mult = startMult;
    var sw = swapped;
    for (var guard = 0; guard < 30; guard++) {
      final groups = findGroups();
      if (groups.isEmpty) break;
      final toClear = <Pos>[];
      final toCreate = <(Pos, int, Special)>[];
      for (final g in groups) {
        toClear.addAll(g);
        final special = _specialFor(g);
        if (special != null) {
          final at = g.firstWhere((p) => sw.contains(p), orElse: () => g[g.length ~/ 2]);
          toCreate.add((at, grid[at.r][at.c]!.type, special));
        }
      }
      steps.add(_clearAndFall(toClear, toCreate, mult));
      mult++;
      sw = const [];
    }
    return steps;
  }

  Special? _specialFor(List<Pos> g) {
    final rows = g.map((p) => p.r).toSet();
    final cols = g.map((p) => p.c).toSet();
    final straight = rows.length == 1 || cols.length == 1;
    if (straight && g.length >= 5) return Special.diversif;
    if (!straight) return Special.ago;
    if (g.length == 4) return Special.dividende;
    return null;
  }

  Step _clearAndFall(List<Pos> positions, List<(Pos, int, Special)> create, int mult) {
    final step = Step();
    final queue = [...positions];
    final seen = <int>{};
    final createKeys = create.map((x) => x.$1.key).toSet();

    while (queue.isNotEmpty) {
      final p = queue.removeAt(0);
      if (!p.inside || !seen.add(p.key)) continue;
      final t = grid[p.r][p.c];
      if (t == null) continue;
      if (t.lock != null) {
        t.lock = t.lock! - 1;
        final opened = t.lock == 0;
        step.lockHits.add(LockHit(t, p, opened));
        if (opened) t.lock = null;
        continue;
      }
      switch (t.special) {
        case Special.dividende:
          for (var c = 0; c < boardSize; c++) {
            queue.add(Pos(p.r, c));
          }
        case Special.ago:
          for (var dr = -1; dr <= 1; dr++) {
            for (var dc = -1; dc <= 1; dc++) {
              queue.add(Pos(p.r + dr, p.c + dc));
            }
          }
        case Special.diversif:
          for (var r = 0; r < boardSize; r++) {
            for (var c = 0; c < boardSize; c++) {
              if (grid[r][c]?.type == t.type) queue.add(Pos(r, c));
            }
          }
        case null:
          break;
      }
      if (!createKeys.contains(p.key) || t.special != null) {
        step.cleared.add(Placed(t, p));
        grid[p.r][p.c] = null;
      }
    }
    for (final (pos, type, special) in create) {
      final existing = grid[pos.r][pos.c];
      if (existing != null) step.cleared.add(Placed(existing, pos));
      final nt = _newTile(type, special);
      grid[pos.r][pos.c] = nt;
      step.created.add(Placed(nt, pos));
    }
    step.points = step.cleared.length * 10 * mult + step.created.length * 50;

    // Gravité : les cadenas restent fixes, les tuiles passent par-dessus.
    for (var c = 0; c < boardSize; c++) {
      final col = <Tile>[];
      for (var r = boardSize - 1; r >= 0; r--) {
        final t = grid[r][c];
        if (t != null && t.lock == null) col.add(t);
      }
      var i = 0;
      for (var r = boardSize - 1; r >= 0; r--) {
        if (grid[r][c]?.lock != null) continue;
        if (i < col.length) {
          grid[r][c] = col[i++];
        } else {
          final nt = _newTile(_randomType());
          grid[r][c] = nt;
          step.spawned.add(nt);
        }
      }
    }
    step.grid = [for (final row in grid) [...row]];
    return step;
  }
}

// ---------- Objectifs, étoiles, épargne ----------
Progress emptyProgress(LevelDef l) => Progress(movesLeft: l.moves);

Progress applySteps(Progress p, List<Step> steps) {
  var score = p.score, unlocked = p.unlocked;
  final collected = {...p.collected};
  for (final s in steps) {
    score += s.points;
    for (final x in s.cleared) {
      collected.update(x.tile.name, (v) => v + 1, ifAbsent: () => 1);
    }
    unlocked += s.lockHits.where((h) => h.opened).length;
  }
  return Progress(movesLeft: p.movesLeft - 1, score: score, collected: collected, unlocked: unlocked);
}

bool objectiveDone(Objective o, Progress p) => switch (o) {
      CollectObjective(:final tile, :final count) => (p.collected[tile] ?? 0) >= count,
      ScoreObjective(:final target) => p.score >= target,
      UnlockObjective(:final count) => p.unlocked >= count,
    };

bool isWon(LevelDef l, Progress p) => l.objectives.every((o) => objectiveDone(o, p));

int stars(LevelDef l, Progress p) {
  if (!isWon(l, p)) return 0;
  final left = p.movesLeft / l.moves;
  return left >= 0.4 ? 3 : (left >= 0.2 ? 2 : 1);
}

/// GDD 4.3 : 1 500 + 150 par coup restant.
int savingsEarned(Progress p) => 1500 + 150 * p.movesLeft;
