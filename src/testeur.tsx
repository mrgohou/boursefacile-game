import { StrictMode, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { cloudAvailable, sendSignup } from './cloud';
import './App.css';
import './testeur.css';

const base = import.meta.env.BASE_URL;
const PROFILS = ['Parent avec un enfant de 10 à 15 ans', 'Étudiant(e)', 'Adulte qui débute en bourse', 'Déjà investisseur à la BRVM'];

function Page() {
  const [form, setForm] = useState({ prenom: '', contact: '', commune: '', profil: '', majeur: false, accord: false });
  const [state, setState] = useState<'idle' | 'sending' | 'done' | 'error' | 'preview'>('idle');
  const set = (k: keyof typeof form) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) =>
    setForm({ ...form, [k]: e.target.type === 'checkbox' ? (e.target as HTMLInputElement).checked : e.target.value });

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!cloudAvailable()) return setState('preview');
    setState('sending');
    try {
      await sendSignup({ ...form, prenom: form.prenom.trim().slice(0, 40), contact: form.contact.trim().slice(0, 80), commune: form.commune.trim().slice(0, 60) });
      setState('done');
    } catch {
      setState('error');
    }
  };

  return (
    <div className="landing">
      <header className="top">
        <div className="brand">
          <span className="logo">P</span>
          <b>PACO Bourse</b>
        </div>
      </header>

      <section className="hero">
        <p className="kicker">Bêta fermée · 100 places · Côte d'Ivoire</p>
        <h1>Ton enfant apprend la bourse avant toi ?</h1>
        <p className="lead">
          PACO Bourse, c'est un jeu où l'on aligne des tuiles pour épargner, puis où l'on investit dans les <b>vraies entreprises de la BRVM</b>. Paco l'éléphant explique tout, ville après ville.
        </p>
        <img className="hero-paco" src={`${base}paco/accueil.webp`} alt="Paco l'éléphant" />
      </section>

      <section className="why">
        {[
          ['tiles/cacao.webp', 'Joue', 'Des puzzles de 2 minutes, simples comme un jeu de bonbons.'],
          ['buildings/banque-3.webp', 'Investis', 'Achète des parts des entreprises cotées à la BRVM, au vrai cours du jour, avec de l’argent fictif.'],
          ['paco/patience.webp', 'Récolte avec patience', 'Dividendes, AGO, diversification : on gagne en étant sage, pas en étant riche.'],
        ].map(([img, t, d]) => (
          <div key={t} className="why-item">
            <img src={`${base}${img}`} alt="" />
            <div>
              <b>{t}</b>
              <p>{d}</p>
            </div>
          </div>
        ))}
      </section>

      <section className="signup">
        {state === 'done' ? (
          <div className="thanks">
            <img src={`${base}paco/reussir.webp`} alt="" />
            <h2>Bienvenue dans l'équipe, {form.prenom || 'testeur'} !</h2>
            <p>On te contacte dès l'ouverture de la bêta. En attendant, l'app Bourse Facile t'attend.</p>
          </div>
        ) : (
          <form onSubmit={submit}>
            <h2>Deviens l'un des 100 premiers testeurs</h2>
            <input required placeholder="Prénom" value={form.prenom} onChange={set('prenom')} maxLength={40} />
            <input required placeholder="WhatsApp ou e-mail" value={form.contact} onChange={set('contact')} maxLength={80} />
            <input required placeholder="Commune ou ville (ex. Cocody, Bouaké)" value={form.commune} onChange={set('commune')} maxLength={60} />
            <select required value={form.profil} onChange={set('profil')}>
              <option value="" disabled>
                Tu es…
              </option>
              {PROFILS.map((p) => (
                <option key={p}>{p}</option>
              ))}
            </select>
            <label className="check">
              <input type="checkbox" required checked={form.majeur} onChange={set('majeur')} />
              J'ai 18 ans ou plus. Les enfants jouent avec le compte d'un parent.
            </label>
            <label className="check">
              <input type="checkbox" required checked={form.accord} onChange={set('accord')} />
              J'accepte que Bourse Facile garde ces informations pour me contacter au sujet de la bêta, puis les supprime au lancement public.
            </label>
            <button className="btn big" disabled={state === 'sending'}>
              {state === 'sending' ? 'Envoi…' : 'Je veux tester'}
            </button>
            {state === 'error' && <p className="error">L'envoi n'a pas marché. Réessaie dans un instant.</p>}
            {state === 'preview' && <p className="error">Aperçu : l'inscription fonctionnera sur la version en ligne du jeu.</p>}
          </form>
        )}
      </section>

      <p className="fine">
        PACO Bourse est un jeu éducatif : argent fictif, aucun conseil d'investissement. Les performances passées ne garantissent pas les résultats futurs.
      </p>
    </div>
  );
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <Page />
  </StrictMode>,
);
