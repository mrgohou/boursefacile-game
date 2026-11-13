export type Pose = 'accueil' | 'confiance' | 'reflechir' | 'expliquer' | 'apprendre' | 'analyser' | 'progresser' | 'reussir' | 'attention' | 'patience' | 'reconfort';

export function Paco({ pose, text, onClose, cta = 'OK' }: { pose: Pose; text: string; onClose?: () => void; cta?: string }) {
  return (
    <div className="paco">
      <img src={`${import.meta.env.BASE_URL}paco/${pose}.webp`} alt="Paco" className="paco-img" />
      <div className="bubble">
        <p>{text}</p>
        {onClose && (
          <button className="btn" onClick={onClose}>
            {cta}
          </button>
        )}
      </div>
    </div>
  );
}
