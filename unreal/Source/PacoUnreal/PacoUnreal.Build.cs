using UnrealBuildTool;
public class PacoUnreal : ModuleRules {
 public PacoUnreal(ReadOnlyTargetRules Target):base(Target){PCHUsage=PCHUsageMode.UseExplicitOrSharedPCHs;PublicDependencyModuleNames.AddRange(new[]{"Core","CoreUObject","Engine","InputCore","Json","JsonUtilities"});}
}
