import { useEffect, useRef, useState } from 'react';
import Phaser from 'phaser';
import { PuzzleScene } from '../game/PuzzleScene';
import {
  applySteps,
  emptyProgress,
  isWon,
  objectiveDone,
  savingsEarned,
  stars,
  type LevelDef,
  type Objective,
  type Progress,
} from '../engine/board';
import { Paco } from './Paco';
import { sfx } from '../audio';

const LABEL: Record<string, string> = {
  cacao: 'cacao',
  telephone: 'téléphones',
  billet: 'billets',
  bidon: 'bidons',
  ampoule: 'ampoules',
  engrenage: 'engrenages',
};

function objText(o: Objective, p: Progress) {
  if (o.kind === 'collect') return `${Math.min(p.collected[o.tile] ?? 0, o.count)}/${o.count}`;
  if (o.kind === 'score') return `${Math.min(p.score, o.target)}/${o.target}`;
  return `${Math.min(p.unlocked, o.count)}/${o.count}`;
}

function objIcon(o: Objective) {
  const base = import.meta.env.BASE_URL;
  if (o.kind === 'collect') return <img src={`${base}tiles/${o.tile}.svg`} alt={LABEL[o.tile]} />;
  if (o.kind === 'unlock') return <img src={`${base}tiles/cadenas.svg`} alt="cadenas" />;
  return <span className="pts">pts</span>;
}

export interface LevelResult {
  won: boolean;
  stars: number;
  savings: number;
}

export function LevelView({ level, onEnd, onQuit }: { level: LevelDef; onEnd: (r: LevelResult) => void; onQuit: () => void }) {
  const host = useRef<HTMLDivElement>(null);
  const [progress, setProgress] = useState<Progress>(() => emptyProgress(level));
  const [phase, setPhase] = useState<'intro' | 'play' | 'won' | 'lost'>('intro');
  const [fails, setFails] = useState(0);
  const [round, setRound] = useState(0);
  const pRef = useRef(progress);
  const phaseRef = useRef(phase);
  pRef.current = progress;
  phaseRef.current = phase;

  useEffect(() => {
    if (!host.current) return;
    const scene = new PuzzleScene();
    const game = new Phaser.Game({
      type: Phaser.AUTO,
      parent: host.current,
      transparent: true,
      scale: { mode: Phaser.Scale.RESIZE, width: host.current.clientWidth, height: host.current.clientHeight },
      scene: [],
      audio: { noAudio: true },
    });
    game.scene.add('puzzle', scene, true, {
      level,
      cb: {
        canPlay: () => phaseRef.current === 'play',
        onSteps: (steps: Parameters<typeof applySteps>[1]) => {
          const next = applySteps(pRef.current, steps);
          pRef.current = next;
          setProgress(next);
        },
        onSettled: () => {
          const p = pRef.current;
          if (isWon(level, p)) {
            sfx('win');
            setPhase('won');
          } else if (p.movesLeft <= 0) {
            sfx('lose');
            setFails((f) => f + 1);
            setPhase('lost');
          }
        },
      },
    });
    return () => game.destroy(true);
  }, [level, round]);

  const retry = () => {
    const p = emptyProgress(level);
    pRef.current = p;
    setProgress(p);
    setRound((r) => r + 1);
    setPhase('intro');
  };

  const s = stars(level, progress);
  const earned = savingsEarned(progress);

  return (
    <div className="level">
      <header className="hud">
        <button className="ghost" onClick={onQuit} aria-label="Retour">
          ←
        </button>
        <div className="moves">
          <b>{progress.movesLeft}</b>
          <small>coups</small>
        </div>
        <div className="objs">
          {level.objectives.map((o, i) => (
            <div key={i} className={`obj ${objectiveDone(o, progress) ? 'done' : ''}`}>
              {objIcon(o)}
              <span>{objText(o, progress)}</span>
            </div>
          ))}
        </div>
      </header>

      <div className="board" ref={host} />

      {phase === 'intro' && (
        <div className="overlay">
          <Paco pose="expliquer" text={level.pacoBefore} onClose={() => setPhase('play')} cta="C'est parti !" />
        </div>
      )}
      {phase === 'won' && (
        <div className="overlay">
          <div className="result">
            <div className="stars">{'★'.repeat(s) + '☆'.repeat(3 - s)}</div>
            <p className="gain">+ {earned.toLocaleString('fr-FR')} FCFA-jeu d'épargne</p>
            <Paco
              pose={s === 3 ? 'reussir' : 'confiance'}
              text={
                progress.movesLeft > 0
                  ? `Bravo ! Tes ${progress.movesLeft} coups restants deviennent de l'épargne.`
                  : 'Bravo, objectif atteint ! Garder des coups en réserve, ça rapporte plus.'
              }
              onClose={() => {
                sfx('coin');
                onEnd({ won: true, stars: s, savings: earned });
              }}
              cta="Encaisser"
            />
          </div>
        </div>
      )}
      {phase === 'lost' && (
        <div className="overlay">
          <Paco
            pose="reflechir"
            text={fails >= 2 ? level.pacoHint : 'Presque ! On réessaie ? Tu ne perds rien, chaque essai t’entraîne.'}
            onClose={retry}
            cta="Rejouer"
          />
        </div>
      )}
    </div>
  );
}
