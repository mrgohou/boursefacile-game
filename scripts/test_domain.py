#!/usr/bin/env python3
"""Compile and run the real Unity-independent C# rules with an installed .NET SDK.
The optional --toolchain path supports a standalone runtime + Roslyn/ref pack.
Does not claim to validate UnityEngine, a scene, URP, or an APK.
"""
import argparse, pathlib, subprocess, os, json
p=argparse.ArgumentParser();p.add_argument('--toolchain',type=pathlib.Path);a=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[1];out=root/'Builds'/'DomainTests';out.mkdir(parents=True,exist_ok=True)
if a.toolchain:
 t=a.toolchain;refs=list((t/'refs/ref/net8.0').glob('*.dll'));jsondll=t/'json/lib/netstandard2.0/Newtonsoft.Json.dll'
 import shutil
 shutil.copy(jsondll,out/'Newtonsoft.Json.dll')
 args=['-nologo','-noconfig','-nostdlib+','-target:exe','-out:'+str(out/'DomainTests.dll')]+['-r:'+str(f) for f in refs+[jsondll]]+[str(f) for f in (root/'Assets/Paco/Domain').glob('*.cs')]+[str(root/'scripts/DomainTests.cs')]
 rsp=out/'compile.rsp';rsp.write_text('\n'.join('"'+s+'"' for s in args))
 dotnet=os.environ.get('DOTNET','dotnet');env={**os.environ,'DOTNET_ROLL_FORWARD':'Major'}
 subprocess.run([dotnet,str(t/'roslyn/tasks/netcore/bincore/csc.dll'),'@'+str(rsp)],check=True,env=env)
 (out/'DomainTests.runtimeconfig.json').write_text(json.dumps({'runtimeOptions':{'tfm':'net8.0','framework':{'name':'Microsoft.NETCore.App','version':'8.0.22'}}}))
 subprocess.run([dotnet,str(out/'DomainTests.dll'),str(root)],check=True,env=env)
else:
 subprocess.run(['dotnet','run','--project',str(root/'scripts/Paco.DomainTests.csproj'),'--',str(root)],check=True)
