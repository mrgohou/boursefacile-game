import { useState } from 'react';
import type { Feedback } from '../store';

const FACES: [1 | 2 | 3, string][] = [
  [1, '😕'],
  [2, '🙂'],
  [3, '😀'],
];

/** Questionnaire testeur (GDD §11) : 3 questions après chaque ville validée. */
export function FeedbackSheet({ city, onDone }: { city: string; onDone: (f: Feedback | null) => void }) {
  const [compris, setCompris] = useState<1 | 2 | 3 | null>(null);
  const [amusant, setAmusant] = useState<1 | 2 | 3 | null>(null);
  const [changer, setChanger] = useState('');
  const row = (value: number | null, set: (v: 1 | 2 | 3) => void) => (
    <div className="faces">
      {FACES.map(([v, f]) => (
        <button key={v} type="button" className={value === v ? 'on' : ''} onClick={() => set(v)} aria-label={`${v} sur 3`}>
          {f}
        </button>
      ))}
    </div>
  );
  return (
    <div className="overlay">
      <form
        className="card account"
        onSubmit={(e) => {
          e.preventDefault();
          if (compris && amusant) onDone({ compris, amusant, changer: changer.trim().slice(0, 500), at: new Date().toISOString() });
        }}
      >
        <h3>Ton avis sur {city}</h3>
        <p className="fine left">Tu testes PACO Bourse : tes réponses aident l'équipe à l'améliorer. Elles ne contiennent ni ton nom ni ton e-mail.</p>
        <label>As-tu compris la leçon ?</label>
        {row(compris, setCompris)}
        <label>C'était amusant ?</label>
        {row(amusant, setAmusant)}
        <label>Une chose à changer ? (facultatif)</label>
        <textarea rows={3} maxLength={500} value={changer} onChange={(e) => setChanger(e.target.value)} placeholder="Écris ici…" />
        <button className="btn" disabled={!compris || !amusant}>
          Envoyer
        </button>
        <button type="button" className="ghost small" onClick={() => onDone(null)}>
          Passer
        </button>
      </form>
    </div>
  );
}
