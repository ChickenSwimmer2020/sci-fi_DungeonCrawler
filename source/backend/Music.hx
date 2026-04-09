package backend;

/**
 * music info, this typedef is for storing information about music tracks.
 */
typedef MusicInfo = {
    /**
     * path to song, no extension/postfix.
     */
    var path:String;
    /**
     * internal name, for sending to `currentlyPlayingSong` or other internal functions.
     */
    var internalName:String;
    /**
     * name, this is what shows on the SoundTray.
     */
    var name:String;
    /**
     * artist, this is what shows on the SoundTray.
     */
    var artist:String;
    /**
     * sections, this is for the looping system.
     */
    var sections:Map<String,Float>;
    /**
     * version info, this contains things like the newest, oldest, and available versions for playback.
     */
    var versionInfo:{NewestVersion:String, OldestVersion:String, AvailableVersions:Array<String>};
    /**
     * BeatsPerMinute, used for Conductor's beat calculations.
     */
    var BPM:Int;
} 
/**
 * Music, this controls game music audio. for SFX, see SFX.hx.
 * @since 0.03.2
 */
class Music {
    /**
     * music infos. provides data about songs without the need for like, 7 individual maps.
     * Heres a little reminder, dont include the song postfix within the path, as the game engine AUTOMATICALLY swaps it to what we want at runtime.
     */
    public static final musicInfos:Map<String, MusicInfo>=[
        "CellCompilation"=>{
            path: '${Paths.musicPath}/CellCompilation-p${#if(sys)'.ogg'#else'.mp3'#end}',
            internalName: "CellCompilation",
            name: "Cell Compilation",
            artist: "ChickenSwimmer2020",
            sections: [
                "loop"=>Functions.MSCSToMS(0, 20, 75),
            ],
            versionInfo: {NewestVersion: "p", OldestVersion: "p", AvailableVersions: ["p"]},
            BPM: 185
        },
        "ProtocalValidation"=>{
            path: '${Paths.musicPath}/ProtocalValidation-p${#if(sys)'.ogg'#else'.mp3'#end}',
            internalName: "ProtocalValidation",
            name: "Protocol Validation",
            artist: "ChickenSwimmer2020",
            sections: [
                "introloop"=>Functions.MSCSToMS(0,0,0),
                "hitcutscene"=>Functions.MSCSToMS(0,5,48),
                "mainloop"=>Functions.MSCSToMS(0,32,91),
                "looptense1min"=>Functions.MSCSToMS(1,38,74),
                "looptense30s"=>Functions.MSCSToMS(2,0,68),
                "looptense15s"=>Functions.MSCSToMS(2,22,62),
                "end"=>Functions.MSCSToMS(2,44,57)
            ],
            versionInfo: {NewestVersion: "p", OldestVersion: "p", AvailableVersions: ["p"]},
            BPM: 175
        },
    ];
    /**
     * if the correct path is input for a song, it will automatically replace the postfix with whatever the default/requested version is
     * with support for automatic fallback to newer versions should a requested version not support
     * @param path original path
     * @return String updated path with correct postfix.
     */
    private static function resolvePostfix(name:String):String {
        var songInfo:MusicInfo = musicInfos.get(name);
        if(songInfo==null) return "";
        var truePostFix:String="";

        if(Main.musicPostfix.toUpperCase()=="D") { //check if we're using the default (most recent) version of the audio
            truePostFix = songInfo.versionInfo.NewestVersion;
        }else{ //if we want a specific one.
            if(songInfo.versionInfo.AvailableVersions.indexOf(Main.musicPostfix)!=-1){
                truePostFix=Main.musicPostfix;
            }else{
                truePostFix = songInfo.versionInfo.AvailableVersions[0]; //the first one is always the newest.
            }
        }
        trace('returned path from ResolvePostfix: ${Paths.musicPath}/ProtocalValidation-$truePostFix.${#if(sys)'ogg'#else'mp3'#end}');
        return '${Paths.musicPath}/ProtocalValidation-$truePostFix.${#if(sys)'ogg'#else'mp3'#end}';
    }
    /**
     * active playing music file of FlxG.sound.music.
     */
    public static var currentlyPlayingSong:String="";
    /**
     * active music objects that are not running based off of FlxG.sound.music.
     */
    public static var activeMusicObjects:Map<String,FlxSound>=[];
    /**
     * removes a looping audio file found in `activeMusicObjects`
     * @param name what to remove
     * @return Bool if removed successfully.
     */
    public static function removeLooping(name:String):Bool {
        if(activeMusicObjects.get(name)!=null) {
            var object:FlxSound = activeMusicObjects.get(name);
            object.kill();
            object.destroy();
            object = null;
            activeMusicObjects.remove(name);
            return activeMusicObjects.get(name)==null;
        }else return false;
    }
    /**
     * Start a looping audio track from a song, name, and start/end sections.
     * @param SST Show on SoundTray
     * @param song name of song to play
     * @param name internal name of audio object
     * @param startSection what section to start playback from
     * @param endSection what section to end playback and loop back to start section at.
     */
    public static function playLooping(SST:Bool=false, song:String, name:String, startSection:OneOfTwo<String, Float>, endSection:OneOfTwo<String, Float>) {
        var songInfo:MusicInfo = musicInfos.get(song);
        if(songInfo==null) return;
        if(SST) currentlyPlayingSong=songInfo.internalName;
        activeMusicObjects.set(name,
            new FlxSound()
                .loadEmbedded(
                    resolvePostfix(songInfo.internalName),
                    true,
                    false
                )
                .play(
                    false,
                    getLoopSection(songInfo.internalName, startSection),
                    getLoopSection(songInfo.internalName, endSection)
                )
        );
    }
    /**
     * just for updating the invidual audio objects, since i cant automatically update them from FlxG, i call Event.ENTER_FRAME in Main to update these manually.
     * @param elapsed 
     */
    public static function manualUpdate(elapsed:Float) {
        for(name => audio in activeMusicObjects) {
            if(audio!=null){
                audio.update(elapsed);
                if(audio.looped && (audio.time == audio.endTime)){
                    audio.time = audio.loopTime;
                }
            }else{
                trace('audio Object $name tried to update, but was null! (should be destroyed)');
            }
        }
    }
    /**
     * play an audio file once, starting from startSection, and ending at endSection. also allows for an onFinish callback.
     * @param song name of song to play
     * @param name internal name of object in `activeMusicObjects`
     * @param startSection what section to start from
     * @param endSection what section to end at
     * @param onFinish what to do when song is finished.
     */
    public static function playOnce(song:String, name:String, startSection:OneOfTwo<String,Float>, endSection:OneOfTwo<String,Float>=null, onFinish:Void->Void) {
        var songInfo:MusicInfo = musicInfos.get(song);
        if(songInfo==null) return;

        currentlyPlayingSong = songInfo.internalName; //automatically do this because i realized that i should do it.
        activeMusicObjects.set(name, new FlxSound()
            .loadEmbedded(resolvePostfix(songInfo.internalName), false, true, ()->{
                onFinish();
                activeMusicObjects.remove(name);
            }).play(
                false,
                getLoopSection(songInfo.internalName, startSection),
                getLoopSection(songInfo.internalName, endSection??null)
            )
        );
        trace(activeMusicObjects);
    }
    /**
     * play looping music (uses FlxG.sound.music)
     * @param song song to play
     * @param startSection what section to start playing from
     * @param endSection what section to end at and loop back to `startSection`
     */
    public static function playLoopingMusic(song:String, startSection:OneOfTwo<String, Float>, endSection:OneOfTwo<String, Float>) {
        var songInfo:MusicInfo = musicInfos.get(song);
        if(songInfo==null) return;
        
        //TODO: better detection system for moving between looping parts and non-looping parts of the same song.
        //if(currentlyPlayingSong!=songInfo.internalName) { //only change the song if the current playing music is not what we want.
            currentlyPlayingSong = songInfo.internalName;
            Conductor.BPM = songInfo.BPM;
            FlxG.sound.playMusic(resolvePostfix(songInfo.internalName), 1.0, true);
            FlxG.sound.music.loopTime = getLoopSection(songInfo.internalName, startSection);
            FlxG.sound.music.time = getLoopSection(songInfo.internalName, startSection);
            FlxG.sound.music.endTime = getLoopSection(songInfo.internalName, endSection);
        //}
    }
    /**
     * get a loopback section from the main thing, just a helper function.
     * @param name song name
     * @param input time/section to get (can be float/string)
     * @return Float loopback time (in MS)
     */
    private static function getLoopSection(name:String, input:OneOfTwo<String, Float>):Null<Float> {
        if(input==null)return null;
        if(input is String)return musicInfos.get(name).sections.get(input);else if(input is Float) return input;
        return 0;
    }
    /**
     * Play music, simple. (uses FlxG.sound.music)
     * @param song what song to play
     * @param playfull play the full song? (OPTIONAL (true))
     * @param section what section to start from (if NOT playfull) (OPTIONAL (""))
     * @param looping should the song loop (OPTIONAL (true))
     * @param loopSection what section should the song loop back to (OPTIONAL (""))
     * @param endSection when should the song loop (OPTIONAL (""))
     */
    public static function playMusic(song:String, ?playfull:Bool=true, ?section:OneOfTwo<String, Float>="", ?looping:Bool=true, ?loopSection:OneOfTwo<String, Float>="", ?endSection:OneOfTwo<String, Float>=null) {
        var songInfo:MusicInfo = musicInfos.get(song);
        if(songInfo==null) return;
        trace('current song $currentlyPlayingSong ${currentlyPlayingSong==songInfo.internalName?"is":"is not"} equL to song (no Path) "${songInfo.internalName}"');
        if(currentlyPlayingSong!=songInfo.internalName || section!="") { //only override if the current song isnt what we want, or the section is forced.
            currentlyPlayingSong = songInfo.internalName;
            FlxG.sound.playMusic(songInfo.path, 1.0, (loopSection!=""&&looping==true));
            Conductor.BPM = songInfo.BPM;
            FlxG.sound.music.loopTime = getLoopSection(songInfo.internalName, loopSection);
            if(endSection!=null) FlxG.sound.music.endTime = getLoopSection(songInfo.internalName, endSection);
            if(!playfull) FlxG.sound.music.time = getLoopSection(songInfo.internalName, section);
        }
    }
    /**
     * stop all currently playing audio, and force play a new song if requested.
     */
    public static function flushAudio(?playNewSong:String, ?song:String, ?playfull:Bool, ?section:OneOfTwo<String, Float>, ?looping:Bool, ?loopSection:OneOfTwo<String, Float>, ?endSection:OneOfTwo<String, Float>=null) {
        FlxG.sound.music.stop();
        for(name=>object in activeMusicObjects) {
            removeLooping(name);
        }
        currentlyPlayingSong="";
        if(playNewSong!=null) {
            playMusic(song, playfull, section, looping, loopSection, endSection);
        }
    }
}