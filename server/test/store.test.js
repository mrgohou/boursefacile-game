import test from 'node:test';
import assert from 'node:assert/strict';
import {createStore} from '../src/store.js';
// Serial transaction fake stages writes until callback succeeds. Not a Firestore emulator.
function fakeDb(){const docs=new Map();let queue=Promise.resolve();return {docs,doc:path=>path,runTransaction(fn){const promise=queue.then(async()=>{const writes=new Map();const get=async ref=>({exists:docs.has(ref),data:()=>structuredClone(docs.get(ref))});const tx={get,getAll:(...refs)=>Promise.all(refs.map(get)),set:(ref,data)=>writes.set(ref,structuredClone(data)),create:(ref,data)=>{if(docs.has(ref))throw Error('exists');writes.set(ref,structuredClone(data));}};const result=await fn(tx);for(const [key,value]of writes)docs.set(key,value);return result;});queue=promise.catch(()=>{});return promise;}};}
const action={type:'buy',companyId:'cacao',quantity:1,expectedVersion:0};
test('initialization, isolation and exactly-once replay return original receipt',async()=>{
 const db=fakeDb(),store=createStore(db,()=>1000);
 assert.equal((await store.player('alice')).state.cash,10000);
 const first=await store.action('alice','key1',action);const replay=await store.action('alice','key1',action);
 assert.equal(first.state.cash,7975);assert.equal(replay.state.cash,7975);assert.equal(replay.replayed,true);
 assert.equal((await store.player('bob')).state.cash,10000);
 await assert.rejects(store.action('alice','key1',{...action,type:'sell'}),{code:'IDEMPOTENCY_CONFLICT'});
 assert.equal(db.docs.get('users/alice/state/main').cash,7975);
});
test('same optimistic version cannot commit twice; failed actions still consume quota',async()=>{
 const db=fakeDb(),store=createStore(db,()=>1000);
 const results=await Promise.allSettled([store.action('a','k1',action),store.action('a','k2',action)]);
 assert.equal(results.filter(r=>r.status==='fulfilled').length,1);
 assert.equal(db.docs.get('users/a/state/main').cash,7975);
 assert.equal(db.docs.get('users/a/limits/api').tokens,28);
 for(let i=0;i<28;i++)await assert.rejects(store.action('a',`fail${i}`,action),{code:'VERSION_CONFLICT'});
 await assert.rejects(store.player('a'),{code:'RATE_LIMITED'});
});
