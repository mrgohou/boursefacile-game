using System;
using System.Collections;
using UnityEngine;
using UnityEngine.UI;
namespace Paco.Unity {
    public sealed class PressFeedback:MonoBehaviour,UnityEngine.EventSystems.IPointerDownHandler,UnityEngine.EventSystems.IPointerUpHandler {
        public void OnPointerDown(UnityEngine.EventSystems.PointerEventData e){if(GetComponent<Button>()?.interactable==true)transform.localScale=Vector3.one*.96f;}
        public void OnPointerUp(UnityEngine.EventSystems.PointerEventData e){transform.localScale=Vector3.one;}
        void OnDisable(){transform.localScale=Vector3.one;}
    }
}
