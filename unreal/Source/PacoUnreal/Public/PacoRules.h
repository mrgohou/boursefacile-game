#pragma once
#include <array>
#include <set>
#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <utility>
namespace Paco {
struct Goal {int level,score,moves,seconds,locks,perfect,collect,type,special;};
inline Goal Challenge(int n){int c=std::min(10,n/6),p=n%6;return {n,(p==0||c%2||p>=4)?3600+c*700+p*250:0,p==3?40:p==5?38:34,std::min(180,(p==3||p==5)?180:120+c*10),(p==1||p==5)?(c>=2?6:4):0,p==3?7:0,(p==2||p==5)?30:0,(c+p)%6,p==4?(c>=3?3:2):0};}
class Match3 {
public:
 std::array<int,81> board{},special{};std::set<int> locked;Goal goal;int score=0,moves,perfect=0,collected=0,used=0;uint32_t seed;
 explicit Match3(int level=0,uint32_t s=4701):goal(Challenge(level)),moves(goal.moves),seed(s+level*137){Fresh();for(int i=0;i<goal.locks;i++)locked.insert((i*13+4)%81);for(int i=0;i<goal.special;i++)special[(i*19+7)%81]=i%5+1;if(Hint().first<0)Fresh();}
 int Random(int n){seed=seed*1664525u+1013904223u;return seed%n;}
 static bool Adjacent(int a,int b){return a>=0&&b>=0&&a<81&&b<81&&std::abs(a%9-b%9)+std::abs(a/9-b/9)==1;}
 std::set<int> Matches(int minimum=3)const{std::set<int> out;for(int i=0;i<81;i++)for(int d:{1,9}){int k=1;while(i+k*d<81&&(d==9||(i+k)/9==i/9)&&board[i+k*d]==board[i])k++;if(k>=minimum)for(int j=0;j<k;j++)out.insert(i+j*d);}return out;}
 std::pair<int,int> Hint(){for(int a=0;a<81;a++)for(int b:{a+1,a+9})if(Adjacent(a,b)&&!locked.count(a)&&!locked.count(b)){if(special[a]||special[b])return{a,b};std::swap(board[a],board[b]);bool yes=!Matches().empty();std::swap(board[a],board[b]);if(yes)return{a,b};}return{-1,-1};}
 void Fresh(){for(int attempt=0;attempt<1000;attempt++){for(int i=0;i<81;i++){int v;do{v=Random(6);}while((i%9>=2&&board[i-1]==v&&board[i-2]==v)||(i>=18&&board[i-9]==v&&board[i-18]==v));board[i]=v;}if(Hint().first>=0)return;} }
 bool Won()const{return score>=goal.score&&locked.empty()&&perfect>=goal.perfect&&collected>=goal.collect&&used>=goal.special;}
 bool Swap(int a,int b){if(Won()||moves<=0||!Adjacent(a,b)||locked.count(a)||locked.count(b))return false;std::swap(board[a],board[b]);std::swap(special[a],special[b]);auto clear=Matches();if(clear.empty()&&!special[a]&&!special[b]){std::swap(board[a],board[b]);std::swap(special[a],special[b]);return false;}bool create=!Matches(4).empty()&&!special[a]&&!special[b];if(!Matches(4).empty())perfect++;if(special[a])clear.insert(a);if(special[b])clear.insert(b);moves--;
 for(int chain=1;!clear.empty()&&chain<=100;chain++){
  std::set<int> visited;bool changed=true;while(changed){changed=false;auto scan=clear;for(int i:scan)if(!visited.count(i)){visited.insert(i);changed=true;int t=special[i];if(t){used++;special[i]=0;for(int j=0;j<81;j++){int dx=std::abs(j%9-i%9),dy=std::abs(j/9-i/9);if((t==1&&dy==0)||(t==2&&board[j]==board[i])||(t==3&&dx<=1&&dy<=1)||(t==4&&board[j]==goal.type)||(t==5&&(dx==0||dy==0)))clear.insert(j);}}}}
  auto locks=locked;for(int i:locks)for(int j:clear)if(i==j||Adjacent(i,j)){locked.erase(i);break;}
  for(int i:clear){if(board[i]==goal.type)collected++;}
  score+=int(clear.size())*100*std::min(chain,3);
  if(create&&chain==1){clear.erase(b);special[b]=1+goal.level%5;}
  for(int x=0;x<9;x++){int dest=8;for(int y=8;y>=0;y--)if(!clear.count(y*9+x)){board[dest*9+x]=board[y*9+x];special[dest*9+x]=special[y*9+x];dest--;}for(;dest>=0;dest--){board[dest*9+x]=Random(6);special[dest*9+x]=0;}}
  clear=Matches();
 }
 if(!clear.empty()||Hint().first<0){special.fill(0);Fresh();}return true;
 }
};
}
