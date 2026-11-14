using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.EventSystems;
using Paco.Domain;
namespace Paco.Unity {

    public sealed class PuzzleView:MonoBehaviour {
        public MatchEngine Engine {get;private set;} public RoundClock Clock {get;private set;}
        public bool Running {get;private set;} public bool Busy {get;private set;} public bool Finished {get;private set;}
        public Action<int,int,int,int> Stats;public Action<bool> Result;public Action<string> Feedback;
        public Camera Camera; public PacoAudio Audio;public bool ReducedMotion;
        readonly string[] names={"tile_cacao","tile_phone","tile_cash","tile_fuel","tile_bulb","tile_gear"};
        GameObject[] pieces=new GameObject[49];Transform tray,tileRoot,effects;int selected=-1,press=-1;Vector2 down;bool blocked;
        public Vector3 Cell(int index){int row=index>=0?index/7:(int)Math.Floor(index/7.0);int col=index-row*7;return new Vector3((col-3)*1.04f,(3-row)*1.04f,0);}
        public void Initialize(Stage stage,Camera camera,PacoAudio audio,bool reduced){
            Engine=new MatchEngine(stage);Clock=new RoundClock(stage.seconds);Camera=camera;Audio=audio;ReducedMotion=reduced;
            tileRoot=new GameObject("Glazed pieces").transform;tileRoot.SetParent(transform,false);tray=new GameObject("Puzzle tray").transform;tray.SetParent(transform,false);effects=new GameObject("Combo sparks").transform;effects.SetParent(transform,false);
            PacoAssets.Box("Board backing",tray,new Vector3(0,0,.64f),new Vector3(7.75f,7.75f,.45f),"purple");
            for(int i=0;i<49;i++)PacoAssets.Box("Recess",tray,Cell(i)+Vector3.forward*.39f,new Vector3(.99f,.99f,.13f),"navy");
            Draw(Engine.Board);Camera.transform.SetPositionAndRotation(new Vector3(0,0,-22),Quaternion.identity);Camera.orthographic=true;Camera.backgroundColor=new Color(.81f,.87f,.96f);ResizeCamera();Publish();
        }
        public void ResizeCamera(){if(Camera==null)return;float boardWidth=7.6f;float available=Mathf.Min(.65f,(Screen.height-Screen.safeArea.yMin-(Screen.height-Screen.safeArea.yMax))/Screen.height-.25f);available=Mathf.Max(.35f,available);Camera.rect=new Rect(0,.19f,1,available);Camera.orthographicSize=Mathf.Max(4.3f,boardWidth/(2*Camera.aspect));}
        GameObject Create(int type,int index){var o=PacoAssets.Model(names[type],tileRoot,Cell(index),.94f);o.transform.localRotation=Quaternion.Euler(-90,0,0);var hit=o.AddComponent<BoxCollider>();hit.center=Vector3.zero;hit.size=new Vector3(1.1f,.65f,1.1f);o.AddComponent<Piece>().Index=index;return o;}
        void Draw(int[] board){foreach(var p in pieces)if(p!=null)Destroy(p);pieces=new GameObject[49];for(int i=0;i<49;i++)if(board[i]>=0)pieces[i]=Create(board[i],i);}
        public void StartRound(){if(Running||Finished)return;Running=true;Clock.Start(WallClock.Now);Publish();}
        void Publish(){Stats?.Invoke(Engine.Score,Engine.Moves,Engine.Target,Clock.Remaining(WallClock.Now));}
        void Finish(bool win){if(Finished)return;Finished=true;Running=false;Audio.Play(win?"win":"lose");Publish();Result?.Invoke(win);}
        public void Hint(){if(!Running||Busy||Finished||Clock.Remaining(WallClock.Now)<=0)return;var pair=MatchEngine.Hint(Engine.Board);if(pair!=null)StartCoroutine(Highlight(pair));}
        IEnumerator Highlight(int[] pair){foreach(int i in pair)if(pieces[i]!=null)pieces[i].transform.localScale=Vector3.one*1.12f;Audio.Play("select");yield return new WaitForSecondsRealtime(.25f);foreach(int i in pair)if(pieces[i]!=null)pieces[i].transform.localScale=Vector3.one*.94f;}
        public void Select(int index){
            if(!Running||Busy||Finished)return;if(Clock.Remaining(WallClock.Now)==0){Finish(Engine.Won);return;}
            if(selected>=0&&MatchEngine.Adjacent(selected,index)){int old=selected;selected=-1;StartCoroutine(Turn(old,index));return;}
            if(selected>=0&&pieces[selected]!=null)pieces[selected].transform.localScale=Vector3.one*.94f;
            selected=index;if(pieces[index]!=null)pieces[index].transform.localScale=Vector3.one*1.1f;Audio.Play("select");
        }
        IEnumerator Turn(int a,int b){
            Busy=true;bool accepted=Engine.Swap(a,b);
            foreach(Frame f in Engine.Frames){
                if(f.Phase==Phase.Swap||f.Phase==Phase.Revert){
                    Audio.Play(f.Phase==Phase.Revert?"invalid":"swap");float duration=ReducedMotion?.01f:.16f;Vector3 pa=Cell(a),pb=Cell(b);GameObject oa=pieces[a],ob=pieces[b];
                    for(float t=0;t<1;t+=Time.unscaledDeltaTime/duration){if(oa!=null)oa.transform.localPosition=Vector3.Lerp(pa,pb,Mathf.SmoothStep(0,1,t));if(ob!=null)ob.transform.localPosition=Vector3.Lerp(pb,pa,Mathf.SmoothStep(0,1,t));yield return null;}
                    pieces[a]=ob;pieces[b]=oa;foreach(int i in new[]{a,b})if(pieces[i]!=null){pieces[i].transform.localPosition=Cell(i);pieces[i].transform.localScale=Vector3.one*.94f;pieces[i].GetComponent<Piece>().Index=i;}
                }else if(f.Phase==Phase.Clear){
                    Audio.Play(f.Chain>1?"cascade":"match",f.Chain);Feedback?.Invoke(f.Chain>=3?"MAGNIFIQUE !":f.Chain==2?"SUPER COMBO !":"BIEN JOUÉ !");
                    foreach(int i in f.Cleared.Take(8))if(pieces[i]!=null&&!ReducedMotion)Burst(Cell(i));
                    float duration=ReducedMotion?.01f:.17f;
                    for(float t=0;t<1;t+=Time.unscaledDeltaTime/duration){foreach(int i in f.Cleared)if(pieces[i]!=null)pieces[i].transform.localScale=Vector3.one*Mathf.Lerp(.94f,0,t);yield return null;}
                    foreach(int i in f.Cleared)if(pieces[i]!=null){Destroy(pieces[i]);pieces[i]=null;}
                }else if(f.Phase==Phase.Fall){
                    var next=new GameObject[49];foreach(var m in f.Motions){GameObject o=m.From>=0?pieces[m.From]:Create(m.Type,m.To);o.transform.localPosition=Cell(m.From);o.GetComponent<Piece>().Index=m.To;next[m.To]=o;}
                    float duration=ReducedMotion?.01f:.23f;
                    for(float t=0;t<1;t+=Time.unscaledDeltaTime/duration){float eased=1-Mathf.Pow(1-t,3);foreach(var m in f.Motions)next[m.To].transform.localPosition=Vector3.Lerp(Cell(m.From),Cell(m.To),eased);yield return null;}
                    pieces=next;for(int i=0;i<49;i++)pieces[i].transform.localPosition=Cell(i);
                }else{Draw(f.After);Audio.Play("shuffle");Feedback?.Invoke("NOUVELLES POSSIBILITÉS");}
                Stats?.Invoke(f.Score,f.Moves,Engine.Target,Clock.Remaining(WallClock.Now));
            }
            Busy=false;Publish();if(accepted&&Engine.Won)Finish(true);else if(Engine.Lost||Clock.Remaining(WallClock.Now)==0)Finish(false);
        }
        void Burst(Vector3 at){
            // Short-lived bounded burst; no textures or paid VFX dependency.
            for(int i=0;i<5;i++){var o=GameObject.CreatePrimitive(PrimitiveType.Sphere);o.transform.SetParent(effects,false);o.transform.localPosition=at+new Vector3(0,0,-.4f);o.transform.localScale=Vector3.one*.09f;Destroy(o.GetComponent<Collider>());o.GetComponent<Renderer>().sharedMaterial=PacoAssets.Material(i%2==0?"gold":"white");StartCoroutine(Spark(o,i));}
        }
        IEnumerator Spark(GameObject o,int i){Vector3 start=o.transform.localPosition,dir=new Vector3(Mathf.Cos(i*1.257f),Mathf.Sin(i*1.257f),-.2f);for(float t=0;t<1;t+=Time.unscaledDeltaTime/.3f){o.transform.localPosition=start+dir*t*.8f;o.transform.localScale=Vector3.one*.09f*(1-t);yield return null;}Destroy(o);}
        void Update(){
            if(Running&&!Finished){Publish();if(!Busy&&Clock.Remaining(WallClock.Now)==0){Finish(Engine.Won);return;}}
            if(!Running||Busy||Finished)return;
            bool begin=Input.GetMouseButtonDown(0),end=Input.GetMouseButtonUp(0);Vector2 point=Input.mousePosition;int finger=-1;
            if(Input.touchCount>0){Touch touch=Input.GetTouch(0);begin=touch.phase==TouchPhase.Began;end=touch.phase==TouchPhase.Ended;point=touch.position;finger=touch.fingerId;if(touch.phase==TouchPhase.Canceled){press=-1;blocked=true;}}
            if(begin){blocked=PacoUiInput.OverUi(point);down=point;press=blocked?-1:Hit(point);}
            if(end&&!blocked&&press>=0){Vector2 delta=point-down;int destination=press;
                if(delta.magnitude>Mathf.Max(18,Screen.width*.035f)){destination=press+(Mathf.Abs(delta.x)>Mathf.Abs(delta.y)?(delta.x>0?1:-1):(delta.y>0?-7:7));if(MatchEngine.Adjacent(press,destination)){selected=press;Select(destination);}}else Select(press);press=-1;}
        }
        int Hit(Vector2 point){RaycastHit hit;if(Physics.Raycast(Camera.ScreenPointToRay(point),out hit,60)){var piece=hit.collider.GetComponent<Piece>();if(piece!=null)return piece.Index;}return -1;}
        void OnApplicationPause(bool paused){if(!paused&&Running&&!Busy&&Clock.Remaining(WallClock.Now)==0)Finish(Engine.Won);}
        void OnDisable(){StopAllCoroutines();Running=false;}
    }
}
