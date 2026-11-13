import { useState } from 'react';
import { FAMILIES, type Company, type Family } from '../engine/city';

const base = import.meta.env.BASE_URL;

/** Collection de cartes entreprises, rangées par familles de secteurs (GDD §5). */
export function CardsView({ cards, companies, onBack }: { cards: string[]; companies: Company[]; onBack: () => void }) {
  const [open, setOpen] = useState<Company | null>(null);
  const families = Object.keys(FAMILIES) as Family[];
  const total = companies.length;
  return (
    <main className="cards">
      <button className="ghost back" onClick={onBack}>
        ← Carte
      </button>
      <h2>
        Mes cartes
        <small>
          {cards.length} / {total} entreprises de la BRVM
        </small>
      </h2>
      <p className="fine left">
        Gagne une carte en gardant une part 10 séances, ou en réussissant un quiz de Paco sans faute.
      </p>
      {families.map((f) => {
        const list = companies.filter((c) => c.family === f);
        if (!list.length) return null;
        const have = list.filter((c) => cards.includes(c.symbol)).length;
        return (
          <section key={f} className="family">
            <h3>
              {FAMILIES[f].label}
              <small>
                {have}/{list.length} {have === list.length ? '· famille complète 🛡️' : ''}
              </small>
            </h3>
            <div className="deck">
              {list.map((c) => {
                const got = cards.includes(c.symbol);
                return (
                  <button
                    key={c.symbol}
                    className={`mini-card ${got ? '' : 'missing'}`}
                    style={{ ['--c' as string]: FAMILIES[f].color }}
                    disabled={!got}
                    onClick={() => setOpen(c)}
                  >
                    {got ? (
                      <>
                        <img src={`${base}tiles/${FAMILIES[f].tile}.svg`} alt="" />
                        <b>{c.symbol}</b>
                      </>
                    ) : (
                      <b>?</b>
                    )}
                  </button>
                );
              })}
            </div>
          </section>
        );
      })}
      {open && (
        <div className="overlay" onClick={() => setOpen(null)}>
          <div className="card" onClick={(e) => e.stopPropagation()}>
            <div className="card-head" style={{ background: FAMILIES[open.family].color }}>
              <img src={`${base}tiles/${FAMILIES[open.family].tile}.svg`} alt="" />
              <div>
                <b>{open.name}</b>
                <small>
                  {open.symbol} · {open.country}
                </small>
              </div>
            </div>
            <ul>
              <li>
                <span>Secteur</span>
                <b>{open.sector}</b>
              </li>
              <li>
                <span>Dernier dividende</span>
                <b>{open.lastDividend != null ? `${open.lastDividend.toLocaleString('fr-FR')} par part` : '?'}</b>
              </li>
              <li>
                <span>Cœur (BPA)</span>
                <b>{open.eps == null ? '?' : open.eps > 0 ? '💚 positif' : '❤️‍🩹 négatif'}</b>
              </li>
              <li>
                <span>PER</span>
                <b>{open.per && open.eps && open.eps > 0 ? `${Math.round(open.per)} années` : 'non calculable'}</b>
              </li>
            </ul>
            <p className="fine">Chiffres de test, à vérifier. Ce n'est pas un conseil d'investissement.</p>
            <button className="btn" onClick={() => setOpen(null)}>
              Fermer
            </button>
          </div>
        </div>
      )}
    </main>
  );
}
