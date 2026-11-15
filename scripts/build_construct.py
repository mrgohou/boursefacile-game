"""Package the editable Construct folder project; no engine/compiler is invoked."""
from pathlib import Path
import shutil,zipfile
root=Path(__file__).resolve().parents[1]
shutil.copyfile(root/'shared/engine.mjs',root/'construct3/scripts/engine.js')
with zipfile.ZipFile(root/'PACO-Construct3.c3p','w',zipfile.ZIP_DEFLATED) as z:
 for path in sorted((root/'construct3').rglob('*')):
  if path.is_file():
   info=zipfile.ZipInfo(str(path.relative_to(root/'construct3')),(2026,11,15,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED;z.writestr(info,path.read_bytes())
print('Archive de sources Construct créée (éditeur non exécuté).')
