// Cloudflare Worker « paco-market » : chaque soir de séance, publie les cours officiels BRVM
// dans Firestore (market_snapshots/latest + un historique par date). Lu par le jeu PACO Bourse.
import facts from './facts.json';
import { buildSnapshot } from './parse.js';
import { readDoc, writeDoc } from './firestore.js';

const ROOT = 'https://www.brvm.org';
const UA = { 'user-agent': 'PacoBourse/0.1 (+https://paco-bourse.web.app)', accept: 'text/html' };

async function page(url) {
  const res = await fetch(url, { headers: UA, redirect: 'manual' });
  if (res.status !== 200) throw new Error(`${url} : ${res.status}`);
  return res.text();
}

export async function run(env) {
  const [actions, home] = await Promise.all([page(`${ROOT}/fr/cours-actions/0`), page(`${ROOT}/fr`)]);
  const snapshot = buildSnapshot(actions, home, facts);
  await writeDoc(env, 'market_snapshots/latest', snapshot);
  await writeDoc(env, `market_snapshots/${snapshot.sessionDate}`, snapshot);
  return snapshot;
}

export default {
  // Déclenchement planifié (voir wrangler.jsonc).
  async scheduled(_event, env, ctx) {
    ctx.waitUntil(run(env));
  },
  async fetch(req, env, ctx) {
    const url = new URL(req.url);
    // Cours du jour pour le jeu, servis depuis le cache du réseau Cloudflare :
    // 10 000 joueurs = quelques lectures Firestore par heure, pas une par joueur.
    if (url.pathname === '/market/latest') return marketLatest(req, env, ctx);
    // Déclenchement manuel protégé : GET /run avec l'en-tête x-run-token.
    if (url.pathname !== '/run') return new Response('PACO Bourse market worker', { status: 200 });
    if (!env.RUN_TOKEN || req.headers.get('x-run-token') !== env.RUN_TOKEN) return new Response('Interdit', { status: 403 });
    try {
      const s = await run(env);
      return Response.json({ ok: true, sessionDate: s.sessionDate, companies: s.companies.length });
    } catch (e) {
      return Response.json({ ok: false, error: String(e) }, { status: 500 });
    }
  },
};

const CORS = { 'access-control-allow-origin': '*', 'access-control-allow-methods': 'GET' };

async function marketLatest(req, env, ctx) {
  const cache = caches.default;
  const key = new Request(new URL('/market/latest', req.url).toString(), { method: 'GET' });
  const hit = await cache.match(key);
  if (hit) return hit;
  let body;
  try {
    body = JSON.stringify(await readDoc(env, 'market_snapshots/latest'));
  } catch (e) {
    return Response.json({ error: 'indisponible' }, { status: 503, headers: { ...CORS, 'retry-after': '60' } });
  }
  const res = new Response(body, {
    headers: {
      ...CORS,
      'content-type': 'application/json; charset=utf-8',
      // 15 min en cache partagé ; le téléphone garde sa copie 5 min et peut réutiliser l'ancienne pendant 1 h si besoin.
      'cache-control': 'public, max-age=300, s-maxage=900, stale-while-revalidate=3600',
    },
  });
  ctx.waitUntil(cache.put(key, res.clone()));
  return res;
}
