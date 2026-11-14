"""Génère les bruitages et les deux musiques de PACO Bourse par synthèse (aucun échantillon externe).
Sortie : app/assets/audio/*.mp3. Usage : python3 scripts/gen_audio.py"""
import os, subprocess, tempfile
import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, lfilter

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', 'app', 'assets', 'audio')
rng = np.random.default_rng(7)

def t(d): return np.arange(int(d * SR)) / SR
def hz(n): return 440.0 * 2 ** ((n - 69) / 12)  # n = note MIDI

def env(d, a=0.003, dec=0.3):
    x = t(d); e = np.exp(-x / dec)
    na = max(1, int(a * SR)); e[:na] *= np.linspace(0, 1, na)
    return e

def lp(x, f, o=2): b, a = butter(o, f / (SR / 2)); return lfilter(b, a, x)
def hp(x, f, o=2): b, a = butter(o, f / (SR / 2), 'high'); return lfilter(b, a, x)
def bp(x, lo, hi): b, a = butter(2, [lo / (SR / 2), hi / (SR / 2)], 'band'); return lfilter(b, a, x)

def balafon(f, d=0.6, v=1.0):
    x = t(d)
    s = (np.sin(2*np.pi*f*x) * env(d, dec=.22) + .45*np.sin(2*np.pi*f*3.93*x) * env(d, dec=.06)
         + .18*np.sin(2*np.pi*f*9.1*x) * env(d, dec=.025))
    click = bp(rng.standard_normal(len(x)), 800, 4000) * env(d, a=.0005, dec=.006) * .3
    return (s + click) * v

def bell(f, d=0.9, v=1.0):
    x = t(d)
    return v * (np.sin(2*np.pi*f*x)*env(d, dec=.35) + .5*np.sin(2*np.pi*f*2.76*x)*env(d, dec=.15)
                + .25*np.sin(2*np.pi*f*5.4*x)*env(d, dec=.07))

def kick(d=0.35, v=1.0):
    x = t(d); f = 45 + 90*np.exp(-x/.04)
    return v * np.sin(2*np.pi*np.cumsum(f)/SR) * env(d, dec=.12)

def shaker(d=0.07, v=1.0):
    return v * .3 * hp(rng.standard_normal(int(d*SR)), 5000) * env(d, a=.004, dec=.02)

def conga(f=220, d=0.25, v=1.0):
    x = t(d); ff = f*(1+.3*np.exp(-x/.01))
    return v * (np.sin(2*np.pi*np.cumsum(ff)/SR)*env(d, dec=.09) + bp(rng.standard_normal(len(x)), 1500, 5000)*env(d, dec=.004)*.25)

def clap(d=0.18, v=1.0):
    n = bp(rng.standard_normal(int(d*SR)), 900, 3500)
    e = env(d, dec=.05)
    for k in (0.01, 0.02):
        tail = .6*env(d - k, dec=.01); e[int(k*SR):int(k*SR) + len(tail)] += tail[:len(e) - int(k*SR)]
    return v * n * e

def bass(f, d, v=1.0):
    x = t(d); e = np.minimum(1, x/.01) * np.exp(-x/.5)
    return v * (np.sin(2*np.pi*f*x) + .25*np.sin(4*np.pi*f*x)) * e

def pad(fs, d, v=1.0):
    x = t(d); s = np.zeros(len(x))
    for f in fs:
        for det in (-.004, .004):
            s += 2*((x*f*(1+det)) % 1) - 1
    s = lp(s, 1200)
    e = np.minimum(1, x/.15) * np.minimum(1, (d - x)/.2)
    return v * s / (len(fs)*2) * e

def mix(*xs):
    out = np.zeros(max(len(x) for x in xs))
    for x in xs: out[:len(x)] += x
    return out

def place(buf, snd, at):
    i = int(at * SR); j = min(len(buf), i + len(snd))
    if i < len(buf): buf[i:j] += snd[:j - i]

def norm(x, peak=.89): return x / (np.max(np.abs(x)) + 1e-9) * peak

def save(name, x, br='96k'):
    x = norm(x)
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as f:
        wavfile.write(f.name, SR, (x * 32767).astype(np.int16))
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', f.name, '-ac', '1', '-b:a', br,
                        os.path.join(OUT, name + '.mp3')], check=True)
    os.unlink(f.name)

# ---------------- Musiques (boucles sans couture) ----------------
def song(bpm, bars, chords, melody, drums, name, swing=0.0):
    beat = 60 / bpm; L = bars * 4 * beat
    buf = np.zeros(int((L + 2) * SR))
    for b in range(bars):
        root, tri = chords[b % len(chords)]
        place(buf, pad([hz(n) for n in tri], 4*beat, .35), b*4*beat)
        for k, (pos, oct_) in enumerate([(0, 0), (1.5, 0), (2, 0), (3, 1), (3.5, 0)]):
            place(buf, bass(hz(root - 24 + 12*oct_), beat*.9, .55), (b*4 + pos)*beat)
        drums(buf, b, beat)
    for (bar, pos, n, d) in melody:
        place(buf, balafon(hz(n), .7, .55), (bar*4 + pos)*beat)
    tail = buf[int(L*SR):]; buf = buf[:int(L*SR)]; buf[:len(tail)] += tail[:len(buf)]
    save(name, buf, '96k')

