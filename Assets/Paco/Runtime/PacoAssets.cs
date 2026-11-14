using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using Newtonsoft.Json;

namespace Paco.Unity {
    public static class PacoObjects {
        public static T First<T>() where T:UnityEngine.Object {
#if UNITY_2022_2_OR_NEWER
            return UnityEngine.Object.FindFirstObjectByType<T>();
#else
            return UnityEngine.Object.FindObjectOfType<T>();
#endif
        }
    }
    [Serializable] sealed class Surface {public string name,hex;public float metallic,smoothness;}
    [Serializable] sealed class SurfaceFile {public Surface[] materials;}
    public static class PacoAssets {
        static readonly Dictionary<string,Material> materials=new Dictionary<string,Material>();
        static readonly Dictionary<string,GameObject> models=new Dictionary<string,GameObject>();
        public static void Initialize(){
            var data=Resources.Load<TextAsset>("Data/materials");if(data==null)throw new InvalidOperationException("Matériaux manquants. Génère les ressources 3D.");
            Shader shader=Shader.Find("Universal Render Pipeline/Lit");if(shader==null)throw new InvalidOperationException("Le pipeline URP doit être préparé via PACO > Préparer le projet.");
            foreach(var s in JsonConvert.DeserializeObject<SurfaceFile>(data.text).materials){Color color;ColorUtility.TryParseHtmlString("#"+s.hex,out color);var m=new Material(shader){name=s.name,color=color};m.SetFloat("_Metallic",s.metallic);m.SetFloat("_Smoothness",s.smoothness);materials[s.name]=m;}
        }
        public static Material Material(string name){return materials[name];}
        public static GameObject Model(string name,Transform parent,Vector3 position,float scale=1){
            GameObject prefab;if(!models.TryGetValue(name,out prefab)){prefab=Resources.Load<GameObject>("Models/"+name);if(prefab==null)throw new InvalidOperationException("Modèle 3D manquant : "+name);models[name]=prefab;}
            var o=UnityEngine.Object.Instantiate(prefab,parent);o.name=name;o.transform.localPosition=position;o.transform.localScale=Vector3.one*scale;
            foreach(var r in o.GetComponentsInChildren<Renderer>()){
                r.sharedMaterials=r.sharedMaterials.Select(m=>{Material found;string n=m==null?"cream":m.name.Split(' ')[0];if(n.StartsWith("glaze_")&&!materials.ContainsKey(n)){string baseName=n.Substring(6);Material source;if(materials.TryGetValue(baseName,out source)){var gloss=new Material(source){name=n};gloss.SetFloat("_Smoothness",.82f);materials[n]=gloss;}}return materials.TryGetValue(n,out found)?found:materials["cream"];}).ToArray();
            }return o;
        }
        public static GameObject Box(string name,Transform parent,Vector3 position,Vector3 scale,string material){
            var o=GameObject.CreatePrimitive(PrimitiveType.Cube);o.name=name;o.transform.SetParent(parent,false);o.transform.localPosition=position;o.transform.localScale=scale;o.GetComponent<Renderer>().sharedMaterial=materials[material];UnityEngine.Object.Destroy(o.GetComponent<Collider>());return o;
        }
    }

    public static class WallClock {
        public static double Now {
            get {
#if UNITY_ANDROID && !UNITY_EDITOR
                using(var clock=new AndroidJavaClass("android.os.SystemClock")){return clock.CallStatic<long>("elapsedRealtime")/1000.0;}
#else
                return (double)System.Diagnostics.Stopwatch.GetTimestamp()/System.Diagnostics.Stopwatch.Frequency;
#endif
            }
        }
    }
}
