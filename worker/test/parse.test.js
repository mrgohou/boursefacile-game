import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { buildSnapshot, parseIndices, parseQuotes, publicationDate } from '../src/parse.js';
import { toValue } from '../src/firestore.js';
import facts from '../src/facts.json';

const actions = readFileSync(new URL('./actions.html', import.meta.url), 'utf8');
const home = readFileSync(new URL('./home.html', import.meta.url), 'utf8');

describe('worker paco-market', () => {
  it('lit les 48 cotations officielles', () => {
    const q = parseQuotes(actions);
    expect(q).toHaveLength(48);
    expect(q[0]).toMatchObject({ symbol: 'ABJC', close: 3400, previousClose: 3400 });
  });
  it('lit la date et les indices', () => {
    expect(publicationDate(home).toISOString()).toBe('2026-11-10T22:45:00.000Z');
    expect(parseIndices(home)['BRVM-C']).toEqual({ value: 512.81, change: -1.74 });
  });
  it('construit un instantané complet, PER recalculé', () => {
    const s = buildSnapshot(actions, home, facts);
    expect(s.sessionDate).toBe('2026-11-10');
    expect(s.companies).toHaveLength(48);
    const sn = s.companies.find((c) => c.symbol === 'SNTS');
    expect(sn.per).toBeCloseTo(sn.price / 185, 1);
    expect(s.companies.find((c) => c.symbol === 'ORAC').per).toBeNull();
  });
  it('refuse une page tronquée', () => {
    expect(() => parseQuotes('<table><tr><td>X</td></tr></table>')).toThrow();
  });
  it('encode pour Firestore', () => {
    expect(toValue({ a: 1, b: 1.5, c: null, d: ['x'] })).toEqual({
      mapValue: { fields: { a: { integerValue: '1' }, b: { doubleValue: 1.5 }, c: { nullValue: null }, d: { arrayValue: { values: [{ stringValue: 'x' }] } } } },
    });
  });
});
