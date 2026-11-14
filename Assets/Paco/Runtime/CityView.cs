using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.EventSystems;
using Paco.Domain;
using Newtonsoft.Json;
namespace Paco.Unity {
    [Serializable] public sealed class WorldObject {public string model,kind,id;public float x,z,rotation,scale;}
    [Serializable] sealed class WorldFile {public WorldObject[] objects;}


    public sealed class CityView:MonoBehaviour {
        public Camera Camera;public Action<string> OnDistrict;
        Transform geometry,actors;readonly List<District> districts=new List<District>();WorldObject[] layout;
        Vector3 focus=new Vector3(1,0,0);Vector2 last,down;bool dragging,blocked;float pinch;
        readonly Quaternion angle=Quaternion.Euler(43,-35,0);
        public bool ReducedMotion;
        public void Initialize(Camera camera,Player player){Camera=camera;layout=JsonConvert.DeserializeObject<WorldFile>(Resources.Load<TextAsset>("Data/world").text).objects;Refresh(player);}
        public void Refresh(Player player){
            if(geometry!=null)Destroy(geometry.gameObject);if(actors!=null)Destroy(actors.gameObject);districts.Clear();
            geometry=new GameObject("City geometry").transform;geometry.SetParent(transform,false);actors=new GameObject("Citizens and vehicles").transform;actors.SetParent(transform,false);
            PacoAssets.Box("Island",geometry,new Vector3(2,-.8f,0),new Vector3(29,1.3f,21),"cream");PacoAssets.Box("Lawn",geometry,new Vector3(2,-.08f,0),new Vector3(28.8f,.25f,20.8f),"lime");
            foreach(float z in new[]{-2.5f,2.5f}){PacoAssets.Box("Road",geometry,new Vector3(0,.1f,z),new Vector3(21.5f,.08f,1.5f),"road");for(int x=-10;x<=10;x+=2)PacoAssets.Box("Lane marking",geometry,new Vector3(x,.15f,z),new Vector3(.7f,.012f,.055f),"white");}
            foreach(float x in new[]{-5f,3f}){
                PacoAssets.Box("Cross street",geometry,new Vector3(x,.1f,0),new Vector3(1.4f,.08f,18),"road");
                for(int z=-8;z<=8;z+=2)PacoAssets.Box("Lane marking",geometry,new Vector3(x,.15f,z),new Vector3(.055f,.012f,.7f),"white");
                foreach(float z in new[]{-3.5f,1.5f})for(int j=0;j<5;j++)PacoAssets.Box("Crosswalk",geometry,new Vector3(x-.5f+j*.25f,.16f,z),new Vector3(.14f,.012f,.6f),"white");
            }
            PacoAssets.Box("Lagoon",geometry,new Vector3(9.5f,-.01f,0),new Vector3(1.2f,.2f,18),"water");
            foreach(float z in new[]{-2.5f,2.5f})PacoAssets.Box("Footbridge",geometry,new Vector3(9.5f,.22f,z),new Vector3(1.8f,.28f,1.4f),"wood");
            foreach(var item in layout){
                Vector3 pos=new Vector3(item.x,0,item.z);
                if(item.kind=="land"){
                    bool owned=player.ownedPlots.Contains(item.id);PacoAssets.Box("District "+item.id,geometry,pos,new Vector3(3.4f,.16f,3.7f),owned?"green":"wood");
                    string building;var model=PacoAssets.Model(player.townBuildings.TryGetValue(item.id,out building)?EconomyCatalog.Buildings.First(b=>b.Id==building).Model:"tree",geometry,pos,player.townBuildings.ContainsKey(item.id)?.85f:.6f);
                    var hit=new GameObject("Terrain "+item.id);hit.transform.SetParent(geometry,false);hit.transform.localPosition=pos+Vector3.up*.7f;var col=hit.AddComponent<BoxCollider>();col.size=new Vector3(3.4f,2,3.7f);var district=hit.AddComponent<District>();district.Id=item.id;district.Selected=OnDistrict;districts.Add(district);
                }else{var model=PacoAssets.Model(item.model,geometry,pos,item.scale);model.transform.localRotation=Quaternion.Euler(0,item.rotation,0);}
            }
            for(int i=0;i<12;i++){
                float x=-8+(i%6)*2,z=i<6?-1.5f:3.5f;var o=PacoAssets.Model("person",actors,new Vector3(x,.18f,z));var mover=o.AddComponent<Citizen>();mover.ReducedMotion=ReducedMotion;mover.Speed=.4f+(i%3)*.12f;mover.Route=new[]{new Vector3(6,.18f,z),new Vector3(-8,.18f,z)};
            }
            for(int i=0;i<3;i++){
                var car=PacoAssets.Model("car",actors,new Vector3(-5,.15f,-5+i*4));var mover=car.AddComponent<Citizen>();mover.Speed=1.1f+i*.2f;mover.ReducedMotion=ReducedMotion;mover.Route=new[]{new Vector3(-5,.15f,2.5f),new Vector3(3,.15f,2.5f),new Vector3(3,.15f,-2.5f),new Vector3(-5,.15f,-2.5f)};
            }
            // Static world meshes share a small material palette; mobile batching is prepared once.
            StaticBatchingUtility.Combine(geometry.gameObject);Recenter();
        }
        public void Recenter(){focus=new Vector3(2,0,0);Camera.orthographicSize=15;PositionCamera();}
        void PositionCamera(){Camera.transform.rotation=angle;Camera.transform.position=focus-angle*Vector3.forward*45;}
        public void Zoom(float amount){Camera.orthographicSize=Mathf.Clamp(Camera.orthographicSize+amount,6,23);}
        bool OverUi(int finger=-1){return PacoUiInput.OverUi(Input.touchCount>0?Input.GetTouch(0).position:(Vector2)Input.mousePosition);}
        void Update(){
            if(Input.touchCount>=2){var a=Input.GetTouch(0);var b=Input.GetTouch(1);float distance=Vector2.Distance(a.position,b.position);if(a.phase==TouchPhase.Began||b.phase==TouchPhase.Began)pinch=distance;if(pinch>0&&!blocked)Zoom((pinch-distance)*Camera.orthographicSize/Screen.height);pinch=distance;dragging=false;return;}
            pinch=0;bool begin=Input.GetMouseButtonDown(0),held=Input.GetMouseButton(0),end=Input.GetMouseButtonUp(0);Vector2 point=Input.mousePosition;
            if(Input.touchCount==1){var t=Input.GetTouch(0);begin=t.phase==TouchPhase.Began;end=t.phase==TouchPhase.Ended;held=t.phase!=TouchPhase.Ended&&t.phase!=TouchPhase.Canceled;point=t.position;if(t.phase==TouchPhase.Canceled)dragging=false;}
            if(begin){blocked=OverUi(Input.touchCount==1?Input.GetTouch(0).fingerId:-1);last=down=point;dragging=!blocked;}
            if(held&&dragging){Vector2 delta=point-last;if(Vector2.Distance(point,down)>12){Vector3 right=Camera.transform.right;Vector3 up=Vector3.ProjectOnPlane(Camera.transform.up,Vector3.up).normalized;focus-=(right*delta.x+up*delta.y)*(Camera.orthographicSize*2/Screen.height);focus.x=Mathf.Clamp(focus.x,-12,22);focus.z=Mathf.Clamp(focus.z,-12,12);PositionCamera();}last=point;}
            if(end&&dragging){if(Vector2.Distance(point,down)<12){RaycastHit hit;if(Physics.Raycast(Camera.ScreenPointToRay(point),out hit,100)){var d=hit.collider.GetComponent<District>();if(d!=null)d.Tap();}}dragging=false;}
            if(!OverUi())Zoom(-Input.mouseScrollDelta.y);
        }
    }
}
