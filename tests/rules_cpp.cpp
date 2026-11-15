#include "PacoRules.h"
#include <cassert>
#include <iostream>
int main(){for(int n=0;n<30;n++)for(int seed=1;seed<=20;seed++){Paco::Match3 p(n,seed);assert(p.Matches().empty());assert(p.goal.seconds>=90&&p.goal.seconds<=180);for(int t=0;t<10&&!p.Won()&&p.moves>0;t++){auto h=p.Hint();assert(h.first>=0);int old=p.moves;assert(p.Swap(h.first,h.second));assert(p.moves==old-1);assert(p.Matches().empty());for(int v:p.board)assert(v>=0&&v<6);assert(p.score>0);}}Paco::Match3 p(1);auto old=p.board;assert(!p.Swap(4,5));assert(!p.Swap(0,80));assert(p.board==old);std::cout<<"C++: 600 plateaux, cascades et coups interdits validés\n";}
