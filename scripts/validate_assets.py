#!/usr/bin/env python3
"""Validate source assets and assembly references without claiming a Unity import."""
import pathlib,json,struct,hashlib
root=pathlib.Path(__file__).resolve().parents[1];data=root/'Assets/Paco/Resources/Data'
stages=json.loads((data/'stages.json').read_text())['stages'];lessons=json.loads((data/'lessons.json').read_text())['lessons'];dest=json.loads((data/'journey.json').read_text())['destinations']
assert len(stages)==len(lessons)==30 and len(dest)==15
assert all(len(d['questions'])==3 for d in dest)
models=['house','farm','shop','telecom','bank','factory','energy','services','tree','palm','car','person','fountain','tile_cacao','tile_phone','tile_cash','tile_fuel','tile_bulb','tile_gear','title_win','title_lose']
for n in models:
 f=root/'Assets/Paco/Resources/Models'/f'{n}.fbx'
 assert f.read_bytes().startswith(b'Kaydara FBX Binary') and f.stat().st_size>1000,n
for f in root.glob('Assets/Paco/**/*.asmdef'):
 d=json.loads(f.read_text());assert 'Unity.Newtonsoft.Json' not in d.get('references',[]) and 'Unity.ugui' not in d.get('references',[])
world=json.loads((data/'world.json').read_text())['objects'];assert sum(x['kind']=='land' for x in world)==6
for x in world:assert x['model'] in models
for n in ['city','puzzle','swap','select','ui','match','cascade','invalid','shuffle','win','lose']:
 b=(root/'Assets/Paco/Resources/Audio'/f'{n}.wav').read_bytes();assert b[:4]==b'RIFF' and b[8:12]==b'WAVE'
manifest=json.loads((root/'Packages/manifest.json').read_text());assert manifest['dependencies']['com.unity.render-pipelines.universal']=='17.0.4'
print('21 original FBX models, 11 WAV, 30 stages, 30 lessons, 15 destinations / 45 quizzes, six purchasable plots: source validation passed.')
print('Unity import, URP rendering, EditMode/PlayMode tests and APK compilation remain separate checks.')
