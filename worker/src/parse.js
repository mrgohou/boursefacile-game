// Lecture des pages publiques de brvm.org (même logique que l'app Android : lib/data/market.dart).

const MONTHS = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];

const ENTITIES = { '&amp;': '&', '&nbsp;': ' ', '&#039;': "'", '&quot;': '"', '&lt;': '<', '&gt;': '>' };
const text = (h) =>
  h
    .replace(/<[^>]+>/g, ' ')
    .replace(/&[#a-z0-9]+;/gi, (e) => ENTITIES[e] ?? ' ')
    .replace(/\s+/g, ' ')
    .trim();

export function number(t) {
  const n = Number(String(t ?? '').replace(/[\s  %]/g, '').replace(',', '.'));
  return Number.isFinite(n) && String(t ?? '').trim() !== '' ? n : null;
}

function rows(html) {
  return [...html.matchAll(/<tr[^>]*>([\s\S]*?)<\/tr>/g)].map((m) =>
    [...m[1].matchAll(/<td[^>]*>([\s\S]*?)<\/td>/g)].map((c) => text(c[1])),
  );
}

/** « Dernière mise à jour : Mardi, 10 novembre, 2026 - 22:45 » → Date UTC (Abidjan = UTC). */
export function publicationDate(html) {
  const m = text(html).match(/Dernière mise à jour\s*:?\s*\S+,?\s*(\d{1,2})\s+([a-zéû]+),?\s*(\d{4})\s*-\s*(\d{1,2}):(\d{2})/i);
  if (!m) throw new Error('Date de séance officielle absente');
  const month = MONTHS.indexOf(m[2].toLowerCase());
  if (month < 0) throw new Error('Mois inconnu');
  return new Date(Date.UTC(+m[3], month, +m[1], +m[4], +m[5]));
}

/** Page « cours des actions » : symbole, nom, volume, cours veille, ouverture, clôture, variation %. */
export function parseQuotes(actionsHtml) {
  const quotes = [];
  for (const c of rows(actionsHtml)) {
    if (c.length !== 7 || !/^[A-Z]{3,5}$/.test(c[0])) continue;
    const close = number(c[5]);
    const change = number(c[6]);
    if (close == null || close <= 0 || change == null) throw new Error(`Cotation incomplète : ${c[0]}`);
    quotes.push({ symbol: c[0], officialName: c[1], volume: number(c[2]) ?? 0, previousClose: number(c[3]), close, change });
  }
  if (quotes.length < 30 || new Set(quotes.map((q) => q.symbol)).size !== quotes.length) throw new Error('Structure BRVM modifiée');
  return quotes;
}

/** Page d'accueil : indices BRVM-C, BRVM-30, BRVM-PRES. */
export function parseIndices(homeHtml) {
  const out = {};
  for (const c of rows(homeHtml))
    if (c.length >= 3 && ['BRVM-C', 'BRVM-30', 'BRVM-PRES'].includes(c[0]) && number(c[1]) != null)
      out[c[0]] = { value: number(c[1]), change: number(c[2]) };
  return out;
}

/**
 * Construit l'instantané lu par le jeu : cours officiels + fiches (secteur, pays, BPA, dividende).
 * Le PER et le rendement sont recalculés avec le cours du jour.
 */
export function buildSnapshot(actionsHtml, homeHtml, facts) {
  const date = publicationDate(homeHtml);
  if (publicationDate(actionsHtml).getTime() !== date.getTime())
    throw new Error('Les deux pages ne correspondent pas à la même publication');
  const companies = parseQuotes(actionsHtml)
    .filter((q) => facts[q.symbol])
    .map((q) => {
      const f = facts[q.symbol];
      return {
        symbol: q.symbol,
        name: f.name,
        sector: f.sector,
        family: f.family,
        country: f.country,
        price: q.close,
        previousClose: q.previousClose,
        eps: f.eps,
        per: f.eps && f.eps > 0 ? Math.round((q.close / f.eps) * 100) / 100 : null,
        lastDividend: f.lastDividend,
        dividendYield: f.lastDividend ? Math.round((f.lastDividend / q.close) * 10000) / 100 : null,
      };
    });
  return {
    sessionDate: date.toISOString().slice(0, 10),
    publishedAt: date.toISOString(),
    source: 'brvm.org (cours officiels) ; BPA et dividendes : fiches Bourse Facile à vérifier',
    indices: parseIndices(homeHtml),
    companies,
  };
}
