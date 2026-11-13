// Cloudflare Worker « paco-market » : chaque soir de séance, publie les cours officiels BRVM
// dans Firestore (market_snapshots/latest + un historique par date). Lu par le jeu PACO Bourse.
import facts from './facts.json';
import { buildSnapshot } from './parse.js';
import { writeDoc } from './firestore.js';

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
  // Déclenchement manuel protégé : GET /run avec l'en-tête x-run-token.
  async fetch(req, env) {
    const url = new URL(req.url);
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
