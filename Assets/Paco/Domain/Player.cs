using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Paco.Domain {
    [Serializable] public sealed class Player {
        public int version=4, cash=10000;
        public Dictionary<string,int> holdings=new Dictionary<string,int>{{"cacao",0},{"telecom",0},{"banque",0}};
        public Dictionary<string,int> prices=new Dictionary<string,int>{{"cacao",2000},{"telecom",2500},{"banque",1500}};
        public HashSet<int> completed=new HashSet<int>(), answered=new HashSet<int>(), journeyAnswers=new HashSet<int>();
        public HashSet<string> companyCards=new HashSet<string>(), ownedPlots=new HashSet<string>();
        public Dictionary<string,string> townBuildings=new Dictionary<string,string>();
        public bool marketDropped, dividendPaid;
        public List<string> history=new List<string>();
        [JsonIgnore] public int Gains {get{return completed.Count*1500+journeyAnswers.Count*300;}}
        public int Unlocked(int count){for(int i=0;i<count;i++)if(!answered.Contains(i))return i;return count;}
        public long TotalValue(){return cash+holdings.Sum(kv=>(long)kv.Value*prices[kv.Key]);}
        public Player Copy(){return JsonConvert.DeserializeObject<Player>(JsonConvert.SerializeObject(this));}
        public Player Validate(int count) {
            Require(cash>=0 && cash<=1000000000,"Solde invalide.");
            Require(holdings!=null && prices!=null && completed!=null && answered!=null && companyCards!=null && ownedPlots!=null && townBuildings!=null && journeyAnswers!=null && history!=null,"Sauvegarde incomplète.");
            Require(holdings.Count==3 && prices.Count==3,"Portefeuille invalide.");
            foreach(Company c in EconomyCatalog.Companies) {
                Require(holdings.ContainsKey(c.Id) && holdings[c.Id]>=0 && holdings[c.Id]<=1000000000,"Quantité invalide.");
                Require(prices.ContainsKey(c.Id) && prices[c.Id]==c.Price-(c.Id=="cacao"?(marketDropped?300:0)+(dividendPaid?100:0):0),"Cours invalide.");
                Require(holdings[c.Id]==0 || companyCards.Contains(c.Id),"Carte manquante.");
            }
            Require(completed.All(n=>n>=0&&n<count) && answered.IsSubsetOf(completed),"Progression invalide.");
            Require(completed.All(n=>n==0||answered.Contains(n-1)),"Progression non séquentielle.");
            Require(companyCards.All(id=>EconomyCatalog.Companies.Any(c=>c.Id==id)),"Carte inconnue.");
            Require(holdings.Values.All(n=>n==0)||answered.Contains(1),"Guichet verrouillé.");
            Require(!marketDropped||answered.Contains(2),"Marché verrouillé.");
            Require(!dividendPaid||(marketDropped&&answered.Contains(4)),"Dividende verrouillé.");
            Require(ownedPlots.All(id=>EconomyCatalog.Lands.Any(l=>l.Id==id)),"Terrain inconnu.");
            for(int i=0;i<EconomyCatalog.Lands.Length;i++) {
                Land l=EconomyCatalog.Lands[i];
                Require(!ownedPlots.Contains(l.Id)||(Gains>=l.Gains&&(i==0||ownedPlots.Contains(EconomyCatalog.Lands[i-1].Id))),"Terrain verrouillé.");
            }
            Require(townBuildings.All(kv=>ownedPlots.Contains(kv.Key)&&EconomyCatalog.Buildings.Any(b=>b.Id==kv.Value)),"Construction invalide.");
            Require(journeyAnswers.All(q=>q>=0&&q<45&&(q/3==0||Enumerable.Range((q/3-1)*3,3).All(journeyAnswers.Contains))),"Voyage invalide.");
            Require(history.Count<=50 && history.All(h=>h!=null&&h.Length<=500),"Carnet invalide.");
            return this;
        }
        public static void Require(bool condition,string message){if(!condition)throw new InvalidOperationException(message);}
        void Log(string message){history.Add(message);if(history.Count>50)history.RemoveAt(0);}
        public Player Win(int level,int count) {
            Require(level>=0&&level<count,"Étape inconnue.");if(completed.Contains(level))return this;
            Require(level==Unlocked(count),"Termine la notion précédente.");
            Player p=Copy();p.cash=checked(p.cash+1500);p.completed.Add(level);p.Log("Puzzle "+(level+1)+" : +1 500 FCFA-jeu.");return p.Validate(count);
        }
        public Player Learn(int level,int count){Require(completed.Contains(level),"Réussis d’abord le puzzle.");if(answered.Contains(level))return this;Player p=Copy();p.answered.Add(level);p.Log("Notion "+(level+1)+" comprise.");return p.Validate(count);}
        public Player Trade(string id,bool buy,int count) {
            Require(holdings.ContainsKey(id),"Entreprise inconnue.");Require(answered.Contains(1),"Termine les deux premières notions.");
            int amount=prices[id],fee=EconomyCatalog.Fee(amount);Require(buy?cash>=amount+fee:holdings[id]>0,buy?"Solde insuffisant, frais compris.":"Aucune part à vendre.");
            Player p=Copy();p.cash=checked(p.cash+(buy?-amount-fee:amount-fee));p.holdings[id]+=buy?1:-1;if(buy)p.companyCards.Add(id);p.Log((buy?"Achat ":"Vente ")+id+" · frais "+fee+" FCFA-jeu.");return p.Validate(count);
        }
        public Player BuyLand(string id,int count){int i=Array.FindIndex(EconomyCatalog.Lands,l=>l.Id==id);Require(i>=0,"Terrain inconnu.");Land l=EconomyCatalog.Lands[i];Require(!ownedPlots.Contains(id),"Terrain déjà acquis.");Require(i==0||ownedPlots.Contains(EconomyCatalog.Lands[i-1].Id),"Acquiers le quartier précédent.");Require(Gains>=l.Gains,"Gagne encore des récompenses.");Require(cash>=l.Price,"Solde insuffisant.");Player p=Copy();p.cash-=l.Price;p.ownedPlots.Add(id);p.Log("Terrain "+l.Name+" acquis.");return p.Validate(count);}
        public Player Build(string land,string type,int count){Building b=EconomyCatalog.Buildings.FirstOrDefault(x=>x.Id==type);Require(b!=null,"Bâtiment inconnu.");Require(ownedPlots.Contains(land)&&!townBuildings.ContainsKey(land),"Il faut un terrain acquis et libre.");Require(cash>=b.Cost,"Solde insuffisant.");Player p=Copy();p.cash-=b.Cost;p.townBuildings[land]=type;p.Log("Construction : "+b.Name+".");return p.Validate(count);}
        public Player Drop(int count){if(marketDropped)return this;Require(answered.Contains(2),"Termine la notion sur le risque.");Player p=Copy();p.marketDropped=true;p.prices["cacao"]-=300;p.Log("Scénario : cacao −300 FCFA-jeu par part.");return p.Validate(count);}
        public Player Dividend(int count){if(dividendPaid)return this;Require(marketDropped&&answered.Contains(4)&&holdings["cacao"]>0,"Observe la baisse, termine la cinquième notion et détiens une part de cacao.");Player p=Copy();p.cash=checked(p.cash+checked(p.holdings["cacao"]*100));p.prices["cacao"]-=100;p.dividendPaid=true;p.Log("Dividende : +100 de cash et −100 au cours, par part.");return p.Validate(count);}
    }
    public static class PlayerCodec {
        static readonly string[] Arrays={"completed","answered","companyCards","ownedPlots","journeyAnswers"};
        public static string Encode(Player p,int count){p.Validate(count);p.version=4;return JsonConvert.SerializeObject(p,Formatting.Indented);}
        public static Player Decode(string text,int count){
            Player.Require(text!=null&&text.Length<=131072,"Sauvegarde trop volumineuse.");JObject j=JObject.Parse(text);
            Player.Require(j["version"]!=null&&j["version"].Type==JTokenType.Integer,"Version invalide.");int version=(int)j["version"];Player.Require(version>=1&&version<=4,"Version inconnue.");
            foreach(string key in new[]{"cash","holdings","prices","completed","answered","marketDropped","dividendPaid","history"})Player.Require(j[key]!=null,"Sauvegarde incomplète.");
            Player.Require(j["cash"].Type==JTokenType.Integer&&j["marketDropped"].Type==JTokenType.Boolean&&j["dividendPaid"].Type==JTokenType.Boolean,"Types invalides.");
            foreach(string key in new[]{"holdings","prices"})Player.Require(j[key].Type==JTokenType.Object&&((JObject)j[key]).Properties().All(v=>v.Value.Type==JTokenType.Integer),"Portefeuille invalide.");
            if(version==1){var h=(JObject)j["holdings"];j["companyCards"]=new JArray(h.Properties().Where(v=>(int)v.Value>0).Select(v=>v.Name));}
            else Player.Require(j["companyCards"]!=null,"Cartes manquantes.");
            if(version<3){j["ownedPlots"]=new JArray();j["townBuildings"]=new JObject();j["journeyAnswers"]=new JArray();}
            Player.Require(j["townBuildings"] is JObject&&((JObject)j["townBuildings"]).Properties().All(v=>v.Value.Type==JTokenType.String),"Constructions invalides.");
            foreach(string key in Arrays){JArray a=j[key] as JArray;Player.Require(a!=null,"Liste manquante.");bool numbers=key=="completed"||key=="answered"||key=="journeyAnswers";Player.Require(a.Count<=45&&a.All(v=>v.Type==(numbers?JTokenType.Integer:JTokenType.String))&&a.Select(v=>v.ToString()).Distinct().Count()==a.Count,"Liste invalide.");}
            Player.Require(j["history"] is JArray&&j["history"].All(v=>v.Type==JTokenType.String),"Carnet invalide.");
            Player p=j.ToObject<Player>();p.version=4;p.Validate(count);if(version<4)Player.Require(p.completed.All(n=>n<6)&&p.answered.All(n=>n<6),"Étapes incompatibles avec l'ancien format.");return p;
        }
    }
}
