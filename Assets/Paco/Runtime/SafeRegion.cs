using System;
using System.Collections;
using UnityEngine;
using UnityEngine.UI;
namespace Paco.Unity {
    public sealed class SafeRegion:MonoBehaviour {
        Rect last;Vector2 size;
        void LateUpdate(){if(last==Screen.safeArea&&size==new Vector2(Screen.width,Screen.height))return;last=Screen.safeArea;size=new Vector2(Screen.width,Screen.height);var r=(RectTransform)transform;r.anchorMin=new Vector2(last.xMin/Screen.width,last.yMin/Screen.height);r.anchorMax=new Vector2(last.xMax/Screen.width,last.yMax/Screen.height);r.offsetMin=r.offsetMax=Vector2.zero;}
    }
}
