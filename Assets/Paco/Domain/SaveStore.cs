using System;
using System.IO;
using System.Text;
namespace Paco.Domain {
    public sealed class SaveStore {
        readonly string path; readonly int count;
        public SaveStore(string path,int count){this.path=path;this.count=count;}
        public Player Load(){
            if(!File.Exists(path)&&!File.Exists(path+".bak"))return new Player();
            try {return PlayerCodec.Decode(File.ReadAllText(path),count);}
            catch(Exception e) when(e is IOException||e is InvalidOperationException||e is Newtonsoft.Json.JsonException){
                if(File.Exists(path+".bak"))return PlayerCodec.Decode(File.ReadAllText(path+".bak"),count);
                throw new IOException("La sauvegarde ne peut pas être lue. Conserve le fichier pour récupération.",e);
            }
        }
        public void Save(Player state){
            string text=PlayerCodec.Encode(state,count),temp=path+".tmp";
            Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(path)));
            byte[] bytes=Encoding.UTF8.GetBytes(text);
            using(var stream=new FileStream(temp,FileMode.Create,FileAccess.Write,FileShare.None)){stream.Write(bytes,0,bytes.Length);stream.Flush(true);}
            if(File.Exists(path))File.Replace(temp,path,path+".bak");else File.Move(temp,path);
        }
    }
    public sealed class RoundClock {
        readonly double seconds; double deadline; bool started;
        public RoundClock(int seconds){this.seconds=seconds;}
        public void Start(double now){if(started)return;started=true;deadline=now+seconds;}
        public int Remaining(double now){return started?Math.Max(0,(int)Math.Ceiling(deadline-now)):(int)seconds;}
    }
}
