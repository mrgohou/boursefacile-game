using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using Newtonsoft.Json;

namespace Paco.Unity {
    public sealed class PacoAudio:MonoBehaviour {
        AudioSource music,fx;readonly Dictionary<string,AudioClip> clips=new Dictionary<string,AudioClip>();
        public bool Music {get;private set;} public bool Effects {get;private set;}
        void Awake(){music=gameObject.AddComponent<AudioSource>();fx=gameObject.AddComponent<AudioSource>();music.loop=true;music.volume=.22f;fx.volume=.45f;Music=PlayerPrefs.GetInt("paco.music",1)==1;Effects=PlayerPrefs.GetInt("paco.sfx",1)==1;}
        AudioClip Clip(string name){AudioClip c;if(!clips.TryGetValue(name,out c)){c=Resources.Load<AudioClip>("Audio/"+name);clips[name]=c;}return c;}
        public void Scene(string name){var clip=Clip(name);if(music.clip==clip)return;music.clip=clip;if(Music)music.Play();}
        public void Play(string name,int chain=1){if(!Effects)return;fx.pitch=Mathf.Min(1.45f,1+(chain-1)*.07f);fx.PlayOneShot(Clip(name));}
        public void ToggleMusic(){Music=!Music;PlayerPrefs.SetInt("paco.music",Music?1:0);if(Music)music.Play();else music.Pause();}
        public void ToggleEffects(){Effects=!Effects;PlayerPrefs.SetInt("paco.sfx",Effects?1:0);}
        void OnApplicationPause(bool paused){if(paused){music.Pause();fx.Stop();}else if(Music)music.UnPause();}
    }
}
