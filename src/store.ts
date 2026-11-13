// Sauvegarde locale v0 (Firestore viendra avec les comptes Firebase).
import levels from './data/levels.json';
import type { LevelDef } from './engine/board';
import snapshot from './data/market-snapshot.json';
import { CITIES } from './data/cities';
import { newCity, scorePaco, type CityState, type Company } from './engine/city';

export const LEVELS = levels as LevelDef[];
export const COMPANIES = snapshot.companies as Company[];
const KEY = 'paco.save.v0';

export interface Save {
  savings: number; // FCFA-jeu
  stars: Record<string, number>; // id niveau -> 0..3
  seenIntro: Record<number, boolean>; // ville -> intro de Paco vue
  city: CityState; // Ma Ville
  days: string[]; // jours joués (AAAA-MM-JJ), pour la régularité
  quiz: Record<number, number>; // ville -> meilleur score au quiz de Paco (0..3)
  cards: string[]; // cartes entreprises gagnées (symboles)
  feedback: Record<number, Feedback>; // avis des testeurs, par ville
}

export interface Feedback {
  compris: 1 | 2 | 3;
  amusant: 1 | 2 | 3;
  changer: string;
  at: string;
}

const fresh = (): Save => ({ savings: 10000, stars: {}, seenIntro: {}, city: newCity(COMPANIES), days: [], quiz: {}, cards: [], feedback: {} });

export function load(): Save {
  try {
    return { ...fresh(), ...JSON.parse(localStorage.getItem(KEY) ?? '{}') };
  } catch {
    return fresh();
  }
}

export function persist(s: Save) {
  try {
    localStorage.setItem(KEY, JSON.stringify(s));
  } catch {
    /* stockage indisponible : on continue sans sauvegarde */
  }
}

export function cityStars(s: Save, city: number) {
  return LEVELS.filter((l) => l.city === city).reduce((n, l) => n + (s.stars[l.id] ?? 0), 0);
}

/** GDD §7 : ville suivante débloquée avec ≥ 5 étoiles sur 9 + quiz de Paco réussi (2/3). */
export function cityValidated(s: Save, city: number) {
  return cityStars(s, city) >= 5 && (s.quiz[city] ?? 0) >= 2;
}

export function cityUnlocked(s: Save, city: number) {
  return city === 1 || cityValidated(s, city - 1);
}

export function levelUnlocked(s: Save, l: LevelDef) {
  if (!cityUnlocked(s, l.city)) return false;
  if (l.index === 1) return true;
  return (s.stars[`c${l.city}-l${l.index - 1}`] ?? 0) > 0;
}

export const GOAT_SCORE = 700;

export function title(s: Save) {
  const done = Array.from({ length: 15 }, (_, i) => i + 1).filter((c) => cityValidated(s, c)).length;
  // GDD §7 : GOAT = ville 15 validée + Score PACO ≥ 700.
  if (done >= 15 && scorePaco(s.city, COMPANIES, s.days.length) >= GOAT_SCORE) return 'GOAT de la BRVM';
  if (done >= 15) return 'Investisseur Patient';
  if (done >= 9) return 'Investisseur Patient';
  if (done >= 4) return 'Actionnaire Moyen';
  return 'Actionnaire Débutant';
}

export function citiesDone(s: Save) {
  return CITIES.filter((c) => cityValidated(s, c.n)).length;
}

/** Cartes gagnées en gardant une part au moins 10 séances (GDD §5). */
export function cardsFromHoldings(s: Save): string[] {
  const won = Object.entries(s.city.holdings)
    .filter(([, h]) => s.city.seance - h.since >= 10)
    .map(([sym]) => sym);
  return [...new Set([...s.cards, ...won])];
}

/** Carte offerte pour un quiz sans faute : une entreprise du pays de la ville, sinon une entreprise débloquée. */
export function quizRewardCard(s: Save, city: number): string | null {
  const country = CITIES[city - 1].country;
  const pool = COMPANIES.filter((c) => !s.cards.includes(c.symbol));
  const local = pool.filter((c) => c.country === country);
  const list = local.length ? local : pool.filter((c) => unlockedCompanies(s).includes(c));
  if (!list.length) return null;
  return list[(s.days.length + city * 7) % list.length].symbol;
}

/** Les entreprises des pays dont au moins une ville est débloquée. */
export function unlockedCompanies(s: Save) {
  const countries = new Set(CITIES.filter((c) => cityUnlocked(s, c.n)).map((c) => c.country));
  return COMPANIES.filter((c) => countries.has(c.country));
}

export function today() {
  return new Date().toISOString().slice(0, 10);
}

/** Remplace les cours de référence par l'instantané du jour (Firestore market_snapshots/latest). */
export function applyMarket(companies: Company[]) {
  const valid = companies.filter((c) => c && c.symbol && c.price > 0);
  if (valid.length < 10) return false; // instantané incomplet : on garde l'actuel
  COMPANIES.splice(0, COMPANIES.length, ...valid);
  return true;
}

/** Avancement d'une sauvegarde, pour choisir entre la version locale et la version en ligne. */
export function progressOf(s: Save) {
  return Object.values(s.stars).reduce((a, b) => a + b, 0) * 1000 + s.city.seance;
}
