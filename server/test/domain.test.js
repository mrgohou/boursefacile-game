import test from 'node:test';
import assert from 'node:assert/strict';
import {parseAction,initialState,reduceAction,payloadHash,consumeToken,checkReplay} from '../src/domain.js';
const buy={type:'buy',companyId:'cacao',quantity:1,expectedVersion:0};
test('strict action contract rejects client authority and malformed orders',()=>{
 assert.deepEqual(parseAction(buy),buy);
 for(const body of [{...buy,uid:'other'},{...buy,cash:9999},{...buy,type:'completeLevel'},{...buy,quantity:2},{...buy,quantity:-1},{...buy,companyId:'real-stock'},{...buy,expectedVersion:0.5}])assert.throws(()=>parseAction(body),{code:'INVALID_ACTION'});
});
test('buy and sell atomically charge fees without mutating input',()=>{
 const initial=initialState();const bought=reduceAction(initial,buy);
 assert.equal(bought.state.cash,7975);assert.equal(bought.state.holdings.cacao,1);assert.equal(bought.state.version,1);assert.equal(initial.cash,10000);
 const sold=reduceAction(bought.state,{...buy,type:'sell',expectedVersion:1});assert.equal(sold.state.cash,9950);assert.equal(sold.state.holdings.cacao,0);
 assert.throws(()=>reduceAction(initial,{...buy,type:'sell'}),{code:'INSUFFICIENT_HOLDINGS'});
 assert.throws(()=>reduceAction({...initial,cash:2000},buy),{code:'INSUFFICIENT_FUNDS'});
 assert.throws(()=>reduceAction(bought.state,buy),{code:'VERSION_CONFLICT'});
});
test('idempotency compares canonical payload including expected version',()=>{
 const hash=payloadHash(buy),response={state:initialState()};assert.equal(payloadHash({...buy}),hash);
 assert.equal(checkReplay({payloadHash:hash,response},hash),response);
 assert.throws(()=>checkReplay({payloadHash:hash,response},payloadHash({...buy,type:'sell'})),{code:'IDEMPOTENCY_CONFLICT'});
});
test('persistent token bucket exhausts and refills without clock rollback refill',()=>{
 let bucket;for(let i=0;i<30;i++)bucket=consumeToken(bucket,1000);
 assert.throws(()=>consumeToken(bucket,1000),{code:'RATE_LIMITED'});
 assert.throws(()=>consumeToken(bucket,0),{code:'RATE_LIMITED'});
 bucket=consumeToken(bucket,3000);assert.equal(bucket.tokens,0);
});
