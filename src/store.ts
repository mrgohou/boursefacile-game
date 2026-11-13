// Sauvegarde locale v0 (Firestore viendra avec les comptes Firebase).
import levels from './data/levels.json';
import type { LevelDef } from './engine/board';
import snapshot from './data/market-snapshot.json';
import { CITIES } from './data/cities';
import { newCity, type CityState, type Company } from './engine/city';

export const LEVELS = levels as LevelDef[];
export const COMPANIES = snapshot.companies as Company[];
const KEY = 'paco.save.v0';

export interface Save {
  savings: number; // FCFA-jeu
  stars: Record<string, number>; // id niveau -> 0..3
  seenIntro: Record<number, boolean>; // ville -> intro de Paco vue
  city: CityState; // Ma Ville
  days: string[]; // jours joués (AAAA-MM-JJ), pour la régularité
}

const fresh = (): Save => ({ savings: 10000, stars: {}, seenIntro: {}, city: newCity(COMPANIES), days: [] });

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

/** GDD §7 : ville suivante débloquée avec ≥ 5 étoiles sur 9 (le quiz de Paco arrive à l'étape suivante). */
export function cityUnlocked(s: Save, city: number) {
  return city === 1 || cityStars(s, city - 1) >= 5;
}

export function levelUnlocked(s: Save, l: LevelDef) {
  if (!cityUnlocked(s, l.city)) return false;
  if (l.index === 1) return true;
  return (s.stars[`c${l.city}-l${l.index - 1}`] ?? 0) > 0;
}

export function title(s: Save) {
  const done = Array.from({ length: 15 }, (_, i) => i + 1).filter((c) => cityStars(s, c) >= 5).length;
  if (done >= 15) return 'GOAT de la BRVM';
  if (done >= 9) return 'Investisseur Patient';
  if (done >= 4) return 'Actionnaire Moyen';
  return 'Actionnaire Débutant';
}

export function citiesDone(s: Save) {
  return CITIES.filter((c) => cityStars(s, c.n) >= 5).length;
}

/** Les entreprises des pays dont au moins une ville est débloquée. */
export function unlockedCompanies(s: Save) {
  const countries = new Set(CITIES.filter((c) => cityUnlocked(s, c.n)).map((c) => c.country));
  return COMPANIES.filter((c) => countries.has(c.country));
}

export function today() {
  return new Date().toISOString().slice(0, 10);
}
