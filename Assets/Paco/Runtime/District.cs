using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.EventSystems;
using Paco.Domain;
using Newtonsoft.Json;
namespace Paco.Unity {
    public sealed class District:MonoBehaviour {public string Id;public Action<string> Selected;public void Tap(){Selected?.Invoke(Id);}}
}
