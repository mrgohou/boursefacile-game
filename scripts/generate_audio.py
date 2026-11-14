#!/usr/bin/env python3
"""Original PACO procedural score. Python standard library only; deterministic PCM."""
import math
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
OUT.mkdir(parents=True, exist_ok=True)


def write(name, samples):
    import array
    if name not in ('city', 'puzzle'):
        fade = min(int(RATE * .025), len(samples))
        for i in range(fade):
            samples[-fade + i] *= (fade - 1 - i) / fade
    peak = max(max(map(abs, samples)), 1)
    data = array.array('h', (round(x / peak * (26000 if name in ('city', 'puzzle') else 11000)) for x in samples))
    import sys
    if sys.byteorder != 'little':
        data.byteswap()
    with wave.open(str(OUT / (name + '.wav')), 'wb') as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(data.tobytes())


def note(buf, start, duration, midi, gain, pad=False, wrap=False):
    freq = 440 * 2 ** ((midi - 69) / 12)
    count = int(duration * RATE)
    for i in range(count):
        t = i / RATE
        env = math.sin(math.pi * i / count) ** 2 if pad else (1 - math.exp(-t * 150)) * math.exp(-t * 6) * min(1, (count - i) / (RATE * .06))
        sample = gain * env * (math.sin(2 * math.pi * freq * t) + .22 * math.sin(4 * math.pi * freq * t))
        pos = int(start * RATE) + i
        if wrap:
            buf[pos % len(buf)] += sample
        elif pos < len(buf):
            buf[pos] += sample


for scene, roots, melody in [
    ('city', [48, 53, 55, 48], [72, 76, 79, 76, 74, 77, 81, 77, 74, 79, 83, 79, 76, 79, 84, 79]),
    ('puzzle', [50, 55, 57, 50], [74, 77, 81, 86, 81, 77, 79, 83, 86, 83, 81, 77, 76, 81, 85, 81]),
]:
    buf = [0.] * (RATE * 14)
    for bar, root in enumerate(roots):
        for pitch in [root, root + 7, root + 12]:
            note(buf, bar * 3.5, 3.9, pitch, .045, pad=True, wrap=True)
    for step, pitch in enumerate(melody):
        note(buf, step * .875, .75, pitch, .14, wrap=True)
        note(buf, step * .875 + .4375, .4, roots[step // 4] + 24, .04, wrap=True)
    write(scene, buf)

sounds = {
    'select': ([76], .14), 'swap': ([72, 79], .18),
    'invalid': ([55, 52], .22), 'match': ([76, 81, 84], .32),
    'cascade': ([79, 84, 88, 91], .42), 'win': ([72, 76, 79, 84, 88], 1.1),
    'lose': ([67, 64, 60], .65), 'shuffle': ([72, 79, 74, 81], .4),
    'ui': ([81], .12),
}
for name, (pitches, duration) in sounds.items():
    buf = [0.] * int(RATE * duration)
    for index, pitch in enumerate(pitches):
        note(buf, index * duration / (len(pitches) + 1), duration * .55, pitch, .3)
    write(name, buf)
print('Generated original PCM WAV assets:', sum(p.stat().st_size for p in OUT.glob('*.wav')), 'bytes')
