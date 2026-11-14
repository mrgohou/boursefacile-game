using System;
using System.Linq;
using Newtonsoft.Json;
namespace Paco.Domain {
    public sealed class Destination {public string name,country,topic,intro,reminder;public JourneyQuestion[] questions;}
    public sealed class JourneyQuestion {public string question,explanation;public string[] options;public int answer;}
    public sealed class JourneyFile {public Destination[] destinations;}
    public static class JourneyRules {
        public static bool Available(Player p,int city){return city>=0&&city<15&&(city==0||Enumerable.Range((city-1)*3,3).All(p.journeyAnswers.Contains));}
        public static Player Answer(Player p,int city,int question,int count){Player.Require(city>=0&&city<15&&question>=0&&question<3,"Destination inconnue.");int id=city*3+question;if(p.journeyAnswers.Contains(id))return p;Player.Require(Available(p,city),"Termine la destination précédente.");Player next=p.Copy();next.cash=checked(next.cash+300);next.journeyAnswers.Add(id);next.history.Add("Voyage "+(city+1)+", notion "+(question+1)+" : +300 FCFA-jeu.");if(next.history.Count>50)next.history.RemoveAt(0);return next.Validate(count);}
    }
}
