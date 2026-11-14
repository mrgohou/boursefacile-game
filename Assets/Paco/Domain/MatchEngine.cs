using System;
using System.Collections.Generic;
using System.Linq;
namespace Paco.Domain {
    public enum Phase { Swap, Revert, Clear, Fall, Shuffle }
    public struct Motion { public int Type,From,To; public Motion(int type,int from,int to){Type=type;From=from;To=to;} }
    public sealed class Frame {
        public readonly Phase Phase;public readonly int[] Before,After,Cleared;public readonly Motion[] Motions;public readonly int Score,Moves,Chain;
        public Frame(Phase phase,int[] before,int[] after,int score,int moves,int chain=0,IEnumerable<int> cleared=null,IEnumerable<Motion> motions=null){Phase=phase;Before=(int[])before.Clone();After=(int[])after.Clone();Score=score;Moves=moves;Chain=chain;Cleared=cleared==null?Array.Empty<int>():cleared.ToArray();Motions=motions==null?Array.Empty<Motion>():motions.ToArray();}
    }
    public sealed class MatchEngine {
        public const int Size=7;
        readonly Random random;
        public int[] Board {get;private set;}
        public int Score {get;private set;}
        public int Moves {get;private set;}
        public int Target {get;private set;}
        public bool Won {get{return Score>=Target;}}
        public bool Lost {get{return Moves==0&&!Won;}}
        public readonly List<Frame> Frames=new List<Frame>();
        public MatchEngine(Stage stage,int seed=4701){random=new Random(seed+stage.index*137);Moves=stage.moves;Target=stage.target;Board=NewBoard();}
        public static bool Adjacent(int a,int b){return a>=0&&b>=0&&a<49&&b<49&&Math.Abs(a%7-b%7)+Math.Abs(a/7-b/7)==1;}
        public static HashSet<int> Matches(int[] board){
            var result=new HashSet<int>();
            for(int y=0;y<7;y++)for(int x=0;x<7;x++){
                int i=y*7+x,v=board[i];if(v<0)continue;
                if(x<5&&v==board[i+1]&&v==board[i+2])for(int n=x;n<7&&board[y*7+n]==v;n++)result.Add(y*7+n);
                if(y<5&&v==board[i+7]&&v==board[i+14])for(int n=y;n<7&&board[n*7+x]==v;n++)result.Add(n*7+x);
            }return result;
        }
        static void Exchange(int[] b,int a,int c){int v=b[a];b[a]=b[c];b[c]=v;}
        public static int[] Hint(int[] board){for(int i=0;i<49;i++)foreach(int j in new[]{i%7<6?i+1:-1,i<42?i+7:-1})if(j>=0){Exchange(board,i,j);bool valid=Matches(board).Count>0;Exchange(board,i,j);if(valid)return new[]{i,j};}return null;}
        int[] NewBoard(){
            for(int attempt=0;attempt<1000;attempt++){
                int[] b=new int[49];
                for(int i=0;i<49;i++){
                    int v;do{v=random.Next(6);}while((i%7>=2&&v==b[i-1]&&v==b[i-2])||(i>=14&&v==b[i-7]&&v==b[i-14]));b[i]=v;
                }
                if(Hint(b)!=null)return b;
            }throw new InvalidOperationException("Impossible de préparer le plateau.");
        }
        public bool Swap(int a,int b){
            Frames.Clear();if(Won||Lost||!Adjacent(a,b))return false;
            int[] before=(int[])Board.Clone();Exchange(Board,a,b);
            Frames.Add(new Frame(Phase.Swap,before,Board,Score,Moves,motions:new[]{new Motion(before[a],a,b),new Motion(before[b],b,a)}));
            var matches=Matches(Board);
            if(matches.Count==0){int[] invalid=(int[])Board.Clone();Exchange(Board,a,b);Frames.Add(new Frame(Phase.Revert,invalid,Board,Score,Moves,motions:new[]{new Motion(invalid[a],a,b),new Motion(invalid[b],b,a)}));return false;}
            Moves--;int chain=0;
            while(matches.Count>0&&chain<60){
                chain++;before=(int[])Board.Clone();Score=checked(Score+matches.Count*30*Math.Min(chain,5));
                foreach(int index in matches)Board[index]=-1;
                Frames.Add(new Frame(Phase.Clear,before,Board,Score,Moves,chain,cleared:matches));
                before=(int[])Board.Clone();var motions=new List<Motion>();
                for(int x=0;x<7;x++){
                    int destination=6;
                    for(int y=6;y>=0;y--)if(before[y*7+x]>=0){int from=y*7+x,to=destination*7+x;Board[to]=before[from];motions.Add(new Motion(before[from],from,to));destination--;}
                    int entering=1;while(destination>=0){int to=destination*7+x,type=random.Next(6);Board[to]=type;motions.Add(new Motion(type,-entering*7+x,to));destination--;entering++;}
                }
                Frames.Add(new Frame(Phase.Fall,before,Board,Score,Moves,chain,motions:motions));matches=Matches(Board);
            }
            if(matches.Count>0||Hint(Board)==null){before=(int[])Board.Clone();Board=NewBoard();Frames.Add(new Frame(Phase.Shuffle,before,Board,Score,Moves,chain));}
            return true;
        }
    }
}
