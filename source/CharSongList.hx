package;

class CharSongList
{
    public static var data:Map<String,Array<String>> = [ //ESSES NOMES SAO DA IMAGEM QUE VAI APARECE NO JOGO + NOME DA IMAGEM
      "girlfriend" => ["tutorial"],
      "daddy" => ["bopeebo", "fresh", "dad-battle"] //eses foi o exemplo
    ];

    public static var characters:Array<String> = [ //ESSES NOMES SAO DA IMAGEM QUE VAI APARECE NO JOGO + NOME DA IMAGEM
      "girlfriend",
      "daddy"
    ];

    public static var songToChar:Map<String,String>=[];

    public static function init(){
      songToChar.clear();
      for(character in data.keys()){
        var songs = data.get(character);
        for(song in songs)songToChar.set(song,character);
      }
    }

    public static function getSongsByChar(char:String)
    {
      if(data.exists(char))return data.get(char);
      return [];
    }

    public static function isLastSong(song:String)
    {
        /*for (i in songs)
        {
            if (i[i.length - 1] == song) return true;
        }
        return false;*/
      if(!songToChar.exists(song))return true;
      var songList = getSongsByChar(songToChar.get(song));
      return songList[songList.length-1]==song;
    }
}