def drums_ville(buf, b, beat):
    for i in range(16):
        place(buf, shaker(v=.18 if i % 2 else .3), (b*4 + i/4)*beat)
    for p in (0, 2.5): place(buf, kick(v=.7), (b*4 + p)*beat)
    for p in (1, 3): place(buf, clap(v=.25), (b*4 + p)*beat)
    for p, f in ((1.75, 260), (2.25, 200), (3.5, 230)): place(buf, conga(f, v=.3), (b*4 + p)*beat)

def drums_puzzle(buf, b, beat):
    for i in range(16):
        place(buf, shaker(v=.22 if i % 2 else .34), (b*4 + i/4)*beat)
    for p in (0, 1, 2, 3): place(buf, kick(v=.75), (b*4 + p)*beat)
    for p in (1, 3): place(buf, clap(v=.32), (b*4 + p)*beat)
    for p, f in ((0.5, 250), (1.75, 300), (2.5, 220), (3.25, 280), (3.75, 240)): place(buf, conga(f, v=.32), (b*4 + p)*beat)

C, G, Am, F = (48, [60, 64, 67]), (43, [59, 62, 67]), (45, [60, 64, 69]), (41, [60, 65, 69])
pent = [60, 62, 64, 67, 69, 72, 74, 76, 79]
def riff(bars, pattern):
    out = []
    for b in range(bars):
        for pos, idx in pattern[b % len(pattern)]:
            out.append((b, pos, pent[idx], .3))
    return out
ville_pat = [[(0, 4), (0.75, 5), (1.5, 4), (2, 2), (3, 3)], [(0, 1), (0.75, 2), (1.5, 4), (2.5, 3), (3.5, 2)],
             [(0, 4), (0.5, 5), (1, 6), (2, 5), (3, 4)], [(0, 3), (1, 2), (1.5, 1), (2, 2), (3, 0)]]
puz_pat = [[(0, 5), (0.5, 4), (0.75, 5), (1.5, 6), (2, 5), (2.75, 4), (3.5, 2)],
           [(0, 3), (0.5, 4), (1, 5), (1.75, 4), (2.5, 3), (3, 2), (3.5, 3)],
           [(0, 5), (0.5, 7), (1, 6), (1.5, 5), (2.25, 6), (3, 7), (3.5, 8)],
           [(0, 6), (0.75, 5), (1.5, 4), (2, 3), (2.5, 2), (3, 1), (3.5, 2)]]
song(100, 8, [C, G, Am, F], riff(8, ville_pat), drums_ville, 'music_ville')
song(118, 8, [Am, F, C, G], riff(8, puz_pat), drums_puzzle, 'music_puzzle')

# ---------------- Bruitages ----------------
def seq(notes, gap, inst=balafon, d=.6, v=1.0):
    buf = np.zeros(int((gap*len(notes) + d)*SR))
    for i, n in enumerate(notes): place(buf, inst(hz(n), d, v), i*gap)
    return buf

def whoosh(d=.18, lo=600, hi=3000, up=True):
    n = rng.standard_normal(int(d*SR)); x = t(d); out = np.zeros_like(n)
    for k in range(8):
        a, b = int(k*len(n)/8), int((k+1)*len(n)/8)
        f = lo + (hi - lo)*(k/7 if up else 1 - k/7)
        out[a:b] = bp(n, f*.7, min(f*1.4, 20000))[a:b]
    return out * np.sin(np.pi*x/d)

save('tap', balafon(hz(84), .15, 1) * env(.15, dec=.04))
save('select', balafon(hz(79), .25))
save('swap', whoosh(.16) * .6)
x = t(.35); save('invalid', np.sin(2*np.pi*np.cumsum(220 - 120*x/.35)/SR) * env(.35, dec=.12) * np.sin(2*np.pi*14*x)**2)
for i in range(6):  # combos : la note monte à chaque cascade
    save(f'match{i+1}', mix(seq([pent[min(i+2, 8)], pent[min(i+4, 8)]], .05, balafon, .5), shaker(.12, .6)))
save('special', seq([72, 76, 79, 84, 88], .05, bell, .6, .7))
save('blast', mix(whoosh(.35, 3000, 300, up=False) * .8, kick(.35, 1.2)))
save('lock', mix(seq([88, 91], .04, bell, .3, .8), bp(rng.standard_normal(int(.3*SR)), 2500, 7000) * env(.3, dec=.02) * .4))
save('coin', seq([88, 95], .07, bell, .5))
save('star', seq([76, 81, 88], .09, bell, .9))
save('win', mix(seq([72, 76, 79, 84, 79, 84, 88], .12, balafon, .8), seq([60, 64, 67, 72], .24, bell, 1.2, .5)))
save('lose', seq([67, 64, 62, 60], .18, balafon, .9, .8))
save('buy', mix(seq([79, 84], .06, bell, .5), shaker(.1, 2)))
save('sell', seq([84, 79], .06, bell, .5))
save('start', seq([67, 72, 76], .08, balafon, .6))
save('cascade', seq([84, 88, 91, 96], .06, bell, .7, .8))
print(sorted(os.listdir(OUT)))
