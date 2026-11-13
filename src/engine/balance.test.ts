// Équilibrage : un joueur-robot « moyen » (coup au hasard parmi les coups valides) joue chaque niveau.
// But v0 : chaque niveau doit rester faisable (taux de réussite du robot ≥ 25 %).
import { describe, expect, it } from 'vitest';
import { Board, SIZE, applySteps, emptyProgress, isWon, rng, type LevelDef } from './board';
import levels from '../data/levels.json';

function playOnce(level: LevelDef, seed: number) {
  const b = new Board({ ...level, seed: level.seed + seed });
  const r = rng(seed);
  let p = emptyProgress(level);
  while (p.movesLeft > 0 && !isWon(level, p)) {
    const moves: [number, number, number, number][] = [];
    for (let i = 0; i < SIZE; i++)
      for (let j = 0; j < SIZE; j++) {
        if (j + 1 < SIZE) moves.push([i, j, i, j + 1]);
        if (i + 1 < SIZE) moves.push([i, j, i + 1, j]);
      }
    for (let k = moves.length - 1; k > 0; k--) {
      const x = Math.floor(r() * (k + 1));
      [moves[k], moves[x]] = [moves[x], moves[k]];
    }
    let played = false;
    for (const [a, b2, c, d] of moves) {
      const steps = b.play({ r: a, c: b2 }, { r: c, c: d });
      if (steps) {
        p = applySteps(p, steps);
        played = true;
        break;
      }
    }
    if (!played) b.shuffle();
  }
  return isWon(level, p);
}

describe('équilibrage des 45 niveaux', () => {
  it('chaque niveau est faisable par un robot moyen', () => {
    const report: string[] = [];
    const rates: [string, number][] = [];
    for (const level of levels as LevelDef[]) {
      let wins = 0;
      const N = 30;
      for (let s = 1; s <= N; s++) if (playOnce(level, s)) wins++;
      report.push(`${level.id}: ${Math.round((wins / N) * 100)}%`);
      rates.push([level.id, wins / N]);
    }
    console.log(report.join('  '));
    for (const [id, rate] of rates) expect(rate, id).toBeGreaterThanOrEqual(0.25);
  }, 120000);
});
