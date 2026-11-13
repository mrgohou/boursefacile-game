import { describe, expect, it } from 'vitest';
import { QUIZ } from './quiz';

describe('quiz de Paco', () => {
  it('3 questions par ville, réponses distinctes, explication présente', () => {
    for (let c = 1; c <= 15; c++) {
      expect(QUIZ[c], `ville ${c}`).toHaveLength(3);
      for (const q of QUIZ[c]) {
        expect(new Set(q.a).size).toBe(q.a.length);
        expect(q.a.length).toBeGreaterThanOrEqual(2);
        expect(q.why.length).toBeGreaterThan(10);
      }
    }
  });
  it("Paco ne donne jamais d'ordre d'achat ou de vente", () => {
    const all = Object.values(QUIZ).flat().map((q) => q.why).join(' ');
    expect(all).not.toMatch(/\b(achète|vends)\b/i);
  });
});
