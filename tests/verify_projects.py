from pathlib import Path
import json,zipfile,ast
root=Path(__file__).resolve().parents[1]
for f in root.rglob('*.json'):json.loads(f.read_text())
for f in (root/'unreal/Scripts').glob('*.py'):ast.parse(f.read_text())
c=root/'construct3';p=json.loads((c/'project.c3proj').read_text());assert p['viewportWidth']==540 and p['viewportHeight']==960;assert p['firstLayout']=='Main';assert p['useWorker']=='no';assert p['properties']['scriptsType']=='module'
for kind,folder in [('layouts','layouts'),('eventSheets','eventSheets'),('objectTypes','objectTypes')]:
 for name in p[kind]['items']:assert(c/folder/(name+'.json')).exists()
for i in range(6):assert(c/'images'/f'piece-default-{i:03}.png').exists()
for f in p['rootFileFolders']['script']['items']:assert(c/'scripts'/f['name']).exists()
for f in p['rootFileFolders']['general']['items']:assert(c/'files'/f['name']).exists()
assert (c/'scripts/engine.js').read_bytes()==(root/'shared/engine.mjs').read_bytes()
for f in [c/'files/catalog.json',root/'unreal/Content/Data/catalog.json']:assert f.read_bytes()==(root/'shared/catalog.json').read_bytes()
u=json.loads((root/'unreal/PacoUnreal.uproject').read_text());assert u['Modules'][0]['Name']=='PacoUnreal';assert len(list((root/'unreal/SourceArt').glob('*.fbx')))==21
with zipfile.ZipFile(root/'PACO-Construct3.c3p') as z:
 assert z.testzip() is None
 assert 'project.c3proj' in z.namelist()
 for f in c.rglob('*'):
  if f.is_file():assert z.read(str(f.relative_to(c)))==f.read_bytes()
print('Structure des projets et archive cohérentes. Aucun éditeur moteur exécuté.')
