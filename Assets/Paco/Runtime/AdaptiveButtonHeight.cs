using System;
using System.Collections;
using UnityEngine;
using UnityEngine.UI;
namespace Paco.Unity {
    public sealed class AdaptiveButtonHeight:MonoBehaviour,ILayoutElement {
        public void CalculateLayoutInputHorizontal(){} public void CalculateLayoutInputVertical(){}
        public float minWidth=>0;public float preferredWidth=>-1;public float flexibleWidth=>1;
        public float minHeight=>144;public float preferredHeight=>Mathf.Max(144*GameUi.FontScale,GetComponentInChildren<Text>().preferredHeight+40);public float flexibleHeight=>0;public int layoutPriority=>2;
    }
}
