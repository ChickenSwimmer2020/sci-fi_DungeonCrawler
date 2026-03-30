package backend;

class Music {
    public static final songDefaultVersion:Map<String,String> = [
        "CellCompilation"=>"-p",
    ];
    public static function playMusic(song:String) {
        var songToPlay:String="";
        var postFix:String = Main.musicPostfix=="D"?songDefaultVersion.get(song):Main.musicPostfix;
        #if (windows||hl) //TODO: checks to see if newer version of song exists if the target doesnt exist.
            if(FileSystem.exists('${Paths.musicPath}/$song.${postFix}')) songToPlay='${Paths.musicPath}/$song.${postFix}.ogg';
        #elseif (html5) //specific code for loading through EMBEDDED assets.
            //TODO: this.
        #end
        FlxG.sound.playMusic(songToPlay);
    }
}