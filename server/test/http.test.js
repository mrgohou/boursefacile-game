import test from 'node:test';
import assert from 'node:assert/strict';
import {createApp} from '../src/app.js';
const key='65a4cb67-a091-4f71-9e45-edbb2d251d9a';
test('HTTP health independent, authentication fail closed and strict payload',async t=>{
 let calls=0;
 const app=createApp({verifyIdToken:async token=>{if(token!=='valid')throw Error('secret');return {uid:'alice'};},verifyAppCheck:async token=>{if(token!=='valid')throw Error('secret');return {appId:'app'};},store:{player:async uid=>({uid}),action:async(uid,k,action)=>{calls++;return {uid,k,action};}}});
 const server=app.listen(0,'127.0.0.1');await new Promise(r=>server.once('listening',r));t.after(()=>server.close());const url=`http://127.0.0.1:${server.address().port}`;
 assert.equal((await fetch(url+'/healthz')).status,200);
 assert.equal((await fetch(url+'/v1/player')).status,401);
 const headers={Authorization:'Bearer valid','X-Firebase-AppCheck':'valid','Idempotency-Key':key,'Content-Type':'application/json'};
 assert.equal((await fetch(url+'/v1/player',{headers})).status,200);
 assert.equal((await fetch(url+'/v1/player',{headers:{...headers,'X-Firebase-AppCheck':'bad'}})).status,401);
 const action={type:'buy',companyId:'cacao',quantity:1,expectedVersion:0};
 assert.equal((await fetch(url+'/v1/actions',{method:'POST',headers,body:JSON.stringify({...action,cash:99999})})).status,400);
 assert.equal((await fetch(url+'/v1/actions',{method:'POST',headers,body:JSON.stringify(action)})).status,200);assert.equal(calls,1);
 assert.equal((await fetch(url+'/v1/actions',{method:'POST',headers,body:JSON.stringify({padding:'x'.repeat(3000)})})).status,413);
});
