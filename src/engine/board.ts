// Moteur du puzzle PACO Bourse (match-3). Logique pure, sans rendu : testable.

export const SIZE = 7;

/** 6 tuiles de base, liées aux secteurs de la BRVM. */
export const TILE_TYPES = ['cacao', 'telephone', 'billet', 'bidon', 'ampoule', 'engrenage'] as const;
export type TileType = (typeof TILE_TYPES)[number];

/** Spéciales : noms = notions de bourse. */
export type Special = 'dividende' | 'ago' | 'diversif';

export interface Tile {
  id: number;
  type: number; // index dans TILE_TYPES
  special?: Special;
  lock?: number; // cadenas « Frais » : coups restants pour l'ouvrir
}

export type Cell = Tile | null;
export type Grid = Cell[][]; // grid[row][col]

export type Objective =
  | { kind: 'collect'; tile: TileType; count: number }
  | { kind: 'score'; target: number }
  | { kind: 'unlock'; count: number };

export interface LevelDef {
  id: string;
  city: number; // 1..15
  index: number; // 1..3 dans la ville
  moves: number;
  tiles: TileType[]; // tuiles autorisées
  objectives: Objective[];
  locks?: [number, number][]; // positions [ligne, colonne] des cadenas
  seed: number;
  pacoBefore: string;
  pacoHint: string;
}

export interface Pos {
  r: number;
  c: number;
}

export interface Step {
  /** tuiles retirées à cette étape */
  cleared: { tile: Tile; r: number; c: number }[];
  /** spéciales créées à cette étape */
  created: { tile: Tile; r: number; c: number }[];
  /** cadenas touchés (encore fermés ou ouverts) */
  lockHits: { tile: Tile; r: number; c: number; opened: boolean }[];
  /** grille après gravité et remplissage */
  grid: Grid;
  /** nouvelles tuiles apparues en haut */
  spawned: Tile[];
  points: number;
}

export interface Progress {
  movesLeft: number;
  score: number;
  collected: Record<string, number>;
  unlocked: number;
}

