import { describe, expect, it } from 'vitest';
import snapshot from '../data/market-snapshot.json';
import { advance, buildingLevel, buy, buyCost, fee, newCity, scorePaco, sell, type Company } from './city';

const companies = snapshot.companies as Company[];
const SNTS = companies.find((c) => c.symbol === 'SNTS')!;

describe('Ma Ville', () => {
  it('utilise les vrais cours (Sonatel 4 110 le 13/11/2026)', () => {
    expect(newCity(companies).prices.SNTS).toBe(4110);
    expect(companies).toHaveLength(45);
  });

  it('frais de 1 % avec un minimum de 50', () => {
    expect(fee(1000)).toBe(50);
    expect(fee(42950)).toBe(430);
  });

  it('achète et vend avec frais, et affiche la plus-value', () => {
    const s0 = newCity(companies);
    const b = buy(s0, 'SNTS', 2, 10000)!;
    expect(b.cash).toBe(10000 - buyCost(s0, 'SNTS', 2));
    expect(buy(s0, 'SLBC', 1, 10000)).toBeNull(); // trop cher pour 10 000
    const higher = { ...b.state, prices: { ...b.state.prices, SNTS: 5000 } };
    const s = sell(higher, 'SNTS', 2, b.cash)!;
    expect(s.gain).toBeGreaterThan(0);
    expect(s.state.holdings.SNTS).toBeUndefined();
    expect(s.state.quickSales).toBe(1); // vendu trop vite
  });

  it('le dividende de l’AGO va seulement aux parts gardées avant le sablier', () => {
    let s = buy(newCity(companies), 'SNTS', 10, 100000)!.state;
    let gained = 0;
    for (let i = 0; i < 10; i++) {
      const r = advance(s, companies, 1);
      s = r.state;
      gained += r.cashGained;
    }
    expect(gained).toBe(Math.round(SNTS.lastDividend! * 10));
    // Achat à 1 séance de l'AGO : pas de dividende.
    let t = newCity(companies);
    for (let i = 0; i < 9; i++) t = advance(t, companies, 2).state;
    t = buy(t, 'SNTS', 10, 100000)!.state;
    expect(advance(t, companies, 2).cashGained).toBe(0);
  });

  it('les prix restent à ±15 % du vrai cours et le bâtiment grandit avec le temps', () => {
    let s = buy(newCity(companies), 'ETIT', 5, 10000)!.state;
    for (let i = 0; i < 60; i++) s = advance(s, companies, 3).state;
    for (const c of companies) {
      expect(s.prices[c.symbol]).toBeGreaterThanOrEqual(Math.floor(c.price * 0.85));
      expect(s.prices[c.symbol]).toBeLessThanOrEqual(Math.ceil(c.price * 1.15));
    }
    expect(buildingLevel(s, 'ETIT')).toBe(4);
  });

  it('le Score PACO récompense la diversification', () => {
    const s0 = newCity(companies);
    const one = buy(s0, 'ETIT', 30, 100000)!.state;
    let many = s0;
    for (const sym of ['ETIT', 'SNTS', 'FTSC', 'CIEC', 'CFAC', 'PALC']) many = buy(many, sym, 1, 100000)!.state;
    expect(scorePaco(many, companies, 3)).toBeGreaterThan(scorePaco(one, companies, 3));
  });
});
