import { Suspense, lazy, useEffect, useState } from 'react';
import { CITIES } from './data/cities';
import {
  COMPANIES,
  LEVELS,
  cardsFromHoldings,
  cityStars,
  cityUnlocked,
  cityValidated,
  citiesDone,
  levelUnlocked,
  load,
  persist,
  quizRewardCard,
  title,
  today,
  unlockedCompanies,
  type Save,
} from './store';
import { QuizView } from './components/QuizView';
import { AccountSheet } from './components/AccountSheet';
import { cloudAvailable, loadCloudSave, loadMarket, onUser, saveCloud, sendFeedback, signOut } from './cloud';
import { GOAT_SCORE, applyMarket, progressOf, type Feedback } from './store';
import snapshot from './data/market-snapshot.json';
import { CardsView } from './components/CardsView';
import { CityView } from './components/CityView';
import { advance, scorePaco } from './engine/city';
import type { LevelResult } from './components/LevelView';
import { FeedbackSheet } from './components/FeedbackSheet';
// Le moteur de jeu (Phaser) n'est chargé qu'au premier niveau : accueil plus rapide.
const LevelView = lazy(() => import('./components/LevelView').then((m) => ({ default: m.LevelView })));
import { Paco } from './components/Paco';
import { isMuted, setMuted, startMusic } from './audio';
import type { LevelDef } from './engine/board';
import './App.css';

type Screen = { name: 'home' } | { name: 'map' } | { name: 'ville' } | { name: 'cards' } | { name: 'quiz'; city: number } | { name: 'city'; city: number } | { name: 'level'; level: LevelDef };

