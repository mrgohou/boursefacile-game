using UnrealBuildTool;
public class PacoUnrealEditorTarget:TargetRules{public PacoUnrealEditorTarget(TargetInfo Target):base(Target){Type=TargetType.Editor;DefaultBuildSettings=BuildSettingsVersion.V5;ExtraModuleNames.Add("PacoUnreal");}}
