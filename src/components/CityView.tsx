import { useEffect, useMemo, useState } from 'react';
import {
  FAMILIES,
  HOURGLASS,
  buildingLevel,
  buy,
  buyCost,
  portfolioValue,
  pacoTip,
  scorePaco,
  seancesToAgo,
  sell,
  type CityState,
  type Company,
} from '../engine/city';
import { Paco } from './Paco';
import { sfx } from '../audio';

const fmt = (n: number) => Math.round(n).toLocaleString('fr-FR');
const base = import.meta.env.BASE_URL;

export interface CityViewProps {
  city: CityState;
  cash: number;
  companies: Company[]; // entreprises débloquées (pays visités)
  citiesDone: number;
  daysPlayed: number;
  sgiOpen: boolean;
  onChange: (city: CityState, cash: number) => void;
  onBack: () => void;
}

export function CityView({ city, cash, companies, citiesDone, daysPlayed, sgiOpen, onChange, onBack }: CityViewProps) {
  const [tab, setTab] = useState<'ville' | 'sgi'>('ville');
  const [detail, setDetail] = useState<Company | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  useEffect(() => {
    if (!toast) return;
    const t = window.setTimeout(() => setToast(null), 3500);
    return () => window.clearTimeout(t);
  }, [toast]);

  const owned = Object.entries(city.holdings);
  const value = portfolioValue(city);
  const score = scorePaco(city, companies, daysPlayed);
  const tip = pacoTip(city, companies, citiesDone);
  const toAgo = seancesToAgo(city);
  const byFamily = useMemo(() => {
    const m = new Map<string, Company[]>();
    for (const c of companies) m.set(c.family, [...(m.get(c.family) ?? []), c]);
    return [...m.entries()];
  }, [companies]);

  const doBuy = (c: Company) => {
    const r = buy(city, c.symbol, 1, cash);
    if (!r) return;
    sfx('coin');
    onChange(r.state, r.cash);
    setToast(`1 part de ${c.name} achetée. Frais compris : ${fmt(buyCost(city, c.symbol, 1))} FCFA-jeu.`);
  };
  const doSell = (c: Company) => {
    const r = sell(city, c.symbol, 1, cash);
    if (!r) return;
    sfx('tap');
    onChange(r.state, r.cash);
    setToast(
      `1 part de ${c.name} vendue. ${r.gain >= 0 ? 'Plus-value' : 'Moins-value'} : ${r.gain >= 0 ? '+' : ''}${fmt(r.gain)} FCFA-jeu, frais compris.`,
    );
  };

  return (
    <main className="cityview">
      <button className="ghost back" onClick={onBack}>
        ← Carte
      </button>
      <section className="kpis">
        <div>
          <small>Score PACO</small>
          <b>{score}</b>
        </div>
        <div>
          <small>Valeur de ta ville</small>
          <b>{fmt(value)}</b>
        </div>
        <div>
          <small>Dividendes reçus</small>
          <b>{fmt(city.dividends)}</b>
        </div>
      </section>
      <p className="seance">
        Séance {city.seance} · AGO dans {toAgo} séance{toAgo > 1 ? 's' : ''} {toAgo <= HOURGLASS ? '⏳' : ''}
      </p>
      {city.lastEvent && <div className="event">📰 {city.lastEvent.text}</div>}
      {city.lastAgo && city.lastAgo.seance === city.seance && (
        <div className="event ago">
          🎉 AGO : tu as reçu {fmt(city.lastAgo.amount)} FCFA-jeu de dividendes.
        </div>
      )}

      {!sgiOpen ? (
        <Paco pose="reflechir" text="Termine Abidjan avec 5 étoiles : ta ville et le guichet SGI s'ouvriront à Dakar." />
      ) : (
        <>
          <div className="tabs">
            <button className={tab === 'ville' ? 'on' : ''} onClick={() => setTab('ville')}>
              Ma Ville ({owned.length})
            </button>
            <button className={tab === 'sgi' ? 'on' : ''} onClick={() => setTab('sgi')}>
              Guichet SGI
            </button>
          </div>

          {tab === 'ville' && (
            <>
              {tip && <Paco pose={owned.length ? 'reflechir' : 'expliquer'} text={tip} />}
              <div className="buildings">
                {owned.map(([sym, h]) => {
                  const c = companies.find((x) => x.symbol === sym);
                  if (!c) return null;
                  const lvl = buildingLevel(city, sym);
                  const up = city.prices[sym] >= c.price;
                  return (
                    <button key={sym} className="building" onClick={() => setDetail(c)} style={{ ['--h' as string]: `${40 + lvl * 14}px`, ['--c' as string]: FAMILIES[c.family].color }}>
                      <span className="walkers">
                        <i className={up ? 'g' : 'r'} />
                        <i className={up ? 'g' : 'r'} />
                      </span>
                      <span className="tower">
                        <img src={`${base}tiles/${FAMILIES[c.family].tile}.svg`} alt="" />
                      </span>
                      <b>{sym}</b>
                      <small>
                        {h.qty} part{h.qty > 1 ? 's' : ''} · niv. {lvl}
                      </small>
                    </button>
                  );
                })}
              </div>
            </>
          )}

          {tab === 'sgi' && (
            <div className="sgi">
              <p className="fine">Cours réels de la BRVM (séance du 13/11/2026, version de test). Frais : 1 %, minimum 50.</p>
              {byFamily.map(([fam, list]) => (
                <div key={fam}>
                  <h3>{FAMILIES[fam as keyof typeof FAMILIES].label}</h3>
                  {list.map((c) => {
                    const h = city.holdings[c.symbol];
                    const cost = buyCost(city, c.symbol, 1);
                    return (
                      <div key={c.symbol} className="row">
                        <button className="who" onClick={() => setDetail(c)}>
                          <b>{c.symbol}</b>
                          <small>{c.name}</small>
                        </button>
                        <span className="px">{fmt(city.prices[c.symbol])}</span>
                        {h && (
                          <button className="mini sell" onClick={() => doSell(c)}>
                            −1
                          </button>
                        )}
                        <button className="mini" disabled={cost > cash} onClick={() => doBuy(c)}>
                          +1
                        </button>
                      </div>
                    );
                  })}
                </div>
              ))}
            </div>
          )}
        </>
      )}

      {toast && (
        <div className="toast" onClick={() => setToast(null)}>
          {toast}
        </div>
      )}

      {detail && (
        <div className="overlay" onClick={() => setDetail(null)}>
          <div className="card" onClick={(e) => e.stopPropagation()}>
            <div className="card-head" style={{ background: FAMILIES[detail.family].color }}>
              <img src={`${base}tiles/${FAMILIES[detail.family].tile}.svg`} alt="" />
              <div>
                <b>{detail.name}</b>
                <small>
                  {detail.symbol} · {detail.country}
                </small>
              </div>
            </div>
            <ul>
              <li>
                <span>Prix d'une part</span>
                <b>{fmt(city.prices[detail.symbol])} FCFA-jeu</b>
              </li>
              <li>
                <span>Vrai cours BRVM</span>
                <b>{fmt(detail.price)} FCFA</b>
              </li>
              <li>
                <span>Secteur</span>
                <b>{detail.sector}</b>
              </li>
              {citiesDone >= 4 && detail.lastDividend != null && (
                <li>
                  <span>Dernier dividende</span>
                  <b>{fmt(detail.lastDividend)} par part</b>
                </li>
              )}
              {citiesDone >= 4 && detail.dividendYield != null && (
                <li>
                  <span>Rendement</span>
                  <b>{detail.dividendYield.toLocaleString('fr-FR')} pièces pour 100</b>
                </li>
              )}
              {citiesDone >= 5 && (
                <li>
                  <span>Cœur (BPA)</span>
                  <b>{detail.eps == null ? '?' : detail.eps > 0 ? `💚 ${fmt(detail.eps)}` : `❤️‍🩹 ${fmt(detail.eps)}`}</b>
                </li>
              )}
              {citiesDone >= 6 && (
                <li>
                  <span>PER</span>
                  <b>{detail.per && detail.eps && detail.eps > 0 ? `${Math.round(detail.per)} années` : 'non calculable'}</b>
                </li>
              )}
            </ul>
            {city.holdings[detail.symbol] && (
              <p className="fine">
                Tu as {city.holdings[detail.symbol].qty} part(s), payées {fmt(city.holdings[detail.symbol].cost)} FCFA-jeu au total.
              </p>
            )}
            <p className="fine">Les chiffres financiers de cette version de test sont à vérifier. Ce n'est pas un conseil d'investissement.</p>
            <button className="btn" onClick={() => setDetail(null)}>
              Fermer
            </button>
          </div>
        </div>
      )}
    </main>
  );
}
