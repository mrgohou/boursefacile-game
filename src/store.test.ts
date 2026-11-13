import { describe, expect, it } from 'vitest';
import { COMPANIES, cityUnlocked, title, type Save } from './store';
import { buy, newCity } from './engine/city';

const base = (): Save => ({ savings: 0, stars: {}, seenIntro: {}, city: newCity(COMPANIES), days: [], quiz: {}, cards: [], feedback: {} });
const allDone = (s: Save) => {
  for (let c = 1; c <= 15; c++) {
    for (let l = 1; l <= 3; l++) s.stars[`c${c}-l${l}`] = 3;
    s.quiz[c] = 3;
  }
  return s;
};

describe('progression', () => {
  it('ville suivante : 5 étoiles ET quiz réussi', () => {
    const s = base();
    s.stars = { 'c1-l1': 3, 'c1-l2': 2 };
    expect(cityUnlocked(s, 2)).toBe(false);
    s.quiz[1] = 2;
    expect(cityUnlocked(s, 2)).toBe(true);
  });
  it('GOAT seulement avec un Score PACO ≥ 700', () => {
    const s = allDone(base());
    expect(title(s)).toBe('Investisseur Patient');
    let city = s.city;
    for (const sym of ['ETIT', 'SNTS', 'FTSC', 'CIEC', 'CFAC', 'PALC', 'SDSC']) city = buy(city, sym, 1, 1e6)!.state;
    s.city = { ...city, dividends: 50000 };
    s.days = ['1', '2', '3', '4', '5', '6', '7'];
    expect(title(s)).toBe('GOAT de la BRVM');
  });
});
