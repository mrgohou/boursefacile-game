import {getApps,initializeApp,applicationDefault} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getAppCheck} from 'firebase-admin/app-check';
import {getFirestore} from 'firebase-admin/firestore';
import {createApp} from './app.js';
import {createStore} from './store.js';
// Lazy initialization keeps health checks independent of ADC and Firestore.
let services;
function getServices(){if(!services){const app=getApps()[0]||initializeApp({credential:applicationDefault()});services={auth:getAuth(app),check:getAppCheck(app),store:createStore(getFirestore(app))};}return services;}
const app=createApp({verifyIdToken:token=>getServices().auth.verifyIdToken(token,true),verifyAppCheck:token=>getServices().check.verifyToken(token),store:{player:uid=>getServices().store.player(uid),action:(...args)=>getServices().store.action(...args)}});
const port=Number(process.env.PORT||8080);if(!Number.isInteger(port)||port<1||port>65535)throw new Error('Invalid PORT');
const server=app.listen(port,'0.0.0.0',()=>console.log(`PACO API listening on ${port}`));
for(const signal of ['SIGTERM','SIGINT'])process.on(signal,()=>{server.close(()=>process.exit(0));setTimeout(()=>process.exit(1),10000).unref();});
