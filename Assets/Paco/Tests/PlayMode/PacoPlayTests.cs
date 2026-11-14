using System.Collections;
using System.Linq;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;
using UnityEngine.UI;
using UnityEngine.SceneManagement;
using Paco.Unity;
namespace Paco.Tests {
    public class PacoPlayTests {
        Button Button(string label){return Object.FindObjectsByType<Button>(FindObjectsSortMode.None).First(b=>b.GetComponentInChildren<Text>()?.text==label);}
        bool Has(string label){return Object.FindObjectsByType<Text>(FindObjectsSortMode.None).Any(t=>t.text==label);}
        [UnityTest] public IEnumerator NewPlayerCanOpenInstructionsAndStartRealBoard(){
            yield return SceneManager.LoadSceneAsync("Main");
            yield return null;yield return null;
            Assert.NotNull(PacoObjects.First<PacoApp>());
            // Intended for an isolated CI sandbox with a new persistentDataPath.
            Button("Jouer et faire grandir ma ville").onClick.Invoke();yield return null;
            Assert.IsTrue(Has("Mission 1 · Épargner"));Assert.NotNull(PacoObjects.First<PuzzleView>());
            Button("C’est parti").onClick.Invoke();yield return new WaitForSecondsRealtime(.15f);
            var puzzle=PacoObjects.First<PuzzleView>();Assert.IsTrue(puzzle.Running);Assert.AreEqual(49,puzzle.GetComponentsInChildren<Piece>().Length);Assert.AreEqual(650,puzzle.Engine.Target);
            Button("Menu").onClick.Invoke();yield return null;Button("Menu principal").onClick.Invoke();yield return null;
            Assert.IsTrue(Has("PACO · Ma ville"));
        }
    }
}
