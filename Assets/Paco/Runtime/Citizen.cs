using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.EventSystems;
using Paco.Domain;
using Newtonsoft.Json;
namespace Paco.Unity {
    public sealed class Citizen:MonoBehaviour {
        public Vector3[] Route;public float Speed=1;public bool ReducedMotion;int next;Transform left,right;float phase;
        void Start(){left=GetComponentsInChildren<Transform>().FirstOrDefault(t=>t.name.StartsWith("Leg_L"));right=GetComponentsInChildren<Transform>().FirstOrDefault(t=>t.name.StartsWith("Leg_R"));}
        void Update(){if(ReducedMotion||Route==null||Route.Length==0)return;Vector3 to=Route[next]-transform.position;if(to.magnitude<.08f){next=(next+1)%Route.Length;return;}transform.rotation=Quaternion.Slerp(transform.rotation,Quaternion.LookRotation(-to.normalized),Time.deltaTime*5);transform.position=Vector3.MoveTowards(transform.position,Route[next],Time.deltaTime*Speed);phase+=Time.deltaTime*9;if(left!=null)left.localRotation=Quaternion.Euler(Mathf.Sin(phase)*18,0,0);if(right!=null)right.localRotation=Quaternion.Euler(-Mathf.Sin(phase)*18,0,0);}
    }
}