export default function App() {
  const [save, setSave] = useState<Save>(load);
  const [screen, setScreen] = useState<Screen>({ name: 'home' });
  const [muted, setM] = useState(isMuted());

  const [uid, setUid] = useState<string | null>(null);
  const [account, setAccount] = useState(false);
  const [feedbackFor, setFeedbackFor] = useState<number | null>(null);
  const [marketDate, setMarketDate] = useState(snapshot.sessionDate);
  const cloud = cloudAvailable();

  useEffect(() => persist(save), [save]);

  // Cours du jour publiés dans Firestore (sinon : instantané intégré au jeu).
  useEffect(() => {
    if (!cloud) return;
    void loadMarket().then((m) => {
      if (m && m.sessionDate > snapshot.sessionDate && applyMarket(m.companies)) setMarketDate(m.sessionDate);
    });
  }, [cloud]);

  // Compte : on récupère la sauvegarde en ligne si elle est plus avancée.
  useEffect(() => {
    if (!cloud) return;
    let off: (() => void) | undefined;
    void onUser(async (u) => {
      setUid(u?.uid ?? null);
      if (!u) return;
      const remote = await loadCloudSave(u.uid).catch(() => null);
      setSave((local) => (remote && progressOf(remote) > progressOf(local) ? { ...local, ...remote } : local));
    }).then((f) => (off = f));
    return () => off?.();
  }, [cloud]);

  // Sauvegarde en ligne, au plus une fois toutes les 3 secondes.
  useEffect(() => {
    if (!uid) return;
    const t = window.setTimeout(() => void saveCloud(uid, save).catch(() => undefined), 3000);
    return () => window.clearTimeout(t);
  }, [uid, save]);

  const start = () => {
    startMusic();
    setScreen({ name: 'map' });
  };

  const onEnd = (level: LevelDef, r: LevelResult) => {
    // 1 puzzle réussi = 1 séance dans Ma Ville (GDD §2).
    const step = advance(save.city, COMPANIES, 2026);
    setSave((s) => {
      const next: Save = {
        ...s,
        savings: s.savings + r.savings + step.cashGained,
        stars: { ...s.stars, [level.id]: Math.max(s.stars[level.id] ?? 0, r.stars) },
        city: step.state,
        days: s.days.includes(today()) ? s.days : [...s.days, today()],
      };
      return { ...next, cards: cardsFromHoldings(next) };
    });
    setScreen({ name: 'city', city: level.city });
  };

  const onQuiz = (city: number, score: number) => {
    setSave((s) => {
      const next = { ...s, quiz: { ...s.quiz, [city]: Math.max(s.quiz[city] ?? 0, score) } };
      const card = score === 3 ? quizRewardCard(s, city) : null;
      return card ? { ...next, cards: [...next.cards, card] } : next;
    });
    setScreen({ name: 'city', city });
    if (score >= 2 && !save.feedback[city]) setFeedbackFor(city);
  };

  const onFeedback = (city: number, f: Feedback | null) => {
    setFeedbackFor(null);
    if (!f) return;
    setSave((s) => ({ ...s, feedback: { ...s.feedback, [city]: f } }));
    if (uid) void sendFeedback(uid, city, f).catch(() => undefined);
  };

  const toggleSound = () => {
    setMuted(!muted);
    setM(!muted);
  };

  return (
    <div className="app">
      {screen.name !== 'level' && (
        <header className="top">
          <div className="brand">
            <span className="logo">P</span>
            <b>PACO Bourse</b>
          </div>
          <div className="wallet" title="Ton épargne (FCFA-jeu, fictifs)">
            <img src={`${import.meta.env.BASE_URL}tiles/billet.webp`} alt="" />
            {save.savings.toLocaleString('fr-FR')}
          </div>
          <button className="ghost" onClick={toggleSound} aria-label={muted ? 'Activer le son' : 'Couper le son'}>
            {muted ? '🔇' : '🔊'}
          </button>
        </header>
      )}

      {screen.name === 'home' && (
        <main className="home">
          <h1>
            Joue. Épargne.
            <br />
            Récolte avec patience.
          </h1>
          <Paco pose="accueil" text="Salut, moi c'est Paco ! Je vais t'apprendre la bourse de la BRVM, ville après ville." />
          <button className="btn big" onClick={start}>
            Jouer
          </button>
          {cloud ? (
            uid ? (
              <button className="ghost small" onClick={() => void signOut()}>
                Connecté · progression sauvegardée en ligne · se déconnecter
              </button>
            ) : (
              <button className="ghost small" onClick={() => setAccount(true)}>
                Se connecter pour sauvegarder en ligne
              </button>
            )
          ) : (
            <p className="fine">Aperçu : la progression reste sur cet appareil. Les comptes marchent sur la version hébergée.</p>
          )}
          <p className="fine">Version de test v0 · FCFA-jeu fictifs · aucun argent réel · aucun conseil d'investissement</p>
        </main>
      )}

      {screen.name === 'map' && (
        <main className="map">
          <p className="titre">
            Titre : <b>{title(save)}</b> · cours BRVM du {marketDate.split('-').reverse().join('/')}
          </p>
          {citiesDone(save) >= 15 && title(save) !== 'GOAT de la BRVM' && (
            <Paco
              pose="progresser"
              text={`Les 15 villes sont validées ! Fais grimper ton Score PACO à ${GOAT_SCORE} pour devenir GOAT de la BRVM.`}
            />
          )}
          <button className="villebtn" onClick={() => setScreen({ name: 'ville' })}>
            <span>🏙️ Ma Ville</span>
            <small>
              Score PACO {scorePaco(save.city, COMPANIES, save.days.length)} · séance {save.city.seance}
            </small>
          </button>
          <button className="villebtn alt" onClick={() => setScreen({ name: 'cards' })}>
            <span>🃏 Mes cartes</span>
            <small>
              {save.cards.length} / {unlockedCompanies(save).length} entreprises
            </small>
          </button>
          <ol className="route">
            {CITIES.map((c) => {
              const open = cityUnlocked(save, c.n);
              const st = cityStars(save, c.n);
              return (
                <li key={c.n} className={`stop ${open ? '' : 'locked'} ${c.n % 2 ? 'left' : 'right'}`}>
                  <button disabled={!open} onClick={() => setScreen({ name: 'city', city: c.n })}>
                    <span className="num">{open ? c.n : '🔒'}</span>
                    <span className="info">
                      <b>{c.name}</b>
                      <small>
                        {c.notion} · {st}/9 ★
                      </small>
                    </span>
                  </button>
                </li>
              );
            })}
          </ol>
        </main>
      )}

      {screen.name === 'city' &&
        (() => {
          const c = CITIES[screen.city - 1];
          const first = !save.seenIntro[c.n];
          const done = cityStars(save, c.n) >= 5;
          return (
            <main className="city">
              <button className="ghost back" onClick={() => setScreen({ name: 'map' })}>
                ← Carte
              </button>
              <h2>
                {c.n}. {c.name}
                <small>
                  {c.country} · {c.notion}
                </small>
              </h2>
              {first ? (
                <Paco
                  pose="expliquer"
                  text={c.pacoIntro}
                  onClose={() => setSave((s) => ({ ...s, seenIntro: { ...s.seenIntro, [c.n]: true } }))}
                  cta="Compris !"
                />
              ) : (
                <>
                  <div className="levels">
                    {LEVELS.filter((l) => l.city === c.n).map((l) => {
                      const ok = levelUnlocked(save, l);
                      const st = save.stars[l.id] ?? 0;
                      return (
                        <button key={l.id} className="lvl" disabled={!ok} onClick={() => setScreen({ name: 'level', level: l })}>
                          <span className="n">{ok ? l.index : '🔒'}</span>
                          <span className="st">{'★'.repeat(st) + '☆'.repeat(3 - st)}</span>
                        </button>
                      );
                    })}
                  </div>
                  {done && !cityValidated(save, c.n) && (
                    <>
                      <Paco pose="apprendre" text={`Ce qu'on retient : ${c.retiens}`} />
                      <button className="btn big" onClick={() => setScreen({ name: 'quiz', city: c.n })}>
                        Quiz de Paco
                      </button>
                    </>
                  )}
                  {cityValidated(save, c.n) && (
                    <Paco
                      pose="reussir"
                      text={`Ville validée ! ${c.retiens}${c.n < 15 ? ` Direction ${CITIES[c.n].name}.` : ''}`}
                    />
                  )}
                  <button className="villebtn" onClick={() => setScreen({ name: 'ville' })}>
                    <span>🏙️ Voir Ma Ville</span>
                    <small>Chaque niveau réussi fait passer une séance de bourse.</small>
                  </button>
                </>
              )}
            </main>
          );
        })()}

      {screen.name === 'ville' && (
        <CityView
          city={save.city}
          cash={save.savings}
          companies={unlockedCompanies(save)}
          citiesDone={citiesDone(save)}
          daysPlayed={save.days.length}
          sgiOpen={cityUnlocked(save, 2)}
          onChange={(city, cash) => setSave((s) => ({ ...s, city, savings: cash }))}
          onBack={() => setScreen({ name: 'map' })}
        />
      )}

      {screen.name === 'quiz' && (
        <QuizView city={screen.city} onDone={(score) => onQuiz(screen.city, score)} onQuit={() => setScreen({ name: 'city', city: screen.city })} />
      )}

      {screen.name === 'cards' && (
        <CardsView cards={save.cards} companies={unlockedCompanies(save)} onBack={() => setScreen({ name: 'map' })} />
      )}

      {screen.name === 'level' && (
        <Suspense fallback={<p className="fine">Chargement du niveau…</p>}>
        <LevelView
          key={screen.level.id}
          level={screen.level}
          onEnd={(r) => onEnd(screen.level, r)}
          onQuit={() => setScreen({ name: 'city', city: screen.level.city })}
        />
        </Suspense>
      )}
      {account && <AccountSheet onClose={() => setAccount(false)} />}
      {feedbackFor != null && <FeedbackSheet city={CITIES[feedbackFor - 1].name} onDone={(f) => onFeedback(feedbackFor, f)} />}
    </div>
  );
}
