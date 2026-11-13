import { describe, expect, it } from 'vitest';
import { Board, SIZE, TILE_TYPES, applySteps, emptyProgress, isWon, stars, savingsEarned, type LevelDef } from './board';
import levels from '../data/levels.json';

const base: LevelDef = {
  id: 't',
  city: 1,
  index: 1,
  moves: 20,
  tiles: [...TILE_TYPES],
  objectives: [{ kind: 'score', target: 100 }],
  seed: 42,
  pacoBefore: '',
  pacoHint: '',
};

describe('Board', () => {
  it('démarre sans alignement et avec au moins un coup possible', () => {
    for (let seed = 1; seed < 40; seed++) {
      const b = new Board({ ...base, seed });
      expect(b.findGroups()).toHaveLength(0);
      expect(b.hasMove()).toBe(true);
      expect(b.grid.flat().every(Boolean)).toBe(true);
    }
  });

  it('refuse un échange qui ne crée pas d alignement et garde la grille intacte', () => {
    const b = new Board(base);
    const before = JSON.stringify(b.grid);
    let refused = false;
    for (let r = 0; r < SIZE && !refused; r++)
      for (let c = 0; c < SIZE - 1 && !refused; c++) {
        const copy = JSON.stringify(b.grid);
        const steps = b.play({ r, c }, { r, c: c + 1 });
        if (steps === null) {
          refused = true;
          expect(JSON.stringify(b.grid)).toBe(copy);
        } else break;
      }
    expect(refused).toBe(true);
    expect(before).toBeTruthy();
  });

  it('un coup valide marque des points et laisse une grille pleine', () => {
    const b = new Board(base);
    let steps = null;
    outer: for (let r = 0; r < SIZE; r++)
      for (let c = 0; c < SIZE; c++)
        for (const [dr, dc] of [
          [0, 1],
          [1, 0],
        ]) {
          if (r + dr >= SIZE || c + dc >= SIZE) continue;
          steps = b.play({ r, c }, { r: r + dr, c: c + dc });
          if (steps) break outer;
        }
    expect(steps).not.toBeNull();
    const p = applySteps(emptyProgress(base), steps!);
    expect(p.score).toBeGreaterThan(0);
    expect(p.movesLeft).toBe(19);
    expect(b.grid.flat().every(Boolean)).toBe(true);
    expect(b.findGroups()).toHaveLength(0);
  });

  it('crée une tuile Dividende pour 4 alignées', () => {
    const b = new Board(base);
    // Ligne 0 : A A x A, avec A sous x pour compléter par échange vertical.
    const g = b.grid;
    for (let c = 0; c < SIZE; c++) for (let r = 0; r < SIZE; r++) g[r][c]!.type = (r * 2 + c * 3) % 5;
    g[0][0]!.type = 5; g[0][1]!.type = 5; g[0][2]!.type = 1; g[0][3]!.type = 5; g[1][2]!.type = 5;
    g[0][4]!.type = 2; g[2][2]!.type = 3;
    const steps = b.play({ r: 0, c: 2 }, { r: 1, c: 2 });
    expect(steps).not.toBeNull();
    expect(steps![0].created.some((x) => x.tile.special === 'dividende')).toBe(true);
  });

  it('un cadenas s ouvre en 2 touches et ne peut pas être échangé', () => {
    const b = new Board({ ...base, locks: [[3, 3]] });
    expect(b.grid[3][3]!.lock).toBe(2);
    expect(b.canSwap({ r: 3, c: 3 }, { r: 3, c: 4 })).toBe(false);
  });

  it('étoiles et épargne suivent le GDD', () => {
    const p = { movesLeft: 10, score: 500, collected: {}, unlocked: 0 };
    expect(isWon(base, p)).toBe(true);
    expect(stars(base, p)).toBe(3);
    expect(savingsEarned(p)).toBe(3000);
  });
});

describe('levels.json', () => {
  it('contient 45 niveaux (15 villes × 3), tous jouables', () => {
    expect(levels).toHaveLength(45);
    for (const l of levels as LevelDef[]) {
      const b = new Board(l);
      expect(b.hasMove()).toBe(true);
      expect(l.pacoBefore.length).toBeGreaterThan(0);
    }
  });
});