// ---------- Hasard reproductible ----------
export function rng(seed: number) {
  let a = seed >>> 0;
  return () => {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export class Board {
  grid: Grid;
  private nextId = 1;
  private rand: () => number;
  private allowed: number[];

  constructor(level: Pick<LevelDef, 'tiles' | 'seed' | 'locks'>) {
    this.rand = rng(level.seed);
    this.allowed = level.tiles.map((t) => TILE_TYPES.indexOf(t));
    this.grid = [];
    for (let r = 0; r < SIZE; r++) {
      const row: Cell[] = [];
      for (let c = 0; c < SIZE; c++) {
        let type: number;
        // Pas d'alignement au départ.
        do {
          type = this.randomType();
        } while (
          (c >= 2 && row[c - 1]!.type === type && row[c - 2]!.type === type) ||
          (r >= 2 && this.grid[r - 1][c]!.type === type && this.grid[r - 2][c]!.type === type)
        );
        row.push(this.newTile(type));
      }
      this.grid.push(row);
    }
    for (const [r, c] of level.locks ?? []) {
      const t = this.grid[r]?.[c];
      if (t) t.lock = 2;
    }
    if (!this.hasMove()) this.shuffle();
  }

  private randomType() {
    return this.allowed[Math.floor(this.rand() * this.allowed.length)];
  }

  private newTile(type: number, special?: Special): Tile {
    const t: Tile = { id: this.nextId++, type };
    if (special) t.special = special;
    return t;
  }

  static adjacent(a: Pos, b: Pos) {
    return Math.abs(a.r - b.r) + Math.abs(a.c - b.c) === 1;
  }

  at(p: Pos): Cell {
    return this.grid[p.r]?.[p.c] ?? null;
  }

  canSwap(a: Pos, b: Pos) {
    const ta = this.at(a);
    const tb = this.at(b);
    return !!ta && !!tb && !ta.lock && !tb.lock && Board.adjacent(a, b);
  }

  /** Les groupes alignés (≥ 3) de la grille. */
  findGroups(): Pos[][] {
    const runs: Pos[][] = [];
    for (let r = 0; r < SIZE; r++) {
      let c = 0;
      while (c < SIZE) {
        const t = this.grid[r][c];
        let e = c + 1;
        while (t && e < SIZE && this.grid[r][e]?.type === t.type) e++;
        if (t && e - c >= 3) runs.push(Array.from({ length: e - c }, (_, i) => ({ r, c: c + i })));
        c = e;
      }
    }
    for (let c = 0; c < SIZE; c++) {
      let r = 0;
      while (r < SIZE) {
        const t = this.grid[r][c];
        let e = r + 1;
        while (t && e < SIZE && this.grid[e][c]?.type === t.type) e++;
        if (t && e - r >= 3) runs.push(Array.from({ length: e - r }, (_, i) => ({ r: r + i, c })));
        r = e;
      }
    }
    // Fusion des alignements qui se croisent (formes L / T).
    const groups: Pos[][] = [];
    const key = (p: Pos) => p.r * SIZE + p.c;
    for (const run of runs) {
      const keys = new Set(run.map(key));
      const hit = groups.filter((g) => g.some((p) => keys.has(key(p))));
      const merged = new Map<number, Pos>();
      for (const g of hit) for (const p of g) merged.set(key(p), p);
      for (const p of run) merged.set(key(p), p);
      for (const g of hit) groups.splice(groups.indexOf(g), 1);
      groups.push([...merged.values()]);
    }
    return groups;
  }

  hasMove(): boolean {
    for (let r = 0; r < SIZE; r++)
      for (let c = 0; c < SIZE; c++) {
        const t = this.grid[r][c];
        if (t?.special === 'diversif' && !t.lock) return true;
        for (const [dr, dc] of [
          [0, 1],
          [1, 0],
        ]) {
          const b = { r: r + dr, c: c + dc };
          if (b.r >= SIZE || b.c >= SIZE || !this.canSwap({ r, c }, b)) continue;
          this.rawSwap({ r, c }, b);
          const ok = this.findGroups().length > 0;
          this.rawSwap({ r, c }, b);
          if (ok) return true;
        }
      }
    return false;
  }

  shuffle() {
    for (let tries = 0; tries < 50; tries++) {
      const free: Tile[] = [];
      for (const row of this.grid) for (const t of row) if (t && !t.lock) free.push(t);
      for (let i = free.length - 1; i > 0; i--) {
        const j = Math.floor(this.rand() * (i + 1));
        [free[i], free[j]] = [free[j], free[i]];
      }
      let k = 0;
      for (let r = 0; r < SIZE; r++)
        for (let c = 0; c < SIZE; c++) if (this.grid[r][c] && !this.grid[r][c]!.lock) this.grid[r][c] = free[k++];
      if (this.findGroups().length === 0 && this.hasMove()) return;
    }
  }

  private rawSwap(a: Pos, b: Pos) {
    const t = this.grid[a.r][a.c];
    this.grid[a.r][a.c] = this.grid[b.r][b.c];
    this.grid[b.r][b.c] = t;
  }

  /**
   * Joue un échange. Renvoie les étapes (pour l'animation) ou null si le coup est refusé.
   */
  play(a: Pos, b: Pos): Step[] | null {
    if (!this.canSwap(a, b)) return null;
    const ta = this.at(a)!;
    const tb = this.at(b)!;
    this.rawSwap(a, b);

    // Diversif échangée : retire toutes les tuiles du type de l'autre tuile.
    if (ta.special === 'diversif' || tb.special === 'diversif') {
      const color = ta.special === 'diversif' ? tb : ta;
      const self = ta.special === 'diversif' ? b : a; // position actuelle de la Diversif
      const targets: Pos[] = [self];
      for (let r = 0; r < SIZE; r++)
        for (let c = 0; c < SIZE; c++) if (this.grid[r][c]?.type === color.type) targets.push({ r, c });
      const steps = [this.clearAndFall(targets, [], 1)];
      steps.push(...this.cascade(2));
      if (!this.hasMove()) this.shuffle();
      return steps;
    }

    const groups = this.findGroups();
    if (groups.length === 0) {
      this.rawSwap(a, b);
      return null;
    }
    const steps = this.cascade(1, [a, b]);
    if (!this.hasMove()) this.shuffle();
    return steps;
  }

  private cascade(startMult: number, swapped: Pos[] = []): Step[] {
    const steps: Step[] = [];
    let mult = startMult;
    for (let guard = 0; guard < 30; guard++) {
      const groups = this.findGroups();
      if (groups.length === 0) break;
      const toClear: Pos[] = [];
      const toCreate: { pos: Pos; type: number; special: Special }[] = [];
      for (const g of groups) {
        toClear.push(...g);
        const special = this.specialFor(g);
        if (special) {
          const at = g.find((p) => swapped.some((s) => s.r === p.r && s.c === p.c)) ?? g[Math.floor(g.length / 2)];
          toCreate.push({ pos: at, type: this.grid[at.r][at.c]!.type, special });
        }
      }
      steps.push(this.clearAndFall(toClear, toCreate, mult));
      mult++;
      swapped = [];
    }
    return steps;
  }

  private specialFor(g: Pos[]): Special | undefined {
    const rows = new Set(g.map((p) => p.r));
    const cols = new Set(g.map((p) => p.c));
    const straight = rows.size === 1 || cols.size === 1;
    if (straight && g.length >= 5) return 'diversif';
    if (!straight) return 'ago';
    if (g.length === 4) return 'dividende';
    return undefined;
  }

  /** Retire des positions (avec réaction en chaîne des spéciales), fait tomber, remplit. */
  private clearAndFall(positions: Pos[], create: { pos: Pos; type: number; special: Special }[], mult: number): Step {
    const step: Step = { cleared: [], created: [], lockHits: [], grid: [], spawned: [], points: 0 };
    const key = (p: Pos) => p.r * SIZE + p.c;
    const queue = [...positions];
    const seen = new Set<number>();
    const createKeys = new Set(create.map((x) => key(x.pos)));

    while (queue.length) {
      const p = queue.shift()!;
      if (p.r < 0 || p.c < 0 || p.r >= SIZE || p.c >= SIZE) continue;
      const k = key(p);
      if (seen.has(k)) continue;
      seen.add(k);
      const t = this.grid[p.r][p.c];
      if (!t) continue;
      if (t.lock) {
        t.lock--;
        step.lockHits.push({ tile: t, r: p.r, c: p.c, opened: t.lock === 0 });
        if (t.lock === 0) delete t.lock;
        continue; // la tuile reste ; le cadenas s'use
      }
      // Déclenchement d'une spéciale existante.
      if (t.special === 'dividende') for (let c = 0; c < SIZE; c++) queue.push({ r: p.r, c });
      if (t.special === 'ago')
        for (let dr = -1; dr <= 1; dr++) for (let dc = -1; dc <= 1; dc++) queue.push({ r: p.r + dr, c: p.c + dc });
      if (t.special === 'diversif')
        for (let r = 0; r < SIZE; r++)
          for (let c = 0; c < SIZE; c++) if (this.grid[r][c]?.type === t.type) queue.push({ r, c });
      if (!createKeys.has(k) || t.special) {
        step.cleared.push({ tile: t, r: p.r, c: p.c });
        this.grid[p.r][p.c] = null;
      }
    }
    for (const x of create) {
      const existing = this.grid[x.pos.r][x.pos.c];
      if (existing) step.cleared.push({ tile: existing, r: x.pos.r, c: x.pos.c });
      const nt = this.newTile(x.type, x.special);
      this.grid[x.pos.r][x.pos.c] = nt;
      step.created.push({ tile: nt, r: x.pos.r, c: x.pos.c });
    }
    step.points = step.cleared.length * 10 * mult + step.created.length * 50;

    // Gravité (les cadenas restent fixes, les tuiles passent par-dessus : simplification v0).
    for (let c = 0; c < SIZE; c++) {
      const col: Tile[] = [];
      for (let r = SIZE - 1; r >= 0; r--) if (this.grid[r][c] && !this.grid[r][c]!.lock) col.push(this.grid[r][c]!);
      let i = 0;
      for (let r = SIZE - 1; r >= 0; r--) {
        if (this.grid[r][c]?.lock) continue;
        if (i < col.length) this.grid[r][c] = col[i++];
        else {
          const nt = this.newTile(this.randomType());
          this.grid[r][c] = nt;
          step.spawned.push(nt);
        }
      }
    }
    step.grid = this.grid.map((row) => [...row]);
    return step;
  }
}

// ---------- Objectifs, étoiles, épargne ----------
export function emptyProgress(level: LevelDef): Progress {
  return { movesLeft: level.moves, score: 0, collected: {}, unlocked: 0 };
}

export function applySteps(p: Progress, steps: Step[]): Progress {
  const next = { ...p, collected: { ...p.collected }, movesLeft: p.movesLeft - 1 };
  for (const s of steps) {
    next.score += s.points;
    for (const x of s.cleared) {
      const name = TILE_TYPES[x.tile.type];
      next.collected[name] = (next.collected[name] ?? 0) + 1;
    }
    next.unlocked += s.lockHits.filter((h) => h.opened).length;
  }
  return next;
}

export function objectiveDone(o: Objective, p: Progress) {
  if (o.kind === 'collect') return (p.collected[o.tile] ?? 0) >= o.count;
  if (o.kind === 'score') return p.score >= o.target;
  return p.unlocked >= o.count;
}

export function isWon(level: LevelDef, p: Progress) {
  return level.objectives.every((o) => objectiveDone(o, p));
}

export function stars(level: LevelDef, p: Progress) {
  if (!isWon(level, p)) return 0;
  const left = p.movesLeft / level.moves;
  return left >= 0.4 ? 3 : left >= 0.2 ? 2 : 1;
}

/** GDD 4.3 : 1 500 + 150 par coup restant. */
export function savingsEarned(p: Progress) {
  return 1500 + 150 * p.movesLeft;
}
