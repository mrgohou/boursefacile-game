#!/usr/bin/env python3
"""Optional C# compatibility compile against external Unity 2021/UGUI reference DLLs.
This catches type/syntax mistakes; it DOES NOT execute Unity or validate Unity 6 APIs.
Toolchain and DLLs are external and never shipped in the project.
"""
import pathlib,subprocess,os,argparse
p=argparse.ArgumentParser();p.add_argument('toolchain',type=pathlib.Path);a=p.parse_args();t=a.toolchain
root=pathlib.Path(__file__).resolve().parents[1];out=root/'Builds/CompatibilityCompile';out.mkdir(parents=True,exist_ok=True)
refs=list((t/'refs/ref/net8.0').glob('*.dll'))+list((t/'unityengine.modules').rglob('*.dll'))+list((t/'unity3d.unityengine.ui').rglob('*.dll'))+[t/'json/lib/netstandard2.0/Newtonsoft.Json.dll']
args=['-nologo','-define:UNITY_ANDROID','-target:library','-nostdlib+','-out:'+str(out/'Paco.Compatibility.dll')]+['-r:'+str(f) for f in refs]+[str(f) for f in (root/'Assets/Paco').rglob('*.cs') if '/Editor/' not in str(f) and '/Tests/' not in str(f)]
rsp=out/'compile.rsp';rsp.write_text('\n'.join('"'+s+'"' for s in args));env={**os.environ,'DOTNET_ROLL_FORWARD':'Major'}
subprocess.run([os.environ.get('DOTNET','dotnet'),str(t/'roslyn/tasks/netcore/bincore/csc.dll'),'@'+str(rsp)],check=True,env=env)
