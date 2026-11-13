import { useState } from 'react';
import { signInEmail, signInGoogle } from '../cloud';

const MESSAGES: Record<string, string> = {
  'auth/invalid-credential': 'E-mail ou mot de passe incorrect.',
  'auth/email-already-in-use': 'Ce compte existe déjà : connecte-toi.',
  'auth/weak-password': 'Mot de passe trop court (6 caractères minimum).',
  'auth/popup-blocked': 'La fenêtre Google a été bloquée par le navigateur.',
  'auth/unauthorized-domain': 'Ce site n’est pas encore autorisé dans Firebase.',
};

/** Connexion avec le compte Bourse Facile d'un parent (Google ou e-mail). */
export function AccountSheet({ onClose }: { onClose: () => void }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [create, setCreate] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const run = async (f: () => Promise<unknown>) => {
    setBusy(true);
    setError(null);
    try {
      await f();
      onClose();
    } catch (e) {
      const code = (e as { code?: string }).code ?? '';
      setError(MESSAGES[code] ?? 'Connexion impossible pour le moment.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="overlay" onClick={onClose}>
      <form
        className="card account"
        onClick={(e) => e.stopPropagation()}
        onSubmit={(e) => {
          e.preventDefault();
          void run(() => signInEmail(email, password, create));
        }}
      >
        <h3>Ton compte Bourse Facile</h3>
        <p className="fine left">
          Le même compte que l'app Bourse Facile. Pour les enfants : utilisez le compte d'un parent. Le jeu ne garde que la
          progression, ni nom ni e-mail.
        </p>
        <button type="button" className="btn" disabled={busy} onClick={() => run(signInGoogle)}>
          Continuer avec Google
        </button>
        <input type="email" required placeholder="Adresse e-mail" value={email} onChange={(e) => setEmail(e.target.value)} />
        <input type="password" required minLength={6} placeholder="Mot de passe" value={password} onChange={(e) => setPassword(e.target.value)} />
        <button type="submit" className="btn" disabled={busy}>
          {create ? 'Créer mon compte' : 'Se connecter'}
        </button>
        <button type="button" className="ghost small" onClick={() => setCreate(!create)}>
          {create ? 'J’ai déjà un compte' : 'Créer un compte par e-mail'}
        </button>
        {error && <p className="error">{error}</p>}
      </form>
    </div>
  );
}
