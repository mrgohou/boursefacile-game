using System;
using System.Collections;
using System.IO;
using System.Linq;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using Paco.Domain;
using Newtonsoft.Json;

namespace Paco.Unity {
    public sealed class PacoApp:MonoBehaviour {
        Catalog catalog;Destination[] destinations;Player player;SaveStore store;Camera worldCamera;PacoAudio audioService;
        CityView city;PuzzleView puzzle;RectTransform ui,screen,modal;Canvas canvas;Text scoreLabel,timeLabel,movesLabel,comboLabel;
        bool reduced,busy;string page="city",lastMessage;int stage;bool winSaved;GameObject titleWorld;Camera titleCamera;RenderTexture titleTexture;
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)] static void Boot(){if(PacoObjects.First<PacoApp>()==null)new GameObject("PACO Unity application").AddComponent<PacoApp>();}
        void Start(){
            try {
                Application.targetFrameRate=60;Screen.sleepTimeout=SleepTimeout.SystemSetting;reduced=PlayerPrefs.GetInt("paco.reducedMotion",0)==1;
                GameUi.Initialize();GameUi.FontScale=PlayerPrefs.GetInt("paco.largeText",0)==1?1.2f:1;
                catalog=new Catalog(Resources.Load<TextAsset>("Data/stages").text,Resources.Load<TextAsset>("Data/lessons").text);
                destinations=JsonConvert.DeserializeObject<JourneyFile>(Resources.Load<TextAsset>("Data/journey").text).destinations;
                store=new SaveStore(Path.Combine(Application.persistentDataPath,"paco-unity-v4.json"),catalog.Stages.Length);
                CreateCanvas();PacoAssets.Initialize();worldCamera=Camera.main;if(worldCamera==null)worldCamera=new GameObject("World camera").AddComponent<Camera>();worldCamera.tag="MainCamera";worldCamera.orthographic=true;worldCamera.allowHDR=true;worldCamera.backgroundColor=GameUi.Hex("BCE6E4");worldCamera.cullingMask=~(1<<31);
                if(PacoObjects.First<AudioListener>()==null)worldCamera.gameObject.AddComponent<AudioListener>();
                audioService=gameObject.AddComponent<PacoAudio>();ConfigureLight();player=store.Load();ShowCity();
            }catch(Exception e){if(ui==null){GameUi.Initialize();CreateCanvas();}ErrorScreen("Le jeu n’a pas pu démarrer.",e.Message);Debug.LogException(e);}
        }
        void CreateCanvas(){
            var root=new GameObject("Mobile interface",typeof(RectTransform),typeof(Canvas),typeof(CanvasScaler),typeof(GraphicRaycaster));canvas=root.GetComponent<Canvas>();canvas.renderMode=RenderMode.ScreenSpaceOverlay;canvas.sortingOrder=10;var scaler=root.GetComponent<CanvasScaler>();scaler.uiScaleMode=CanvasScaler.ScaleMode.ScaleWithScreenSize;scaler.referenceResolution=new Vector2(1080,1920);scaler.matchWidthOrHeight=0;
            ui=GameUi.Stretch("Safe area",root.transform);ui.gameObject.AddComponent<SafeRegion>();if(EventSystem.current==null)new GameObject("Event system",typeof(EventSystem),typeof(StandaloneInputModule));
        }
        void ConfigureLight(){
            RenderSettings.ambientMode=UnityEngine.Rendering.AmbientMode.Trilight;RenderSettings.ambientSkyColor=new Color(.7f,.82f,.9f);RenderSettings.ambientEquatorColor=new Color(.55f,.65f,.6f);RenderSettings.ambientGroundColor=new Color(.35f,.42f,.3f);RenderSettings.fog=false;
            if(PacoObjects.First<Light>()==null){var sun=new GameObject("Warm afternoon sun").AddComponent<Light>();sun.type=LightType.Directional;sun.transform.rotation=Quaternion.Euler(48,-35,0);sun.color=new Color(1,.94f,.82f);sun.intensity=1.45f;sun.shadows=LightShadows.Soft;sun.shadowStrength=.6f;RenderSettings.sun=sun;}
        }
        RectTransform NewScreen(bool opaque=true){if(screen!=null)Destroy(screen.gameObject);var panel=GameUi.Panel("Screen "+page,ui,opaque?GameUi.Hex("E8F2EF"):Color.clear,false);panel.raycastTarget=opaque;screen=(RectTransform)panel.transform;return screen;}
        void ClearWorld(){if(city!=null){Destroy(city.gameObject);city=null;}if(puzzle!=null){Destroy(puzzle.gameObject);puzzle=null;}worldCamera.rect=new Rect(0,0,1,1);}
        void CloseModal(){if(modal!=null)Destroy(modal.gameObject);modal=null;if(titleWorld!=null)Destroy(titleWorld);if(titleCamera!=null){titleCamera.enabled=false;titleCamera.targetTexture=null;Destroy(titleCamera.gameObject);}if(titleTexture!=null){titleTexture.Release();Destroy(titleTexture);}titleWorld=null;titleCamera=null;titleTexture=null;}
        RectTransform Modal(string title){
            CloseModal();var scrim=GameUi.Panel("Modal shield",ui,new Color(.04f,.1f,.13f,.64f),false);modal=(RectTransform)scrim.transform;var box=GameUi.Rect("Dialog",modal,new Vector2(.06f,.12f),new Vector2(.94f,.88f));GameUi.Panel("Cream dialog",box,GameUi.Cream);var body=GameUi.Scroll(box);GameUi.Paragraph(title,body,64);return body;
        }
        void Header(string title,Action back=null){var box=GameUi.Rect("Header",screen,new Vector2(0,.85f),Vector2.one,new Vector2(30,0),new Vector2(-30,-20));var col=GameUi.Column(box,12,0);GameUi.Paragraph(title,col,64);if(back!=null){var b=GameUi.Button("Retour à la ville",col,back,GameUi.Purple);GameUi.Height(b,144);}}
        RectTransform Body(float bottom=.03f,float top=.835f){return GameUi.Scroll(GameUi.Rect("Page content",screen,new Vector2(0,bottom),new Vector2(1,top)));}
        void Toast(string message){lastMessage=message;var p=Modal("Paco t’informe");GameUi.Paragraph(message,p);GameUi.Button("Compris",p,CloseModal);}
        bool Commit(Func<Player,Player> change){if(busy)return false;busy=true;try{Player next=change(player);store.Save(next);player=next;audioService.Play("ui");return true;}catch(Exception e){Toast(e.Message);return false;}finally{busy=false;}}
        void ErrorScreen(string title,string detail){page="error";NewScreen();var p=Body();GameUi.Paragraph(title,p,64);GameUi.Paragraph(detail,p);GameUi.Paragraph("La sauvegarde reste sur l’appareil. Une réinitialisation doit être volontaire.",p);GameUi.Button("Réessayer",p,()=>{Destroy(gameObject);UnityEngine.SceneManagement.SceneManager.LoadScene(0);});}
        void ShowCity(){
            CloseModal();ClearWorld();page="city";NewScreen(false);audioService.Scene("city");worldCamera.backgroundColor=GameUi.Hex("BCE6E4");
            city=new GameObject("Lagoon town").AddComponent<CityView>();city.ReducedMotion=reduced;city.OnDistrict=ShowLand;city.Initialize(worldCamera,player);
            var hud=GameUi.Rect("City HUD",screen,new Vector2(.025f,.79f),new Vector2(.975f,.99f));var p=GameUi.Panel("HUD",hud,GameUi.Cream);var c=GameUi.Column(p.transform,10,24);GameUi.Paragraph("PACO · Ma ville",c,62);GameUi.Paragraph(player.cash.ToString("N0")+" FCFA-jeu · "+player.answered.Count+" / "+catalog.Stages.Length+" étapes",c,38);var row=GameUi.Row(c,144,16);GameUi.Button("Réglages",row,ShowSettings,GameUi.Purple);GameUi.Button("Recentrer",row,()=>city.Recenter(),GameUi.Purple);GameUi.Button("Voyager",row,ShowJourney,GameUi.Green);
            var mission=GameUi.Rect("Next mission",screen,new Vector2(.035f,.15f),new Vector2(.965f,.31f));var m=GameUi.Column(GameUi.Panel("Mission panel",mission,GameUi.Cream).transform,10,20);int next=player.Unlocked(catalog.Stages.Length);GameUi.Paragraph(next<catalog.Stages.Length?"Étape "+(next+1)+" · "+catalog.Lessons[next].topic:"Parcours terminé · bravo !",m,46);GameUi.Button(next<catalog.Stages.Length?"Jouer et faire grandir ma ville":"Revoir les étapes",m,()=>{if(next<catalog.Stages.Length)OpenStage(next);else ShowStages();});
            var dock=GameUi.Rect("Main navigation",screen,new Vector2(.025f,.02f),new Vector2(.975f,.13f));var r=GameUi.Row(dock,150,12);GameUi.Button("Étapes",r,ShowStages,GameUi.Purple);GameUi.Button("Acquis",r,ShowProperties,GameUi.Green);GameUi.Button("Cartes",r,ShowCards,GameUi.Purple);GameUi.Button("Agrandir",r,ShowLands,GameUi.Green);
        }
        void ShowStages(){
            CloseModal();ClearWorld();page="stages";NewScreen();Header("Le chemin de Paco",ShowCity);var body=Body();int unlocked=player.Unlocked(catalog.Stages.Length);
            GameUi.Paragraph("30 étapes · cinq chapitres",body,48);if(unlocked<catalog.Stages.Length)GameUi.Button("Continuer · étape "+(unlocked+1),body,()=>OpenStage(unlocked));
            for(int i=0;i<catalog.Stages.Length;i++){int index=i;Stage s=catalog.Stages[i];var card=GameUi.Card(body,i<=unlocked?GameUi.Cream:GameUi.Hex("D6DFD8"));GameUi.Paragraph("Chapitre "+s.chapter+" · "+(i+1)+". "+catalog.Lessons[i].topic,card,48);GameUi.Paragraph(s.target+" points · "+s.moves+" coups · "+s.seconds+" s",card,36);GameUi.Button(i>unlocked?"Verrouillé":player.answered.Contains(i)?"Rejouer":player.completed.Contains(i)?"Comprendre avec Paco":"Jouer",card,()=>OpenStage(index),null,i<=unlocked);}
        }
        void OpenStage(int index){
            if(index<0||index>=catalog.Stages.Length||index>player.Unlocked(catalog.Stages.Length))return;
            if(player.completed.Contains(index)&&!player.answered.Contains(index)){ShowQuiz(index);return;}
            CloseModal();ClearWorld();page="puzzle";stage=index;winSaved=false;NewScreen(false);audioService.Scene("puzzle");
            puzzle=new GameObject("3D match board").AddComponent<PuzzleView>();puzzle.Initialize(catalog.Stages[index],worldCamera,audioService,reduced);puzzle.Result=ShowResult;puzzle.Stats=UpdateStats;puzzle.Feedback=Combo;
            var head=GameUi.Rect("Puzzle HUD",screen,new Vector2(.035f,.83f),new Vector2(.965f,.99f));var c=GameUi.Column(GameUi.Panel("Puzzle HUD panel",head,GameUi.Cream).transform,8,20);GameUi.Paragraph("Étape "+(index+1)+" · "+catalog.Lessons[index].topic,c,50);scoreLabel=GameUi.Paragraph("",c,38);var r=GameUi.Row(c,85,24);timeLabel=GameUi.Label("",r,44,GameUi.Red);movesLabel=GameUi.Label("",r,42);
            var bottom=GameUi.Rect("Puzzle actions",screen,new Vector2(.035f,.02f),new Vector2(.965f,.16f));var col=GameUi.Column(bottom,8,0);comboLabel=GameUi.Paragraph("Aligne au moins trois pièces.",col,40);var actions=GameUi.Row(col,144,16);GameUi.Button("Indice",actions,()=>puzzle.Hint(),GameUi.Purple);GameUi.Button("Consigne",actions,()=>Instructions(false),GameUi.Purple);GameUi.Button("Menu",actions,LeaveRound,GameUi.Green);
            UpdateStats(puzzle.Engine.Score,puzzle.Engine.Moves,puzzle.Engine.Target,catalog.Stages[index].seconds);Instructions(true);
        }
        void UpdateStats(int score,int moves,int target,int remaining){if(scoreLabel==null)return;scoreLabel.text=score.ToString("N0")+" / "+target.ToString("N0")+" points";movesLabel.text=moves+" coups";timeLabel.text=(remaining/60)+":"+(remaining%60).ToString("00");}
        void Combo(string text){if(comboLabel!=null)comboLabel.text=text;}
        void Instructions(bool initial){
            var p=Modal("Mission "+(stage+1)+" · "+catalog.Lessons[stage].topic);Stage s=catalog.Stages[stage];GameUi.Paragraph("Atteins "+s.target+" points en "+s.seconds+" secondes et "+s.moves+" coups maximum.",p,46);
            GameUi.Paragraph("Glisse une pièce vers une voisine pour aligner au moins trois symboles. Tu peux aussi toucher deux cases voisines. Un échange sans combinaison revient en place sans utiliser de coup.",p);
            GameUi.Paragraph(initial?"Le chrono démarre avec « C’est parti ». Ensuite, il continue en arrière-plan et pendant la lecture de l’aide.":"Le chrono continue pendant cette aide.",p,38,GameUi.Muted);
            GameUi.Button(initial?"C’est parti":"Reprendre",p,()=>{CloseModal();if(initial)puzzle.StartRound();});GameUi.Button("Menu principal",p,()=>{if(initial)ShowCity();else LeaveRound();},GameUi.Purple);
        }
        void LeaveRound(){if(puzzle!=null&&!puzzle.Running&&!puzzle.Finished){ShowCity();return;}if(puzzle!=null&&puzzle.Busy){Combo("La combinaison se termine…");return;}if(puzzle!=null&&puzzle.Finished){ShowResult(puzzle.Engine.Won);return;}var p=Modal("Quitter cette partie ?");GameUi.Paragraph("La progression de ce puzzle sera perdue. Tes acquis restent conservés.",p);GameUi.Button("Continuer la partie",p,CloseModal);GameUi.Button("Menu principal",p,ShowCity,GameUi.Purple);}
        void ShowResult(bool won){
            if(won&&!winSaved){try{Player next=player.Win(stage,catalog.Stages.Length);store.Save(next);player=next;winSaved=true;}catch(Exception e){var retry=Modal("Enregistrement à reprendre");GameUi.Paragraph("La victoire est obtenue, mais la sauvegarde a échoué : "+e.Message,retry);GameUi.Button("Réessayer l’enregistrement",retry,()=>ShowResult(true));return;}}
            var p=Modal(won?"Mission accomplie":"Une nouvelle tentative ?");ShowClayTitle(won);
            GameUi.Paragraph(won?("Victoire enregistrée. La récompense de 1 500 FCFA-jeu est attribuée une seule fois par étape. Vérifie la notion pour poursuivre."):"Le temps ou les coups sont épuisés. Tu peux réessayer sans perdre tes acquis.",p,44);
            if(won)GameUi.Button("Comprendre avec Paco",p,()=>ShowQuiz(stage));else GameUi.Button("Réessayer",p,()=>OpenStage(stage));
            GameUi.Button("Menu principal",p,ShowCity,GameUi.Purple);
        }
        void ShowClayTitle(bool won){
            // Beveled, extruded text geometry rendered by a dedicated camera above the modal.
            titleWorld=PacoAssets.Model(won?"title_win":"title_lose",null,new Vector3(0,1000,0));titleWorld.transform.rotation=Quaternion.Euler(-90,0,0);
            foreach(var t in titleWorld.GetComponentsInChildren<Transform>())t.gameObject.layer=31;
            titleCamera=new GameObject("Clay title camera").AddComponent<Camera>();titleCamera.orthographic=true;titleCamera.transform.SetPositionAndRotation(new Vector3(0,1000,-15),Quaternion.identity);titleCamera.cullingMask=1<<31;titleCamera.clearFlags=CameraClearFlags.SolidColor;titleCamera.backgroundColor=Color.clear;titleCamera.allowHDR=false;
            titleTexture=new RenderTexture(1024,256,16,RenderTextureFormat.ARGB32);titleCamera.targetTexture=titleTexture;
            Bounds bounds=new Bounds(titleWorld.transform.position,Vector3.zero);foreach(var renderer in titleWorld.GetComponentsInChildren<Renderer>())bounds.Encapsulate(renderer.bounds);titleCamera.transform.position=new Vector3(bounds.center.x,bounds.center.y,-15);titleCamera.orthographicSize=Mathf.Max(bounds.size.y*.65f,bounds.size.x*.15f);
            var r=GameUi.Rect("Bouncing clay title",modal,new Vector2(.04f,.86f),new Vector2(.96f,.98f));var raw=r.gameObject.AddComponent<RawImage>();raw.texture=titleTexture;raw.raycastTarget=false;if(!reduced)StartCoroutine(Bounce(r));
        }
        IEnumerator Bounce(RectTransform r){for(float t=0;t<1;t+=Time.unscaledDeltaTime/.42f){if(r==null)yield break;float x=t-1;float v=1+2.7f*x*x*x+1.7f*x*x;r.localScale=Vector3.one*Mathf.Max(.1f,v);yield return null;}if(r!=null)r.localScale=Vector3.one;}
        void ShowQuiz(int index){
            CloseModal();ClearWorld();page="quiz";NewScreen();Header("Comprendre avec Paco",ShowCity);var body=Body();Stage lesson=catalog.Lessons[index];GameUi.Paragraph("Étape "+(index+1)+" · "+lesson.topic,body,58);GameUi.Paragraph(lesson.question,body,48);
            for(int i=0;i<lesson.options.Length;i++){int answer=i;GameUi.Button(lesson.options[i],body,()=>{
                bool correct=answer==lesson.answer;if(correct&&!Commit(p=>p.Learn(index,catalog.Stages.Length)))return;
                var result=Modal(correct?"Bien compris !":"Essaie encore");GameUi.Paragraph(correct?lesson.explanation:"Tu peux réessayer sans pénalité. Prends le temps de comparer les réponses.",result);
                GameUi.Button(correct?(index==catalog.Stages.Length-1?"Parcours terminé · ma ville":"Continuer vers la suite"):"Réessayer",result,()=>{if(correct){if(index+1<catalog.Stages.Length)OpenStage(index+1);else ShowCity();}else CloseModal();});GameUi.Button("Menu principal",result,ShowCity,GameUi.Purple);
            },GameUi.Green);}
        }
        void ShowProperties(){
            CloseModal();ClearWorld();page="properties";NewScreen();Header("Mes acquis",ShowCity);var body=Body();GameUi.Paragraph("Solde : "+player.cash.ToString("N0")+" FCFA-jeu",body,48);GameUi.Paragraph("Cash + parts : "+player.TotalValue().ToString("N0")+" FCFA-jeu. Les terrains sont des dépenses de jeu distinctes.",body,36,GameUi.Muted);
            foreach(var company in EconomyCatalog.Companies){var c=company;var card=GameUi.Card(body);GameUi.Paragraph(c.Name,card,50);GameUi.Paragraph(player.holdings[c.Id]+" part(s) · "+player.prices[c.Id]+" FCFA-jeu / part",card);var actions=GameUi.Row(card,150);GameUi.Button("Acheter plus",actions,()=>Trade(c.Id,true),GameUi.Green,player.answered.Contains(1));GameUi.Button("Vendre",actions,()=>Trade(c.Id,false),GameUi.Red,player.holdings[c.Id]>0);}
            if(!player.answered.Contains(1))GameUi.Paragraph("Termine les deux premières notions pour ouvrir les échanges.",body);
            foreach(var l in EconomyCatalog.Lands.Where(l=>player.ownedPlots.Contains(l.Id))){var land=l;var card=GameUi.Card(body);GameUi.Paragraph(l.Name,card,48);string id;GameUi.Paragraph(player.townBuildings.TryGetValue(l.Id,out id)?EconomyCatalog.Buildings.First(b=>b.Id==id).Name:"Terrain acquis et libre",card);GameUi.Button("Voir le quartier",card,()=>ShowLand(land.Id),GameUi.Purple);}
            GameUi.Button("Scénario : baisse du cacao",body,()=>{if(Commit(p=>p.Drop(catalog.Stages.Length)))ShowProperties();},GameUi.Purple,!player.marketDropped&&player.answered.Contains(2));GameUi.Button("Démonstration du dividende",body,()=>{if(Commit(p=>p.Dividend(catalog.Stages.Length)))ShowProperties();},GameUi.Purple,!player.dividendPaid&&player.answered.Contains(4)&&player.marketDropped&&player.holdings["cacao"]>0);
        }
        void Trade(string id,bool buy){int price=player.prices[id];var p=Modal(buy?"Acheter une part de plus":"Vendre une part");GameUi.Paragraph("Cours : "+price+" FCFA-jeu · frais : "+EconomyCatalog.Fee(price)+" FCFA-jeu. Tout l’argent de cette simulation est fictif.",p);GameUi.Button(buy?"Confirmer l’achat":"Confirmer la vente",p,()=>{if(Commit(s=>s.Trade(id,buy,catalog.Stages.Length)))ShowProperties();},buy?GameUi.Green:GameUi.Red);GameUi.Button("Annuler",p,CloseModal,GameUi.Purple);}
        void ShowCards(){
            CloseModal();ClearWorld();page="cards";NewScreen();Header("Mes cartes",ShowCity);var body=Body();GameUi.Paragraph("Les cartes restent acquises après la vente des parts.",body);
            foreach(var c in EconomyCatalog.Companies){var card=GameUi.Card(body);GameUi.Paragraph(c.Name,card,50);GameUi.Paragraph(player.companyCards.Contains(c.Id)?"Carte acquise · collection permanente":"Carte à découvrir avec une première part",card);}
            GameUi.Paragraph("Notions comprises : "+player.answered.Count+" / "+catalog.Stages.Length,body,48);foreach(int i in player.answered.OrderBy(x=>x))GameUi.Paragraph((i+1)+" · "+catalog.Lessons[i].topic,body,38);
        }
        void ShowLands(){
            CloseModal();ClearWorld();page="lands";NewScreen();Header("Agrandir ma ville",ShowCity);var body=Body();GameUi.Paragraph("Gains obtenus : "+player.Gains.ToString("N0")+" FCFA-jeu",body,46);GameUi.Paragraph("Gagne des puzzles pour débloquer les quartiers. Leur achat utilise ensuite ton solde disponible.",body);
            foreach(var l in EconomyCatalog.Lands){var land=l;var card=GameUi.Card(body);GameUi.Paragraph(l.Name,card,50);GameUi.Paragraph(player.ownedPlots.Contains(l.Id)?"Terrain acquis":l.Price+" FCFA-jeu · dès "+l.Gains+" de gains",card);GameUi.Button(player.ownedPlots.Contains(l.Id)?"Aménager":"Découvrir ce terrain",card,()=>ShowLand(land.Id),GameUi.Green);}
        }
        void ShowLand(string id){
            Land l=EconomyCatalog.Lands.First(x=>x.Id==id);var p=Modal(l.Name);
            if(!player.ownedPlots.Contains(id)){GameUi.Paragraph("Prix : "+l.Price+" FCFA-jeu. Seuil : "+l.Gains+" de gains. Ton solde : "+player.cash+".",p);GameUi.Button("Acheter le terrain",p,()=>{if(Commit(s=>s.BuyLand(id,catalog.Stages.Length)))ShowCity();});}
            else if(player.townBuildings.ContainsKey(id))GameUi.Paragraph("Bâtiment acquis : "+EconomyCatalog.Buildings.First(b=>b.Id==player.townBuildings[id]).Name,p,46);
            else{GameUi.Paragraph("Terrain acquis. Choisis son premier bâtiment.",p);foreach(var building in EconomyCatalog.Buildings){var b=building;GameUi.Button(b.Name+" · "+b.Cost+" FCFA-jeu",p,()=>{if(Commit(s=>s.Build(id,b.Id,catalog.Stages.Length)))ShowCity();});}}
            GameUi.Button("Fermer",p,CloseModal,GameUi.Purple);
        }
        void ShowSettings(){
            var p=Modal("À ton rythme");GameUi.Button("Musique : "+(audioService.Music?"active":"coupée"),p,()=>{audioService.ToggleMusic();ShowSettings();},GameUi.Purple);GameUi.Button("Bruitages : "+(audioService.Effects?"actifs":"coupés"),p,()=>{audioService.ToggleEffects();ShowSettings();},GameUi.Purple);
            GameUi.Button("Mouvements réduits : "+(reduced?"oui":"non"),p,()=>{reduced=!reduced;PlayerPrefs.SetInt("paco.reducedMotion",reduced?1:0);ShowCity();ShowSettings();},GameUi.Purple);
            GameUi.Button("Grands textes : "+(GameUi.FontScale>1?"oui":"non"),p,()=>{GameUi.FontScale=GameUi.FontScale>1?1:1.2f;PlayerPrefs.SetInt("paco.largeText",GameUi.FontScale>1?1:0);ShowCity();ShowSettings();},GameUi.Purple);
            GameUi.Button("Exporter ma sauvegarde",p,ExportSave,GameUi.Purple);GameUi.Button("Importer une sauvegarde",p,ImportSave,GameUi.Purple);
            GameUi.Paragraph("Démo locale · entreprises et monnaie fictives. La sauvegarde Unity est indépendante des éditions Flutter et Kotlin.",p,36,GameUi.Muted);GameUi.Button("Fermer",p,CloseModal,GameUi.Green);
        }

        void ShowJourney(){
            CloseModal();ClearWorld();page="journey";NewScreen();Header("Voyager avec Paco",ShowCity);var body=Body();GameUi.Paragraph("15 destinations · 45 quiz · +300 FCFA-jeu par notion, une seule fois.",body);
            for(int i=0;i<destinations.Length;i++){int cityIndex=i;Destination d=destinations[i];var card=GameUi.Card(body);GameUi.Paragraph((i+1)+". "+d.name+" · "+d.country,card,48);GameUi.Paragraph(d.topic,card);GameUi.Button(JourneyRules.Available(player,i)?"Découvrir":"Verrouillé",card,()=>ShowDestination(cityIndex),GameUi.Green,JourneyRules.Available(player,i));}
        }
        void ShowDestination(int cityIndex){
            var d=destinations[cityIndex];var p=Modal(d.name+" · "+d.topic);GameUi.Paragraph(d.intro,p);GameUi.Paragraph(d.reminder,p,40,GameUi.Muted);
            for(int i=0;i<d.questions.Length;i++){int question=i;GameUi.Button("Notion "+(i+1)+(player.journeyAnswers.Contains(cityIndex*3+i)?" · comprise":" · +300 FCFA-jeu"),p,()=>ShowJourneyQuestion(cityIndex,question),GameUi.Green);}
            GameUi.Button("Retour aux destinations",p,ShowJourney,GameUi.Purple);
        }
        void ShowJourneyQuestion(int cityIndex,int question){
            var q=destinations[cityIndex].questions[question];var p=Modal(q.question);
            for(int i=0;i<q.options.Length;i++){int index=i;GameUi.Button(q.options[i],p,()=>{bool correct=index==q.answer;if(correct&&!Commit(s=>JourneyRules.Answer(s,cityIndex,question,catalog.Stages.Length)))return;var result=Modal(correct?"Bien compris !":"Réessaie");GameUi.Paragraph(correct?q.explanation:"Compare les réponses. Aucun acquis n’est perdu.",result);GameUi.Button("Continuer",result,()=>{if(correct)ShowDestination(cityIndex);else ShowJourneyQuestion(cityIndex,question);});});}
            GameUi.Button("Fermer",p,()=>ShowDestination(cityIndex),GameUi.Purple);
        }
        void ExportSave(){GUIUtility.systemCopyBuffer=PlayerCodec.Encode(player,catalog.Stages.Length);Toast("La sauvegarde JSON a été copiée dans le presse-papiers. Conserve-la dans un fichier personnel.");}
        void ImportSave(){
            var p=Modal("Importer une sauvegarde");GameUi.Paragraph("Colle un export PACO v1 à v4. Tu pourras vérifier le solde et la progression avant de remplacer la sauvegarde Unity.",p);
            var background=GameUi.Panel("JSON input",p,Color.white);GameUi.Height(background,400);var field=background.gameObject.AddComponent<InputField>();field.lineType=InputField.LineType.MultiLineNewline;var text=GameUi.Label("",background.transform,32);text.supportRichText=false;field.textComponent=text;field.characterLimit=131072;var placeholder=GameUi.Label("Coller le JSON ici",background.transform,32,GameUi.Muted);field.placeholder=placeholder;
            GameUi.Button("Vérifier",p,()=>{try{Player candidate=PlayerCodec.Decode(field.text,catalog.Stages.Length);var confirm=Modal("Remplacer la sauvegarde Unity ?");GameUi.Paragraph(candidate.cash+" FCFA-jeu · "+candidate.completed.Count+" puzzles gagnés · "+candidate.answered.Count+" notions comprises. Les soldes ne sont pas additionnés.",confirm);GameUi.Button("Confirmer le remplacement",confirm,()=>{if(Commit(old=>candidate))ShowCity();},GameUi.Red);GameUi.Button("Annuler",confirm,CloseModal,GameUi.Purple);}catch(Exception e){Toast(e.Message);}});
            GameUi.Button("Annuler",p,CloseModal,GameUi.Purple);
        }
        void Update(){if(Input.GetKeyDown(KeyCode.Escape)){if(page=="puzzle")LeaveRound();else if(modal!=null)CloseModal();else if(page!="city")ShowCity();}}
    }
}
