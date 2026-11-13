// Ma Ville : la simulation d'investissement (GDD §4, §5, §6). Logique pure, testable.
import { rng } from './board';

export type Family = 'banque' | 'telecom' | 'agro' | 'distribution' | 'industrie' | 'energie' | 'services';

export const FAMILIES: Record<Family, { label: string; tile: string; color: string }> = {
  banque: { label: 'Banque', tile: 'billet', color: '#8fd46e' },
  telecom: { label: 'Télécoms', tile: 'telephone', color: '#6cc3ef' },
  agro: { label: 'Agro', tile: 'cacao', color: '#f3b54a' },
  distribution: { label: 'Distribution', tile: 'bidon', color: '#f28b82' },
  industrie: { label: 'Industrie', tile: 'engrenage', color: '#b49ae8' },
  energie: { label: 'Énergie et eau', tile: 'ampoule', color: '#ffcf33' },
  services: { label: 'Services', tile: 'ago', color: '#9fb8ad' },
};

export interface Company {
  symbol: string;
  name: string;
  sector: string;
  family: Family;
  country: string;
  price: number; // vrai cours de clôture (référence)
  previousClose: number | null;
  eps: number | null;
  per: number | null;
  lastDividend: number | null;
  dividendYield: number | null;
}

export interface Holding {
  qty: number;
  cost: number; // total payé, frais compris
  since: number; // séance d'achat de la première part encore détenue
}

export interface EventCard {
  id: string;
  family: Family | null; // null = tout le marché
  move: number; // variation appliquée ce jour (ex. 0.04 = +4 %)
  text: string;
}

export interface CityState {
  seance: number;
  prices: Record<string, number>;
  holdings: Record<string, Holding>;
  dividends: number; // total encaissé
  invested: number; // total des achats (frais compris)
  quickSales: number; // ventes de parts gardées < 5 séances
  lastEvent: EventCard | null;
  lastAgo: { seance: number; amount: number } | null;
}

export const FEE_RATE = 0.01;
export const FEE_MIN = 50;
export const AGO_EVERY = 10;
export const HOURGLASS = 3; // il faut détenir la part 3 séances avant l'AGO

export const EVENTS: EventCard[] = [
  { id: 'cacao', family: 'agro', move: 0.05, text: 'Bonne récolte de cacao : l’agro-industrie sourit.' },
  { id: 'pluie', family: 'agro', move: -0.04, text: 'Pluies trop fortes : les récoltes prennent du retard.' },
  { id: 'reseau', family: 'telecom', move: -0.04, text: 'Panne réseau géante : les télécoms tremblent.' },
  { id: 'abonnes', family: 'telecom', move: 0.04, text: 'Des millions de nouveaux abonnés au mobile money !' },
  { id: 'credit', family: 'banque', move: 0.03, text: 'Les banques prêtent plus aux entreprises.' },
  { id: 'impayes', family: 'banque', move: -0.03, text: 'Des clients remboursent en retard : prudence chez les banques.' },
  { id: 'usine', family: 'industrie', move: 0.05, text: 'Une nouvelle usine ouvre : l’industrie embauche.' },
  { id: 'panne', family: 'industrie', move: -0.04, text: 'Pénurie de pièces : les machines ralentissent.' },
  { id: 'carburant', family: 'distribution', move: -0.03, text: 'Le prix du carburant monte : les distributeurs gagnent moins.' },
  { id: 'fetes', family: 'distribution', move: 0.04, text: 'Période de fêtes : les magasins sont pleins.' },
  { id: 'barrage', family: 'energie', move: 0.03, text: 'Un nouveau barrage produit plus d’électricité.' },
  { id: 'calme', family: null, move: 0.0, text: 'Journée calme à la BRVM. Rien ne presse.' },
  { id: 'optimisme', family: null, move: 0.015, text: 'Bonne humeur générale : la BRVM-C monte un peu.' },
  { id: 'prudence', family: null, move: -0.015, text: 'Les investisseurs hésitent : la BRVM-C baisse un peu.' },
];

export function newCity(companies: Company[]): CityState {
  return {
    seance: 0,
    prices: Object.fromEntries(companies.map((c) => [c.symbol, c.price])),
    holdings: {},
    dividends: 0,
    invested: 0,
    quickSales: 0,
    lastEvent: null,
    lastAgo: null,
  };
}

export function fee(amount: number) {
  return Math.max(FEE_MIN, Math.round(amount * FEE_RATE));
}

/** Prix d'achat total pour qty parts, frais compris. */
export function buyCost(state: CityState, symbol: string, qty: number) {
  const gross = state.prices[symbol] * qty;
  return gross + fee(gross);
}

export function buy(state: CityState, symbol: string, qty: number, cash: number): { state: CityState; cash: number } | null {
  const total = buyCost(state, symbol, qty);
  if (qty <= 0 || total > cash) return null;
  const h = state.holdings[symbol];
  const holdings = {
    ...state.holdings,
    [symbol]: h ? { ...h, qty: h.qty + qty, cost: h.cost + total } : { qty, cost: total, since: state.seance },
  };
  return { state: { ...state, holdings, invested: state.invested + total }, cash: cash - total };
}

export interface SaleResult {
  state: CityState;
  cash: number;
  proceeds: number;
  gain: number; // plus-value (positive) ou moins-value (négative), frais compris
}

