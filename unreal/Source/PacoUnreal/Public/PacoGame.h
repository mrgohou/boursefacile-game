#pragma once
#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/HUD.h"
#include "PacoRules.h"
#include "PacoGame.generated.h"
class AStaticMeshActor;
class FJsonObject;
UCLASS()
class PACOUNREAL_API APacoGame:public AGameModeBase {
 GENERATED_BODY()
public:
 APacoGame();virtual void BeginPlay()override;virtual void Tick(float Delta)override;
 TSharedPtr<FJsonObject> Catalog;TSharedPtr<FJsonObject> Save;
 TUniquePtr<Paco::Match3> Puzzle;FString Screen=TEXT("home"),Message;int Selected=-1,CompanyIndex=0,PlotIndex=0,Stage=0;float Seconds=0;
 UPROPERTY() TArray<AStaticMeshActor*> Pieces;
 UPROPERTY() TArray<AActor*> CityActors;
 void Action(FName Name);void Cell(int Index);void Rebuild();void Town();void Trade(bool Buy);bool Persist();int Balance()const;FString Objectives()const;
};
UCLASS()
class PACOUNREAL_API APacoController:public APlayerController {
 GENERATED_BODY()
public:virtual void BeginPlay()override;virtual void SetupInputComponent()override;void Press();void Release();void TouchBegin(ETouchIndex::Type Index,FVector Point);void TouchEnd(ETouchIndex::Type Index,FVector Point);void Point(FVector2D Position,bool Down);int StartCell=-1;
};
UCLASS()
class PACOUNREAL_API APacoHUD:public AHUD {
 GENERATED_BODY()
public:virtual void DrawHUD()override;virtual void NotifyHitBoxClick(FName Name)override;
 TArray<FBox2D> Boxes;TArray<FName> Names;bool Dispatch(FVector2D Point);
 void Button(FString Text,float Y,FName Name,FLinearColor Color=FLinearColor(.1f,.45f,.18f));
};
