import {ApiError,initialState,stateSchema,reduceAction,consumeToken,payloadHash,checkReplay} from './domain.js';
export function createStore(db,clock=Date.now){
 async function throttle(uid){const ref=db.doc(`users/${uid}/limits/api`);await db.runTransaction(async tx=>{const saved=await tx.get(ref);tx.set(ref,consumeToken(saved.exists?saved.data():null,clock()));});}
 return {
  async player(uid){await throttle(uid);return db.runTransaction(async tx=>{
   const stateRef=db.doc(`users/${uid}/state/main`);
   const saved=await tx.get(stateRef);
   const state=saved.exists?saved.data():initialState();
   if(!stateSchema.safeParse(state).success)throw new ApiError(503,'INVALID_SERVER_STATE');
   if(!saved.exists)tx.create(stateRef,state);
   return {state,prices:{cacao:2000,telecom:2500,banque:1500},simulation:true};
  });},
  async action(uid,key,action){await throttle(uid);const hash=payloadHash(action);return db.runTransaction(async tx=>{
   const stateRef=db.doc(`users/${uid}/state/main`),opRef=db.doc(`users/${uid}/operations/${key}`);
   const [saved,op]=await tx.getAll(stateRef,opRef);
   const replay=checkReplay(op.exists?op.data():null,hash);
   if(replay)return {...replay,replayed:true};
   const response={...reduceAction(saved.exists?saved.data():initialState(),action),replayed:false,simulation:true};
   tx.set(stateRef,response.state);tx.create(opRef,{payloadHash:hash,response,createdAt:new Date(clock())});
   return response;
  });}
 };
}
