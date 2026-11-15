export function challenge(level,mastery=0){
 if(!Number.isInteger(level)||level<0)throw Error('Niveau invalide');mastery=Math.max(0,Math.min(3,mastery));
 const c=Math.min(10,Math.floor(level/6)),p=level%6,n=3600+c*700+p*250;
 return {level,score:p===0||c%2===1||p>=4?n+Math.floor(n*mastery/10):0,moves:Math.max(24,(p===3?40:p===5?38:34)-mastery),seconds:Math.max(90,Math.min(180,(p===3||p===5?180:120+c*10)-mastery*5)),locks:p===1||p===5?(c>=2?6:4):0,perfect:p===3?7:0,collect:p===2||p===5?30:0,type:(c+p)%6,special:p===4?(c>=3?3:2):0};
}
export class Match3{
 constructor(level=0,seed=4701,mastery=0){this.spec=challenge(level,mastery);this.rng=(seed+level*137)>>>0;this.score=0;this.moves=this.spec.moves;this.perfect=0;this.collected=0;this.used=0;this.locked=new Set();this.special=Array(81).fill(0);this.board=this.fresh();for(let i=0;i<this.spec.locks;i++)this.locked.add((i*13+4)%81);for(let i=0;i<this.spec.special;i++)this.special[(i*19+7)%81]=i%5+1;this.events=[];}
 random(n){this.rng=(Math.imul(this.rng,1664525)+1013904223)>>>0;return this.rng%n;}
 static adjacent(a,b){return a>=0&&b>=0&&a<81&&b<81&&Math.abs(a%9-b%9)+Math.abs(Math.floor(a/9)-Math.floor(b/9))===1;}
 static matches(board,min=3){const out=new Set();for(let i=0;i<81;i++){const v=board[i];if(v<0)continue;for(const d of [1,9]){if(d===1&&i%9>9-min||i+(min-1)*d>=81)continue;let k=1;while(i+k*d<81&&(d===9||Math.floor((i+k)/9)===Math.floor(i/9))&&board[i+k*d]===v)k++;if(k>=min)for(let j=0;j<k;j++)out.add(i+j*d);}}return out;}
 fresh(){for(let attempt=0;attempt<1000;attempt++){const b=[];for(let i=0;i<81;i++){let v;do{v=this.random(6);}while(i%9>=2&&b[i-1]===v&&b[i-2]===v||i>=18&&b[i-9]===v&&b[i-18]===v);b.push(v);}if(this.hint(b))return b;}throw Error('Plateau indisponible');}
 get won(){const s=this.spec;return this.score>=s.score&&!this.locked.size&&this.perfect>=s.perfect&&this.collected>=s.collect&&this.used>=s.special;}
 get lost(){return !this.won&&this.moves<=0;}
 hint(board=this.board){for(let a=0;a<81;a++)for(const b of [a+1,a+9])if(Match3.adjacent(a,b)&&!this.locked.has(a)&&!this.locked.has(b)){if(this.special[a]||this.special[b])return[a,b];[board[a],board[b]]=[board[b],board[a]];const yes=Match3.matches(board).size;[board[a],board[b]]=[board[b],board[a]];if(yes)return[a,b];}return null;}
 effect(i,type,clear){const x=i%9,y=Math.floor(i/9);for(let j=0;j<81;j++){const dx=Math.abs(j%9-x),dy=Math.abs(Math.floor(j/9)-y);if(type===1&&dy===0||type===2&&this.board[j]===this.board[i]||type===3&&dx<=1&&dy<=1||type===4&&this.board[j]===this.spec.type||type===5&&(dx===0||dy===0))clear.add(j);}}
 swap(a,b){this.events=[];if(this.won||this.lost||!Match3.adjacent(a,b)||this.locked.has(a)||this.locked.has(b))return false;
 const before=this.board.slice();[this.board[a],this.board[b]]=[this.board[b],this.board[a]];[this.special[a],this.special[b]]=[this.special[b],this.special[a]];
 let clear=Match3.matches(this.board);const activated=[a,b].filter(i=>this.special[i]);if(!clear.size&&!activated.length){[this.board[a],this.board[b]]=[this.board[b],this.board[a]];[this.special[a],this.special[b]]=[this.special[b],this.special[a]];return false;}
 if(Match3.matches(this.board,4).size)this.perfect++;const create=Match3.matches(this.board,4).size&&!activated.length;for(const i of activated)clear.add(i);this.moves--;
 for(let chain=1;clear.size&&chain<=100;chain++){
  const queue=[...clear],seen=new Set();while(queue.length){const i=queue.shift();if(seen.has(i))continue;seen.add(i);if(this.special[i]){this.effect(i,this.special[i],clear);this.used++;this.special[i]=0;for(const j of clear)if(!seen.has(j))queue.push(j);}}
  for(const i of [...this.locked])if(clear.has(i)||[...clear].some(j=>Match3.adjacent(i,j)))this.locked.delete(i);
  this.collected+=[...clear].filter(i=>this.board[i]===this.spec.type).length;this.score+=clear.size*100*Math.min(chain,3);this.events.push({phase:'clear',cells:[...clear],before:this.board.slice(),score:this.score});
  if(create&&chain===1){clear.delete(b);this.special[b]=1+(this.spec.level%5);}
  for(let x=0;x<9;x++){const keep=[];for(let y=8;y>=0;y--){const i=y*9+x;if(!clear.has(i))keep.push([this.board[i],this.special[i]]);}for(let y=8;y>=0;y--){const [v,s]=keep.shift()??[this.random(6),0];this.board[y*9+x]=v;this.special[y*9+x]=s;}}
  this.events.push({phase:'fall',after:this.board.slice()});clear=Match3.matches(this.board);
 }
 if(clear.size||!this.hint()){this.special.fill(0);this.board=this.fresh();}this.events.unshift({phase:'swap',a,b,before});return true;
 }
 progress(){return `${this.score}/${this.spec.score||'bonus'} pts · ${this.locked.size} cadenas · ${this.perfect}/${this.spec.perfect} parfaits · ${this.collected}/${this.spec.collect} récoltes · ${this.used}/${this.spec.special} spéciaux`;}
}
export class Economy{
 constructor(catalog,data){this.catalog=catalog;this.data=data??{version:1,cash:10000,holdings:{},cards:[],plots:['centre'],placements:{},completed:[],answered:[]};this.validate();}
 validate(){const d=this.data;if(!Number.isSafeInteger(d.cash)||d.cash<0||d.cash>1e9)throw Error('Solde invalide');for(const [id,n]of Object.entries(d.holdings))if(!this.catalog.companies.some(c=>c.id===id)||!Number.isSafeInteger(n)||n<0||n>1e6)throw Error('Position invalide');if(d.completed.some((v,i,a)=>!Number.isInteger(v)||v<0||v>=30||a.indexOf(v)!==i||v>0&&!d.answered.includes(v-1))||d.answered.some(v=>!d.completed.includes(v)))throw Error('Progression invalide');const sites=new Set();for(const [id,p]of Object.entries(d.placements)){const site=p.land+':'+p.cell;if(!(d.holdings[id]>0)||!d.plots.includes(p.land)||!Number.isInteger(p.cell)||p.cell<0||p.cell>=16||sites.has(site))throw Error('Placement invalide');sites.add(site);}return this;}
 transaction(change,persist){const next=new Economy(this.catalog,JSON.parse(JSON.stringify(this.data)));change(next.data);next.validate();persist?.(JSON.stringify(next.data));this.data=next.data;}
 win(level,persist){this.transaction(d=>{if(d.completed.includes(level))return;if(level!==d.answered.length)throw Error('Étape verrouillée');d.completed.push(level);d.cash+=1500;},persist);}
 learn(level,persist){this.transaction(d=>{if(!d.completed.includes(level))throw Error('Réussis le puzzle');if(!d.answered.includes(level))d.answered.push(level);},persist);}
 trade(id,buy,persist){this.transaction(d=>{if(!d.answered.includes(1))throw Error('Termine deux notions');const c=this.catalog.companies.find(c=>c.id===id);if(!c)throw Error('Entreprise inconnue');const f=Math.max(25,Math.ceil(c.price/100));if(buy){if(d.cash<c.price+f)throw Error('Solde insuffisant');d.cash-=c.price+f;d.holdings[id]=(d.holdings[id]??0)+1;if(!d.cards.includes(id))d.cards.push(id);}else{if(!(d.holdings[id]>0))throw Error('Aucune part');d.cash+=c.price-f;d.holdings[id]--;if(!d.holdings[id])delete d.placements[id];}},persist);}
 buyLand(id,persist){this.transaction(d=>{const index=this.catalog.lands.findIndex(l=>l.id===id),l=this.catalog.lands[index];if(!l||d.plots.includes(id)||index>0&&!d.plots.includes(this.catalog.lands[index-1].id)||d.completed.length*1500<l.gains||d.cash<l.price)throw Error('Terrain indisponible');d.cash-=l.price;d.plots.push(id);},persist);}
 place(id,land,cell,persist){this.transaction(d=>{d.placements[id]={land,cell};},persist);}
}
