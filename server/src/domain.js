import {createHash} from 'node:crypto';
import {z} from 'zod';
export class ApiError extends Error {
  constructor(status, code) {super(code); this.status=status; this.code=code;}
}
export const actionSchema=z.object({type:z.enum(['buy','sell']),companyId:z.enum(['cacao','telecom','banque']),quantity:z.literal(1),expectedVersion:z.number().int().min(0).max(1_000_000)}).strict();
export const keySchema=z.string().uuid();
export const PRICES=Object.freeze({cacao:2000,telecom:2500,banque:1500});
const holdingsSchema=z.object({cacao:z.number().int().nonnegative().max(1_000_000),telecom:z.number().int().nonnegative().max(1_000_000),banque:z.number().int().nonnegative().max(1_000_000)}).strict();
export const stateSchema=z.object({version:z.number().int().nonnegative().max(1_000_000),cash:z.number().int().nonnegative().max(1_000_000_000),holdings:holdingsSchema}).strict();
export function initialState(){return {version:0,cash:10000,holdings:{cacao:0,telecom:0,banque:0}};}
export function parseAction(body){const result=actionSchema.safeParse(body);if(!result.success)throw new ApiError(400,'INVALID_ACTION');return result.data;}
export function payloadHash(action){return createHash('sha256').update(JSON.stringify([action.type,action.companyId,action.quantity,action.expectedVersion])).digest('hex');}
export function reduceAction(raw,action){
 const parsed=stateSchema.safeParse(raw);if(!parsed.success)throw new ApiError(503,'INVALID_SERVER_STATE');
 const state=parsed.data;
 if(state.version!==action.expectedVersion)throw new ApiError(409,'VERSION_CONFLICT');
 const price=PRICES[action.companyId],fee=Math.max(25,Math.ceil(price*.01));
 if(action.type==='buy'&&state.cash<price+fee)throw new ApiError(409,'INSUFFICIENT_FUNDS');
 if(action.type==='sell'&&state.holdings[action.companyId]<1)throw new ApiError(409,'INSUFFICIENT_HOLDINGS');
 const next={version:state.version+1,cash:state.cash+(action.type==='buy'?-price-fee:price-fee),holdings:{...state.holdings,[action.companyId]:state.holdings[action.companyId]+(action.type==='buy'?1:-1)}};
 if(!stateSchema.safeParse(next).success)throw new ApiError(409,'SIMULATION_LIMIT');
 return {state:next,receipt:{type:action.type,companyId:action.companyId,quantity:1,price,fee}};
}
// Persist this result in the same Firestore transaction as the economic action.
export function consumeToken(previous,now){
 const capacity=30, perMs=capacity/60000;
 const valid=previous&&Number.isFinite(previous.tokens)&&previous.tokens>=0&&previous.tokens<=capacity&&Number.isFinite(previous.at);
 const at=valid?Math.max(previous.at,now):now;
 const available=valid?Math.min(capacity,previous.tokens+Math.max(0,now-previous.at)*perMs):capacity;
 if(available<1)throw new ApiError(429,'RATE_LIMITED');
 return {tokens:available-1,at};
}
export function checkReplay(operation,hash){if(!operation)return null;if(operation.payloadHash!==hash)throw new ApiError(409,'IDEMPOTENCY_CONFLICT');return operation.response;}
