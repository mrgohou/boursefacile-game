import { useMemo, useState } from 'react';
import { QUIZ } from '../data/quiz';
import { rng } from '../engine/board';
import { Paco } from './Paco';
import { sfx } from '../audio';

/** Quiz de Paco : 3 questions, 2 bonnes réponses pour débloquer la ville suivante. */
export function QuizView({ city, onDone, onQuit }: { city: number; onDone: (score: number) => void; onQuit: () => void }) {
  const questions = QUIZ[city];
  const [i, setI] = useState(0);
  const [picked, setPicked] = useState<string | null>(null);
  const [score, setScore] = useState(0);
  const [attempt] = useState(() => Math.floor(Math.random() * 1e6));

  const options = useMemo(() => {
    const q = questions[i];
    if (!q) return [];
    const r = rng(attempt + i * 31);
    const o = [...q.a];
    for (let k = o.length - 1; k > 0; k--) {
      const j = Math.floor(r() * (k + 1));
      [o[k], o[j]] = [o[j], o[k]];
    }
    return o;
  }, [questions, i, attempt]);

  if (i >= questions.length) {
    const ok = score >= 2;
    return (
      <main className="quiz">
        <h2>{ok ? 'Quiz réussi !' : 'Presque !'}</h2>
        <p className="big">{score} / 3</p>
        <Paco
          pose={ok ? (score === 3 ? 'reussir' : 'confiance') : 'reflechir'}
          text={
            ok
              ? score === 3
                ? 'Sans faute ! Tu gagnes une carte entreprise pour ta collection.'
                : 'Bravo, la ville suivante est ouverte !'
              : 'Il faut 2 bonnes réponses. Relis la leçon de la ville et réessaie, rien n’est perdu.'
          }
          onClose={() => onDone(score)}
          cta={ok ? 'Continuer' : 'Retour'}
        />
      </main>
    );
  }

  const q = questions[i];
  const good = q.a[0];
  return (
    <main className="quiz">
      <button className="ghost back" onClick={onQuit}>
        ← Ville
      </button>
      <p className="step">
        Question {i + 1} / {questions.length}
      </p>
      <h2>{q.q}</h2>
      <div className="answers">
        {options.map((o) => {
          const state = picked == null ? '' : o === good ? 'good' : o === picked ? 'bad' : 'dim';
          return (
            <button
              key={o}
              className={`answer ${state}`}
              disabled={picked != null}
              onClick={() => {
                setPicked(o);
                if (o === good) {
                  setScore((s) => s + 1);
                  sfx('coin');
                } else sfx('nope');
              }}
            >
              {o}
            </button>
          );
        })}
      </div>
      {picked != null && (
        <Paco
          pose={picked === good ? 'confiance' : 'expliquer'}
          text={(picked === good ? 'Exact ! ' : 'Pas tout à fait. ') + q.why}
          onClose={() => {
            setPicked(null);
            setI(i + 1);
          }}
          cta="Suivant"
        />
      )}
    </main>
  );
}
