using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;

namespace Paco.Domain {
    [Serializable] public sealed class Stage {
        public string id, topic, question, explanation;
        public int index, chapter, target, moves, seconds, answer;
        public bool legacy;
        public string[] options;
    }
    public sealed class StageFile { public int version; public Stage[] stages; }
    public sealed class LessonFile { public Stage[] lessons; }
    public sealed class Catalog {
        public readonly Stage[] Stages;
        public readonly Stage[] Lessons;
        public Catalog(string stages, string lessons) {
            Stages = JsonConvert.DeserializeObject<StageFile>(stages).stages;
            Lessons = JsonConvert.DeserializeObject<LessonFile>(lessons).lessons;
            if (Stages == null || Stages.Length < 30 || Lessons == null || Stages.Length != Lessons.Length)
                throw new ArgumentException("Catalogue incomplet.");
            for(int i=0;i<Stages.Length;i++) {
                Stage s=Stages[i], q=Lessons[i];
                if(s.index!=i || s.id!="paco-"+(i+1).ToString("000") || s.moves<19 || s.moves>24 || s.seconds<60 || s.seconds>90 || s.target<=0 || s.target>s.moves*90)
                    throw new ArgumentException("Objectif invalide.");
                if(q.options==null || q.options.Length<2 || q.answer<0 || q.answer>=q.options.Length || string.IsNullOrWhiteSpace(q.question))
                    throw new ArgumentException("Quiz invalide.");
            }
        }
    }
    public sealed class Company {
        public readonly string Id, Name, Model;
        public readonly int Price;
        public Company(string id,string name,int price,string model){Id=id;Name=name;Price=price;Model=model;}
    }
    public sealed class Land {
        public readonly string Id,Name;
        public readonly int Price,Gains;
        public Land(string id,string name,int price,int gains){Id=id;Name=name;Price=price;Gains=gains;}
    }
    public sealed class Building {
        public readonly string Id,Name,Model;
        public readonly int Cost;
        public Building(string id,string name,int cost,string model){Id=id;Name=name;Cost=cost;Model=model;}
    }
    public static class EconomyCatalog {
        public static readonly Company[] Companies={
            new Company("cacao","Cacao des Lagunes",2000,"farm"),
            new Company("telecom","Télécom Horizon",2500,"telecom"),
            new Company("banque","Banque Baobab",1500,"bank")};
        public static readonly Land[] Lands={
            new Land("rive","Les Rives",1000,1500),new Land("verger","Le Verger",1500,3000),
            new Land("marche","Le Marché",2200,4500),new Land("atelier","Les Ateliers",3000,6000),
            new Land("lumiere","Les Lumières",4000,9000),new Land("jardin","Le Grand Jardin",5000,12000)};
        public static readonly Building[] Buildings={
            new Building("ferme","Ferme de cacao",500,"farm"),new Building("boutique","Boutique du quartier",650,"shop"),
            new Building("antenne","Centre télécom",800,"telecom"),new Building("banque","Agence du quartier",1000,"bank"),
            new Building("atelier","Atelier de production",1200,"factory"),new Building("energie","Maison de l’énergie",1500,"energy"),
            new Building("services","Centre de services",1800,"services")};
        public static int Fee(int amount){return Math.Max(25,(amount+99)/100);}
    }
}
