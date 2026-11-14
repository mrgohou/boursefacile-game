using System;
using System.Collections;
using UnityEngine;
using UnityEngine.UI;
namespace Paco.Unity {



    public static class PacoUiInput {
        static readonly System.Collections.Generic.List<UnityEngine.EventSystems.RaycastResult> hits=new System.Collections.Generic.List<UnityEngine.EventSystems.RaycastResult>();
        public static bool OverUi(Vector2 position){var system=UnityEngine.EventSystems.EventSystem.current;if(system==null)return false;hits.Clear();system.RaycastAll(new UnityEngine.EventSystems.PointerEventData(system){position=position},hits);return hits.Count>0;}
    }
    public static class GameUi {
        public static readonly Color Ink=Hex("244B50"),Cream=Hex("FFF5DF"),Green=Hex("23674D"),Purple=Hex("7560AE"),Gold=Hex("FFD16C"),Red=Hex("AC4346"),Muted=Hex("53666A");
        public static Font Font; public static float FontScale=1;
        static Sprite rounded;
        public static Color Hex(string hex){Color c;ColorUtility.TryParseHtmlString("#"+hex,out c);return c;}
        public static void Initialize(){Font=Resources.Load<Font>("Fonts/Nunito");if(Font==null)Font=Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            var t=new Texture2D(64,64,TextureFormat.RGBA32,false);t.name="Paco rounded UI";for(int y=0;y<64;y++)for(int x=0;x<64;x++){Vector2 q=new Vector2(Mathf.Abs(x-31.5f)-15.5f,Mathf.Abs(y-31.5f)-15.5f);float distance=new Vector2(Mathf.Max(q.x,0),Mathf.Max(q.y,0)).magnitude+Mathf.Min(Mathf.Max(q.x,q.y),0)-15;float a=Mathf.Clamp01(.5f-distance);t.SetPixel(x,y,new Color(1,1,1,a));}t.Apply();rounded=Sprite.Create(t,new Rect(0,0,64,64),new Vector2(.5f,.5f),100,0,SpriteMeshType.FullRect,new Vector4(24,24,24,24));}
        public static RectTransform Rect(string name,Transform parent,Vector2 min,Vector2 max,Vector2 insetMin=default(Vector2),Vector2 insetMax=default(Vector2)){
            var o=new GameObject(name,typeof(RectTransform));var r=(RectTransform)o.transform;r.SetParent(parent,false);r.anchorMin=min;r.anchorMax=max;r.offsetMin=insetMin;r.offsetMax=insetMax;return r;
        }
        public static RectTransform Stretch(string name,Transform parent){return Rect(name,parent,Vector2.zero,Vector2.one);}
        public static Image Panel(string name,Transform parent,Color color,bool round=true){var r=Stretch(name,parent);var image=r.gameObject.AddComponent<Image>();image.color=color;if(round){image.sprite=rounded;image.type=Image.Type.Sliced;}return image;}
        public static Text Label(string text,Transform parent,int size=42,Color? color=null,TextAnchor alignment=TextAnchor.UpperLeft){var r=Stretch(text,parent);var t=r.gameObject.AddComponent<Text>();t.text=text;t.font=Font;t.fontSize=Mathf.RoundToInt(size*FontScale);t.color=color??Ink;t.alignment=alignment;t.horizontalOverflow=HorizontalWrapMode.Wrap;t.verticalOverflow=VerticalWrapMode.Overflow;t.raycastTarget=false;return t;}
        public static void Height(Component item,float height){var e=item.gameObject.GetComponent<LayoutElement>()??item.gameObject.AddComponent<LayoutElement>();e.minHeight=height;e.preferredHeight=height;}
        public static Text Paragraph(string text,Transform parent,int size=42,Color? color=null){var t=Label(text,parent,size,color);var e=t.gameObject.AddComponent<LayoutElement>();e.minHeight=size*1.5f;return t;}
        public static RectTransform Column(Transform parent,int spacing=24,int padding=32){var r=Stretch("Content",parent);var layout=r.gameObject.AddComponent<VerticalLayoutGroup>();layout.spacing=spacing;layout.padding=new RectOffset(padding,padding,padding,padding);layout.childControlWidth=true;layout.childForceExpandWidth=true;layout.childControlHeight=true;layout.childForceExpandHeight=false;return r;}
        public static RectTransform Row(Transform parent,int height=144,int spacing=20){var r=Stretch("Actions",parent);var layout=r.gameObject.AddComponent<HorizontalLayoutGroup>();layout.spacing=spacing;layout.childControlWidth=true;layout.childForceExpandWidth=true;layout.childControlHeight=true;layout.childForceExpandHeight=true;Height(r,height);return r;}
        public static Button Button(string text,Transform parent,Action action,Color? color=null,bool enabled=true){
            var image=Panel(text,parent,color??Green);var button=image.gameObject.AddComponent<Button>();button.interactable=enabled;
            var colors=button.colors;colors.normalColor=Color.white;colors.highlightedColor=new Color(.94f,.97f,.94f);colors.pressedColor=new Color(.8f,.86f,.8f);colors.disabledColor=new Color(.65f,.67f,.65f,.75f);button.colors=colors;
            var t=Label(text,image.transform,40,Color.white,TextAnchor.MiddleCenter);((RectTransform)t.transform).offsetMin=new Vector2(20,12);((RectTransform)t.transform).offsetMax=new Vector2(-20,-12);
            Height(button,144*FontScale);button.onClick.AddListener(()=>action?.Invoke());image.gameObject.AddComponent<PressFeedback>();image.gameObject.AddComponent<AdaptiveButtonHeight>();button.navigation=new Navigation{mode=Navigation.Mode.Automatic};return button;
        }
        public static RectTransform Scroll(Transform parent){
            var viewport=Stretch("Scroll view",parent);var image=viewport.gameObject.AddComponent<Image>();image.color=new Color(1,1,1,.005f);viewport.gameObject.AddComponent<RectMask2D>();var scroll=viewport.gameObject.AddComponent<ScrollRect>();scroll.horizontal=false;scroll.movementType=ScrollRect.MovementType.Clamped;scroll.scrollSensitivity=42;
            var content=Rect("Scroll content",viewport,new Vector2(0,1),Vector2.one);content.pivot=new Vector2(.5f,1);var layout=content.gameObject.AddComponent<VerticalLayoutGroup>();layout.spacing=24;layout.padding=new RectOffset(32,32,32,48);layout.childControlWidth=true;layout.childForceExpandWidth=true;layout.childControlHeight=true;layout.childForceExpandHeight=false;
            var fit=content.gameObject.AddComponent<ContentSizeFitter>();fit.verticalFit=ContentSizeFitter.FitMode.PreferredSize;scroll.viewport=viewport;scroll.content=content;return content;
        }
        public static RectTransform Card(Transform parent,Color? color=null){var p=Panel("Card",parent,color??Cream);var l=p.gameObject.AddComponent<LayoutElement>();l.minHeight=180;var layout=p.gameObject.AddComponent<VerticalLayoutGroup>();layout.spacing=18;layout.padding=new RectOffset(28,28,28,28);layout.childControlWidth=true;layout.childForceExpandWidth=true;layout.childControlHeight=true;layout.childForceExpandHeight=false;return (RectTransform)p.transform;}
    }
}
