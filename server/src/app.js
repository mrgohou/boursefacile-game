import express from 'express';
import {ApiError,parseAction,keySchema} from './domain.js';
export function createApp({verifyIdToken,verifyAppCheck,store}){
 const app=express();app.disable('x-powered-by');app.set('trust proxy',false);
 app.use((_req,res,next)=>{res.set('Cache-Control','no-store');res.set('X-Content-Type-Options','nosniff');next();});
 app.get('/healthz',(_req,res)=>res.json({status:'ok'}));
 app.use('/v1',async(req,res,next)=>{
  const bearer=req.get('authorization')?.match(/^Bearer ([^\s]+)$/),appToken=req.get('X-Firebase-AppCheck');
  if(!bearer||!appToken||appToken.length>8192||bearer[1].length>8192)return next(new ApiError(401,'AUTH_REQUIRED'));
  try{const [identity]=await Promise.all([verifyIdToken(bearer[1]),verifyAppCheck(appToken)]);
   if(!identity?.uid||!/^[A-Za-z0-9:_-]{1,128}$/.test(identity.uid))throw new Error('invalid identity');req.uid=identity.uid;next();
  }catch{next(new ApiError(401,'AUTH_INVALID'));}
 });
 app.get('/v1/player',async(req,res,next)=>{try{res.json(await store.player(req.uid));}catch(error){next(error);}});
 app.post('/v1/actions',express.json({limit:'2kb',strict:true}),async(req,res,next)=>{try{
  if(!req.is('application/json'))throw new ApiError(415,'JSON_REQUIRED');
  const key=keySchema.safeParse(req.get('Idempotency-Key'));if(!key.success)throw new ApiError(400,'INVALID_IDEMPOTENCY_KEY');
  const action=parseAction(req.body);res.json(await store.action(req.uid,key.data,action));
 }catch(error){next(error);}});
 app.use((_req,_res,next)=>next(new ApiError(404,'NOT_FOUND')));
 app.use((error,_req,res,_next)=>{
  const status=error instanceof ApiError?error.status:error.type==='entity.too.large'?413:error.type==='entity.parse.failed'?400:503;
  const code=error instanceof ApiError?error.code:status===413?'BODY_TOO_LARGE':status===400?'INVALID_JSON':'SERVICE_UNAVAILABLE';
  if(status===429)res.set('Retry-After','2');res.status(status).json({error:{code}});
 });return app;
}
