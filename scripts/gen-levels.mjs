// Génère src/data/levels.json : 15 villes × 3 niveaux (v0).
// Lancer : node scripts/gen-levels.mjs
import { writeFileSync } from 'node:fs';

const ALL = ['cacao', 'telephone', 'billet', 'bidon', 'ampoule', 'engrenage'];
const FEATURED = ['cacao', 'telephone', 'billet', 'bidon', 'telephone', 'engrenage', 'ampoule', 'billet',
  'telephone', 'billet', 'cacao', 'cacao', 'engrenage', 'ampoule', 'billet'];
const NAMES = { cacao: 'cacao', telephone: 'téléphones', billet: 'billets', bidon: 'bidons', ampoule: 'ampoules', engrenage: 'engrenages' };

const levels = [];
for (let city = 1; city <= 15; city++) {
  const f = FEATURED[city - 1];
  // 4 types de tuiles (villes 1–3), 5 (villes 4–12), 6 (villes 13–15).
  const n = city <= 3 ? 4 : city <= 12 ? 5 : 6;
  const tiles = [f, ...ALL.filter((t) => t !== f)].slice(0, n);
  const second = tiles[1];
  for (let index = 1; index <= 3; index++) {
    const step = (city - 1) * 3 + (index - 1); // 0..44
    const moves = Math.max(20, 26 - Math.floor(step / 8)) + (n === 6 ? 4 : 0);
    const objectives = [];
    let pacoBefore, pacoHint;
    const locks = [];
    if (index === 1) {
      const count = n === 6 ? 9 + Math.floor(step / 10) : 12 + Math.floor(step / 5);
      objectives.push({ kind: 'collect', tile: f, count });
      pacoBefore = `Récolte ${count} ${NAMES[f]} pour remplir ta tirelire.`;
      pacoHint = 'Aligne 4 tuiles pour créer une tuile Dividende : elle vide toute une ligne !';
    } else if (index === 2) {
      const target = Math.round(((n === 6 ? 700 : 900) + step * 35) / 50) * 50;
      objectives.push({ kind: 'score', target });
      pacoBefore = `Atteins ${target} points. Les cascades rapportent plus : sois patient.`;
      pacoHint = 'Joue en bas de la grille : les tuiles qui tombent créent des cascades.';
    } else {
      const c1 = (n === 6 ? 8 : 10) + Math.floor(step / 8);
      objectives.push({ kind: 'collect', tile: f, count: c1 }, { kind: 'collect', tile: second, count: c1 });
      pacoBefore = `Récolte ${c1} ${NAMES[f]} et ${c1} ${NAMES[second]} : deux secteurs, c'est plus solide !`;
      pacoHint = 'Une forme en L ou en T crée une tuile AGO qui explose tout autour.';
    }
    // Cadenas « Frais » à partir de la ville 10.
    if (city >= 10 && index !== 2) {
      const k = city >= 13 ? 3 : 2;
      const spots = [[3, 2], [3, 4], [2, 3], [4, 3]].slice(0, k);
      locks.push(...spots);
      objectives.push({ kind: 'unlock', count: k });
      pacoBefore += ` Ouvre aussi ${k} cadenas « Frais ».`;
      pacoHint = 'Un cadenas s ouvre en le touchant 2 fois avec des alignements à côté.';
    }
    levels.push({
      id: `c${city}-l${index}`,
      city,
      index,
      moves,
      tiles,
      objectives,
      ...(locks.length ? { locks } : {}),
      seed: 1000 + step * 7919,
      pacoBefore,
      pacoHint,
    });
  }
}
writeFileSync(new URL('../src/data/levels.json', import.meta.url), JSON.stringify(levels, null, 2) + '\n');
console.log(`${levels.length} niveaux écrits`);
