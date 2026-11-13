// Sons et musique synthétisés (Web Audio) : aucun fichier à charger, rien à licencier.
// Instrument de base : un timbre court et boisé, proche du balafon.

let ctx: AudioContext | null = null;
let master: GainNode | null = null;
let musicTimer: number | null = null;
let muted = localStorage.getItem('paco.muted') === '1';

function audio() {
  if (!ctx) {
    ctx = new AudioContext();
    master = ctx.createGain();
    master.gain.value = muted ? 0 : 0.6;
    master.connect(ctx.destination);
  }
  if (ctx.state === 'suspended') void ctx.resume();
  return { ctx, out: master! };
}

function note(freq: number, at: number, dur = 0.25, vol = 0.25, type: OscillatorType = 'triangle') {
  const { ctx, out } = audio();
  const o = ctx.createOscillator();
  const g = ctx.createGain();
  o.type = type;
  o.frequency.value = freq;
  g.gain.setValueAtTime(0, at);
  g.gain.linearRampToValueAtTime(vol, at + 0.01);
  g.gain.exponentialRampToValueAtTime(0.001, at + dur);
  o.connect(g).connect(out);
  o.start(at);
  o.stop(at + dur + 0.05);
}

// Gamme pentatonique (do majeur pentatonique).
const PENTA = [261.63, 293.66, 329.63, 392.0, 440.0, 523.25, 587.33, 659.25, 783.99, 880.0];

export type Sfx = 'tap' | 'nope' | 'match' | 'special' | 'unlock' | 'win' | 'lose' | 'coin';

export function sfx(kind: Sfx, combo = 0) {
  if (muted) return;
  const { ctx } = audio();
  const t = ctx.currentTime;
  switch (kind) {
    case 'tap':
      note(PENTA[5], t, 0.08, 0.12);
      break;
    case 'nope':
      note(196, t, 0.12, 0.15, 'square');
      note(174.6, t + 0.1, 0.15, 0.15, 'square');
      break;
    case 'match':
      note(PENTA[Math.min(combo + 2, PENTA.length - 1)], t, 0.22);
      break;
    case 'special':
      [0, 2, 4].forEach((k, i) => note(PENTA[k + 3], t + i * 0.07, 0.25));
      break;
    case 'unlock':
      note(PENTA[7], t, 0.15, 0.2, 'sine');
      note(PENTA[9], t + 0.08, 0.3, 0.2, 'sine');
      break;
    case 'coin':
      note(1318.5, t, 0.08, 0.15, 'square');
      note(1760, t + 0.07, 0.2, 0.15, 'square');
      break;
    case 'win':
      [0, 2, 4, 5, 7, 9].forEach((k, i) => note(PENTA[k], t + i * 0.1, 0.35));
      break;
    case 'lose':
      [4, 2, 0].forEach((k, i) => note(PENTA[k] / 2, t + i * 0.18, 0.4, 0.2, 'sine'));
      break;
  }
}

/** Boucle musicale douce : basse + motif de balafon, tempo calme. */
export function startMusic() {
  if (musicTimer !== null || muted) return;
  const { ctx } = audio();
  const beat = 0.32;
  const pattern = [0, 2, 4, 2, 5, 4, 2, 1, 0, 2, 4, 5, 7, 5, 4, 2];
  const bass = [0, 0, 3, 3, 4, 4, 3, 3];
  let bar = 0;
  const schedule = () => {
    const t0 = ctx.currentTime + 0.05;
    pattern.forEach((k, i) => {
      if (i % 2 === 1 && (bar + i) % 3 === 0) return; // respiration
      note(PENTA[k], t0 + i * beat, 0.3, 0.08);
    });
    for (let i = 0; i < 8; i++) note(PENTA[bass[(i + bar) % 8]] / 2, t0 + i * beat * 2, 0.6, 0.07, 'sine');
    bar++;
  };
  schedule();
  musicTimer = window.setInterval(schedule, pattern.length * beat * 1000);
}

export function stopMusic() {
  if (musicTimer !== null) window.clearInterval(musicTimer);
  musicTimer = null;
}

export function isMuted() {
  return muted;
}

export function setMuted(m: boolean) {
  muted = m;
  localStorage.setItem('paco.muted', m ? '1' : '0');
  if (master) master.gain.value = m ? 0 : 0.6;
  if (m) stopMusic();
  else startMusic();
}
