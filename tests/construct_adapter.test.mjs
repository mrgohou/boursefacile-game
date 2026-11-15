import test from 'node:test';import assert from 'node:assert/strict';import {readFileSync} from 'node:fs';
test('contrôleur Construct : démarrage, menu, ouverture 9×9 et retour',async()=>{
 const handlers={},project={};const instances=[];let id=0;
 globalThis.runOnStartup=fn=>project.start=fn;globalThis.localStorage={getItem:()=>null,setItem:()=>{}};globalThis.alert=()=>{};globalThis.addEventListener=(n,fn)=>handlers[n]=fn;
 const originalFetch=globalThis.fetch;globalThis.fetch=async()=>({json:async()=>JSON.parse(readFileSync(new URL('../shared/catalog.json',import.meta.url)))});
 const type={createInstance:(_layer,x,y)=>{const o={id:++id,x,y,destroy(){o.dead=true;}};instances.push(o);return o;},getAllInstances:()=>[]};
 const runtime={objects:{Label:type,Piece:type},assets:{getProjectFileUrl:async()=>''},layout:{getLayer:()=>({cssPxToLayer:(x,y)=>[x,y]})},addEventListener:(n,fn)=>project[n]=fn};
 try{await import('../construct3/scripts/main.js');await project.start(runtime);await project.beforeprojectstart();assert(instances.some(o=>o.text?.startsWith('Jouer')));handlers.pointerdown({clientX:270,clientY:250});handlers.pointerup({clientX:270,clientY:250});assert.equal(instances.filter(o=>!o.dead&&o.animationFrame!==undefined).length,81);handlers.pointerdown({clientX:270,clientY:875});handlers.pointerup({clientX:270,clientY:875});assert(instances.some(o=>!o.dead&&o.text==='Mes cartes'));}finally{globalThis.fetch=originalFetch;}
});
