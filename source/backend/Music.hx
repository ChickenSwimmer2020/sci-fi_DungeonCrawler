package backend;

class Music {
    //songName=>{NewestVersion, OldestVersion, AvailableVersions}
    public static final songInformation:Map<String,{NV:String,O:String,AV:Array<String>}> = [
        "CellCompilation"=>{NV:"p", O:"p", AV:["p"]},
    ];
    public static function playMusic(song:String) {
        var songToPlay:String="";
        var targetPostFix:String = Main.musicPostfix=="D"?songInformation.get(song).NV:Main.musicPostfix;
        var versions:Array<String> = songInformation.get(song).AV;
        #if (windows||hl)
            if(versions.indexOf(targetPostFix) != -1) {
                songToPlay = '${Paths.musicPath}/$song-$targetPostFix.ogg';
            }else {
                var fallbackIndex = versions.indexOf(targetPostFix);
                while(fallbackIndex >= 0) {
                    var fallbackPostFix = versions[fallbackIndex];
                    if(FileSystem.exists('${Paths.musicPath}/$song-$fallbackPostFix.ogg')) {
                        songToPlay = '${Paths.musicPath}/$song-$fallbackPostFix.ogg';
                        break;
                    }
                    fallbackIndex--;
                }
            }
            trace(songToPlay);
        #elseif (html5) //specific code for loading through EMBEDDED assets.
            if(versions.indexOf(targetPostFix) != -1) {
                songToPlay = '${Paths.musicPath}/$song-$targetPostFix.mp3';
            } else {
                var fallbackIndex = versions.length - 1;
                while(fallbackIndex >= 0) {
                    var fallbackPostFix = versions[fallbackIndex];
                    songToPlay = '${Paths.musicPath}/$song-$fallbackPostFix.mp3';
                    break;
                    fallbackIndex--;
                }
            }
            trace(songToPlay);
        #end
        FlxG.sound.playMusic(songToPlay);
    }
}