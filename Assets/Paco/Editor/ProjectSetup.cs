using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using Paco.Unity;

namespace Paco.Editor {
    public static class ProjectSetup {
        const string Generated="Assets/Paco/Generated";
        const string ScenePath="Assets/Paco/Scenes/Main.unity";
        [InitializeOnLoadMethod] static void Schedule(){EditorApplication.delayCall+=()=>{if(!EditorApplication.isPlayingOrWillChangePlaymode&&!AssetDatabase.IsValidFolder(Generated))Prepare();};}
        [MenuItem("PACO/Préparer le projet")]
        public static void Prepare(){
            Directory.CreateDirectory(Generated);Directory.CreateDirectory("Assets/Paco/Scenes");AssetDatabase.Refresh();
            string path=Generated+"/PacoURP.asset";var pipeline=AssetDatabase.LoadAssetAtPath<UniversalRenderPipelineAsset>(path);
            if(pipeline==null){pipeline=UniversalRenderPipelineAsset.Create();AssetDatabase.CreateAsset(pipeline,path);AssetDatabase.AddObjectToAsset(pipeline.rendererDataList[0],pipeline);}
            pipeline.supportsHDR=true;pipeline.msaaSampleCount=4;pipeline.renderScale=1;pipeline.shadowDistance=45;pipeline.shadowCascadeCount=2;pipeline.supportsMainLightShadows=true;
            GraphicsSettings.defaultRenderPipeline=pipeline;QualitySettings.renderPipeline=pipeline;QualitySettings.vSyncCount=0;QualitySettings.shadows=ShadowQuality.All;QualitySettings.shadowResolution=ShadowResolution.High;
            PlayerSettings.companyName="PACO";PlayerSettings.productName="PACO Unity";PlayerSettings.bundleVersion="0.1.0";
            PlayerSettings.SetApplicationIdentifier(NamedBuildTarget.Android,"ci.paco.bourse.unity");PlayerSettings.Android.bundleVersionCode=1;PlayerSettings.Android.minSdkVersion=AndroidSdkVersions.AndroidApiLevel24;PlayerSettings.Android.targetSdkVersion=AndroidSdkVersions.AndroidApiLevelAuto;PlayerSettings.Android.targetArchitectures=AndroidArchitecture.ARM64;
            PlayerSettings.SetScriptingBackend(NamedBuildTarget.Android,ScriptingImplementation.IL2CPP);PlayerSettings.colorSpace=ColorSpace.Linear;PlayerSettings.defaultInterfaceOrientation=UIOrientation.Portrait;
            PlayerSettings.SetManagedStrippingLevel(NamedBuildTarget.Android,ManagedStrippingLevel.Low);PlayerSettings.SetUseDefaultGraphicsAPIs(BuildTarget.Android,false);PlayerSettings.SetGraphicsAPIs(BuildTarget.Android,new[]{UnityEngine.Rendering.GraphicsDeviceType.OpenGLES3});
            // Legacy input supports both mouse and Android touch; no secondary input package.
            var settings=new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/ProjectSettings.asset")[0]);var input=settings.FindProperty("activeInputHandler");if(input!=null){input.intValue=0;settings.ApplyModifiedPropertiesWithoutUndo();}
            EditorSettings.serializationMode=SerializationMode.ForceText;
            // Keep the URP shader reachable when materials are selected dynamically at runtime.
            var material=new Material(Shader.Find("Universal Render Pipeline/Lit"));if(!File.Exists(Generated+"/RetainedLit.mat"))AssetDatabase.CreateAsset(material,Generated+"/RetainedLit.mat");else UnityEngine.Object.DestroyImmediate(material);
            Directory.CreateDirectory("Assets/Paco/Resources/Materials");if(!File.Exists("Assets/Paco/Resources/Materials/RetainedLit.mat"))AssetDatabase.CopyAsset(Generated+"/RetainedLit.mat","Assets/Paco/Resources/Materials/RetainedLit.mat");
            if(!File.Exists(ScenePath)){
                var scene=EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Single);
                var camera=new GameObject("World camera",typeof(Camera),typeof(AudioListener));camera.tag="MainCamera";camera.GetComponent<Camera>().orthographic=true;var data=camera.AddComponent<UniversalAdditionalCameraData>();data.renderPostProcessing=true;data.antialiasing=AntialiasingMode.FastApproximateAntialiasing;data.stopNaN=true;
                var volume=new GameObject("Gentle finishing",typeof(Volume)).GetComponent<Volume>();volume.isGlobal=true;
                var profile=ScriptableObject.CreateInstance<VolumeProfile>();var bloom=profile.Add<Bloom>(true);bloom.intensity.Override(.12f);bloom.threshold.Override(1.2f);bloom.scatter.Override(.5f);
                var tone=profile.Add<Tonemapping>(true);tone.mode.Override(TonemappingMode.Neutral);
                AssetDatabase.CreateAsset(profile,Generated+"/PacoFinish.asset");volume.sharedProfile=profile;EditorSceneManager.SaveScene(scene,ScenePath);
            }
            EditorBuildSettings.scenes=new[]{new EditorBuildSettingsScene(ScenePath,true)};AssetDatabase.SaveAssets();AssetDatabase.Refresh();Debug.Log("PACO project prepared. Open Main scene, then Play.");
        }
        [MenuItem("PACO/Compiler Android ARM64")]
        public static void Android(){Prepare();Directory.CreateDirectory("Builds/Android");EditorUserBuildSettings.buildAppBundle=false;var report=BuildPipeline.BuildPlayer(new BuildPlayerOptions{scenes=new[]{ScenePath},locationPathName="Builds/Android/paco-unity-0.1.0-arm64.apk",target=BuildTarget.Android,options=BuildOptions.None});if(report.summary.result!=BuildResult.Succeeded)throw new Exception("Unity Android build failed: "+report.summary.result);}
        public static void ConfigureForCi(){Prepare();}
    }
    public sealed class PacoModelImport:AssetPostprocessor {
        void OnPreprocessModel(){if(!assetPath.StartsWith("Assets/Paco/Resources/Models/"))return;var importer=(ModelImporter)assetImporter;importer.globalScale=1;importer.importAnimation=false;importer.importCameras=false;importer.importLights=false;importer.isReadable=true;importer.meshCompression=ModelImporterMeshCompression.Low;}
        void OnPreprocessAudio(){if(!assetPath.StartsWith("Assets/Paco/Resources/Audio/"))return;var importer=(AudioImporter)assetImporter;var settings=importer.defaultSampleSettings;bool loop=assetPath.EndsWith("city.wav")||assetPath.EndsWith("puzzle.wav");settings.loadType=loop?AudioClipLoadType.Streaming:AudioClipLoadType.DecompressOnLoad;settings.compressionFormat=AudioCompressionFormat.Vorbis;settings.quality=.7f;importer.defaultSampleSettings=settings;importer.forceToMono=false;}
    }
}