export function sell(state: CityState, symbol: string, qty: number, cash: number): SaleResult | null {
  const h = state.holdings[symbol];
  if (!h || qty <= 0 || qty > h.qty) return null;
  const gross = state.prices[symbol] * qty;
  const proceeds = gross - fee(gross);
  const costPart = (h.cost / h.qty) * qty;
  const holdings = { ...state.holdings };
  // Vendre fait perdre la croissance accumulée : le bâtiment repart de zéro.
  if (qty === h.qty) delete holdings[symbol];
  else holdings[symbol] = { qty: h.qty - qty, cost: h.cost - costPart, since: state.seance };
  const quick = state.seance - h.since < 5 ? 1 : 0;
  return {
    state: { ...state, holdings, quickSales: state.quickSales + quick },
    cash: cash + proceeds,
    proceeds,
    gain: Math.round(proceeds - costPart),
  };
}

/** Taille du bâtiment (1 à 5) selon la durée de détention : 10 / 25 / 50 / 100 séances. */
export function buildingLevel(state: CityState, symbol: string) {
  const h = state.holdings[symbol];
  if (!h) return 0;
  const held = state.seance - h.since;
  return held >= 100 ? 5 : held >= 50 ? 4 : held >= 25 ? 3 : held >= 10 ? 2 : 1;
}

export function seancesToAgo(state: CityState) {
  return AGO_EVERY - (state.seance % AGO_EVERY);
}

/**
 * Une séance passe (1 puzzle terminé = 1 séance).
 * Prix : petite variation autour du vrai cours + effet de l'événement du jour, bornés à ±15 % du vrai cours.
 */
export function advance(
  state: CityState,
  companies: Company[],
  seed: number,
): { state: CityState; cashGained: number; event: EventCard; ago: boolean } {
  const r = rng(seed + state.seance * 7919);
  const event = EVENTS[Math.floor(r() * EVENTS.length)];
  const prices: Record<string, number> = {};
  for (const c of companies) {
    const p = state.prices[c.symbol] ?? c.price;
    const noise = (r() - 0.5) * 0.03; // ±1,5 %
    const pull = (c.price - p) / c.price * 0.2; // rappel vers le vrai cours
    let move = noise + pull;
    if (event.family === null || event.family === c.family) {
      // Famille complète = bouclier : une famille d'au moins 2 entreprises détenues amortit les chocs négatifs.
      const shield = event.move < 0 && familyCount(state, companies, c.family) >= 2 ? 0.5 : 1;
      move += event.move * shield;
    }
    const next = Math.min(c.price * 1.15, Math.max(c.price * 0.85, p * (1 + move)));
    prices[c.symbol] = Math.max(1, Math.round(next));
  }
  const seance = state.seance + 1;
  let cashGained = 0;
  let ago = false;
  let lastAgo = state.lastAgo;
  if (seance % AGO_EVERY === 0) {
    ago = true;
    for (const [sym, h] of Object.entries(state.holdings)) {
      const c = companies.find((x) => x.symbol === sym);
      if (!c?.lastDividend) continue;
      if (seance - h.since >= HOURGLASS) cashGained += Math.round(c.lastDividend * h.qty);
    }
    lastAgo = { seance, amount: cashGained };
  }
  return {
    state: { ...state, seance, prices, dividends: state.dividends + cashGained, lastEvent: event, lastAgo },
    cashGained,
    event,
    ago,
  };
}

export function familyCount(state: CityState, companies: Company[], family: Family) {
  return Object.keys(state.holdings).filter((s) => companies.find((c) => c.symbol === s)?.family === family).length;
}

export function portfolioValue(state: CityState) {
  return Object.entries(state.holdings).reduce((v, [s, h]) => v + state.prices[s] * h.qty, 0);
}

/**
 * Score PACO sur 1 000 (GDD §6) :
 * 35 % valeur · 25 % dividendes · 25 % diversification · 15 % régularité.
 */
export function scorePaco(state: CityState, companies: Company[], daysPlayed: number) {
  const value = portfolioValue(state);
  const costHeld = Object.values(state.holdings).reduce((v, h) => v + h.cost, 0);
  const ratio = costHeld > 0 ? value / costHeld : 1; // 1 = à l'équilibre
  const sValue = Math.max(0, Math.min(1, (ratio - 0.85) / 0.3)); // 0 à −15 %, 1 à +15 %
  const sDiv = state.invested > 0 ? Math.min(1, state.dividends / (state.invested * 0.08)) : 0;
  const fams = new Set(Object.keys(state.holdings).map((s) => companies.find((c) => c.symbol === s)?.family));
  const sDivers = Math.min(1, fams.size / 7);
  const sReg = Math.max(0, Math.min(1, daysPlayed / 7) - state.quickSales * 0.1);
  if (Object.keys(state.holdings).length === 0 && state.dividends === 0) return Math.round(sReg * 150);
  return Math.round(350 * sValue + 250 * sDiv + 250 * sDivers + 150 * sReg);
}

/** Paco contextuel (GDD §8). Jamais « achète / vends » : il explique. */
export function pacoTip(state: CityState, companies: Company[], citiesDone: number): string | null {
  const fams = new Set(Object.keys(state.holdings).map((s) => companies.find((c) => c.symbol === s)?.family));
  const n = Object.keys(state.holdings).length;
  if (n === 0) return 'Ta ville est vide. Au guichet SGI, tu peux acheter une part d’une vraie entreprise de la BRVM.';
  if (state.quickSales >= 3) return 'Tu revends souvent. Chaque vente coûte des frais, et ton bâtiment perd sa croissance.';
  const toAgo = seancesToAgo(state);
  if (toAgo <= HOURGLASS) return `AGO dans ${toAgo} séance${toAgo > 1 ? 's' : ''} ! Seules les parts gardées avant le sablier touchent le dividende.`;
  if (fams.size === 1 && citiesDone >= 3) return 'Toutes tes parts sont dans le même secteur. Une seule mauvaise nouvelle peut tout toucher.';
  return null;
}
