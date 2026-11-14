using System;
using System.Linq;
using NUnit.Framework;
using UnityEngine;
using UnityEditor;
using Paco.Domain;
namespace Paco.Tests {
    public class PacoEditTests {
        Catalog Catalog(){return new Catalog(Resources.Load<TextAsset>("Data/stages").text,Resources.Load<TextAsset>("Data/lessons").text);}
        [Test] public void AllStagesResolveAndRewardsPersist(){var catalog=Catalog();Player p=new Player();for(int i=0;i<catalog.Stages.Length;i++){var e=new MatchEngine(catalog.Stages[i]);int budget=e.Moves;while(!e.Won&&budget-->0){int[] hint=MatchEngine.Hint(e.Board);Assert.NotNull(hint);Assert.IsTrue(e.Swap(hint[0],hint[1]));}Assert.IsTrue(e.Won);p=PlayerCodec.Decode(PlayerCodec.Encode(p.Win(i,30).Learn(i,30),30),30);}Assert.AreEqual(55000,p.cash);Assert.AreEqual(30,p.Unlocked(30));}
        [Test] public void OriginalModelsAndMaterialPaletteImport(){foreach(string name in new[]{"house","farm","shop","telecom","bank","factory","energy","services","tree","palm","person","car","fountain","tile_cacao","tile_phone","tile_cash","tile_fuel","tile_bulb","tile_gear","title_win","title_lose"}){var model=Resources.Load<GameObject>("Models/"+name);Assert.NotNull(model,name);Assert.IsTrue(model.GetComponentsInChildren<MeshFilter>().Any(),name);}Assert.NotNull(Resources.Load<TextAsset>("Data/materials"));Assert.NotNull(Shader.Find("Universal Render Pipeline/Lit"));}
        [Test] public void CompanionsHaveFifteenDestinationsAndFortyFiveQuizzes(){var all=Newtonsoft.Json.JsonConvert.DeserializeObject<JourneyFile>(Resources.Load<TextAsset>("Data/journey").text);Assert.AreEqual(15,all.destinations.Length);foreach(var d in all.destinations){Assert.AreEqual(3,d.questions.Length);foreach(var q in d.questions)Assert.That(q.answer,Is.InRange(0,q.options.Length-1));}}
        [Test] public void SceneAndRetainedShaderExist(){Assert.NotNull(AssetDatabase.LoadAssetAtPath<SceneAsset>("Assets/Paco/Scenes/Main.unity"));Assert.NotNull(Resources.Load<Material>("Materials/RetainedLit"));}
    }
}
