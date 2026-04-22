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
            path: '${Paths.paths.get('music')}/CellCompilation-p${#if(sys)'.ogg'#else'.mp3'#end}',
            internalName: "CellCompilation",
            name: "Cell Compilation",
            artist: "ChickenSwimmer2020",
            sections: [
                "loop"=>Functions.MSCSToMS(0, 20, 75),
            ],
            versionInfo: {NewestVersion: "p", OldestVersion: "p", AvailableVersions: ["p"]},
            BPM: 185
        },
        "ProtocolValidation"=>{
            path: '${Paths.paths.get('music')}/ProtocolValidation-p${#if(sys)'.ogg'#else'.mp3'#end}',
            internalName: "ProtocolValidation",
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
        "SubLayers"=>{
            path: '${Paths.paths.get('music')}/SubLayers-p${#if(sys)'.ogg'#else'.mp3'#end}',
            internalName: "SubLayers",
            name: "SubLayers",
            artist: "ChickenSwimmer2020",
            sections: [
                "default"=>Functions.MSCSToMS(0,0,0),
                "piano"=>Functions.MSCSToMS(0,17,61),
                "plucks"=>Functions.MSCSToMS(0,35,22),
                "chords"=>Functions.MSCSToMS(0,52,84),
                "pianochords"=>Functions.MSCSToMS(1,10,45),
                "pluckschords"=>Functions.MSCSToMS(1,28,7),
                "fulldrop"=>Functions.MSCSToMS(1,45,68),
                "fall0"=>Functions.MSCSToMS(2,20,91),
                "fall1"=>Functions.MSCSToMS(2,56,14),
                "end"=>Functions.MSCSToMS(3,31,37) //just in-case
            ],
            versionInfo: {NewestVersion: "p", OldestVersion: "p", AvailableVersions: ["p"]},
            BPM: 109
        },
        "PowerCells"=>{
            path: '${Paths.paths.get('music')}/PowerCells-p${#if(sys)'.ogg'#else'.mp3'#end}',
            internalName: "PowerCells",
            name: "PowerCells",
            artist: "ChickenSwimmer2020",
            sections: [
                "start"=>Functions.MSCSToMS(0,0,0),
                "loop"=>Functions.MSCSToMS(0,9,60),
                "goodloop"=>Functions.MSCSToMS(0,28,80),
                "end"=>Functions.MSCSToMS(1,7,20)
            ],
            versionInfo: {NewestVersion: "p", OldestVersion: "p", AvailableVersions: ["p"]},
            BPM: 100
        }
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
        trace('returned path from ResolvePostfix: ${Paths.paths.get('music')}/$name-$truePostFix.${#if(sys)'ogg'#else'mp3'#end}');
        return '${Paths.paths.get('music')}/$name-$truePostFix.${#if(sys)'ogg'#else'mp3'#end}';
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
    static var startedChecker:Bool=false;
    /**
     * just for updating the invidual audio objects, since i cant automatically update them from FlxG, i call Event.ENTER_FRAME in Main to update these manually.
     * @param elapsed 
     */
    public static function manualUpdate(elapsed:Float) {
        if(!startedChecker) {
            Functions.wait(Flags.CONDUCTOR_BPM_CHECK_INTERVAL, (_)->{
                if(musicInfos.get(currentlyPlayingSong)!=null){
                    if(Conductor.BPM!=musicInfos.get(currentlyPlayingSong).BPM){
                        Conductor.BPM = musicInfos.get(currentlyPlayingSong).BPM; //only change if we need to. and default to zero if null.
                    }
                }
            }, 0);
            startedChecker=true;
        }
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
    private static var lastMusicVolume:Float=0.0;
    /**
     * play an audio file once, starting from startSection, and ending at endSection. also allows for an onFinish callback. (USES FlxG.sound.music!)
     * @param song name of song to play
     * @param name internal name of object in `activeMusicObjects`
     * @param startSection what section to start from
     * @param endSection what section to end at
     * @param onFinish what to do when song is finished.
     */
    public static function playOnceMusic(song:String, startSection:OneOfTwo<String,Float>, endSection:OneOfTwo<String,Float>=null, onFinish:Void->Void) {
        lastMusicVolume=FlxG.sound.music.volume;
        var songInfo:MusicInfo = musicInfos.get(song);
        if(songInfo==null) return;
        startedChecker=false;
        currentlyPlayingSong = songInfo.internalName; //automatically do this because i realized that i should do it.
        FlxG.sound.playMusic(resolvePostfix(songInfo.internalName), 1.0, true);
        FlxG.sound.music.onComplete = onFinish;
        FlxG.sound.music.loopTime = getLoopSection(songInfo.internalName, startSection);
        FlxG.sound.music.time = getLoopSection(songInfo.internalName, startSection);
        FlxG.sound.music.endTime = getLoopSection(songInfo.internalName, endSection??null);
        FlxG.sound.music.volume = lastMusicVolume; //so dynamic music doesnt bug in the pause menu.
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
        startedChecker=false;
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
    public static function deathFadeOut(?time:Float=1.1231) {
        overrideSpecialTileAudioVolume=true;
        stopLoops();
        FlxG.sound.music.fadeOut(time, 0, (_)->{
            stopMusic();
        });   
    }
    public static function deathFadeIn(?time:Float=1.1231) { //ONLY CALL THIS IF FlxG.sound.music IS PLAYING, OTHERWISE NULL ACCESS
        overrideSpecialTileAudioVolume=false;
        FlxG.sound.music.fadeIn(time, 0, 1);
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
        startedChecker=false;
        trace('current song $currentlyPlayingSong ${currentlyPlayingSong==songInfo.internalName?"is":"is not"} equL to song (no Path) "${songInfo.internalName}"');
        if(currentlyPlayingSong!=songInfo.internalName || section!="") { //only override if the current song isnt what we want, or the section is forced.
            currentlyPlayingSong = songInfo.internalName;
            FlxG.sound.playMusic(songInfo.path, 1.0, (loopSection!=""&&looping==true)); 
            FlxG.sound.music.loopTime = getLoopSection(songInfo.internalName, loopSection);
            if(endSection!=null) FlxG.sound.music.endTime = getLoopSection(songInfo.internalName, endSection);
            if(!playfull) FlxG.sound.music.time = getLoopSection(songInfo.internalName, section);
        }
    }
    /**
     * stop and destroy all looping objects in `activeMusicObjects`
     */
    public static function stopLoops(soft:Bool=true) {
        if(soft){
            for(name=>object in activeMusicObjects){
                if(object!=null){
                    object.volume=0;
                    object.pause();
                }else{
                    trace('audio Object "$name" tried to stop, but was null! (should be destroyed)');
                }
            }
        }else stopLoopsUnsafe();
    }
    public static inline function stopLoopsUnsafe() for(name=>object in activeMusicObjects) removeLooping(name);
    /**
     * stop all currently playing audio, and force play a new song if requested.
     */
    public static function flushAudio(?playNewSong:String, ?song:String, ?playfull:Bool, ?section:OneOfTwo<String, Float>, ?looping:Bool, ?loopSection:OneOfTwo<String, Float>, ?endSection:OneOfTwo<String, Float>=null) {
        stopMusic();
        stopLoops();
        currentlyPlayingSong="";
        if(playNewSong!=null) {
            playMusic(song, playfull, section, looping, loopSection, endSection);
        }
    }
    /**
     * alias for `DynamicMusic.removeDynamicMusic()` which technically does what we want already.
     */
    public static function stopMusic() {
        FlxG.sound.music.stop();
    }

    public static var overrideSpecialTileAudioVolume:Bool=false;
    public static var musicVolumePreFade:Float=0;
    public static var musicVolumesPreFade:Map<String,Float>=[];
    public static function doPauseFade() {
        overrideSpecialTileAudioVolume=true;
        if(FlxG.sound.music.playing) {
            musicVolumePreFade = FlxG.sound.music.volume;
            FlxG.sound.music.fadeOut(1.5, musicVolumePreFade.getPercentage(25));
        }
        for(key => object in Music.activeMusicObjects) {
            if(object.playing){
                musicVolumesPreFade.set(key, object.volume);
                object.fadeOut(1.5, object.volume.getPercentage(25));
            }
        }
    }
    public static function undoPauseFade() {
        if(FlxG.sound.music.playing) {
            FlxG.sound.music.fadeIn(1.5, FlxG.sound.music.volume, musicVolumePreFade);
            musicVolumePreFade=0.0; //reset.
        }
        for(key => object in Music.activeMusicObjects) {
            if(object.playing){
                object.fadeIn(1.5, object.volume, musicVolumesPreFade.get(key));
                musicVolumesPreFade.remove(key);
            }
        }
        overrideSpecialTileAudioVolume=false;
    }
}

class DynamicMusic {
    public static var onSectionEnd:Void->Void;
    public static var curDynamicSong:String="";
    private static function playRandomSection(song:String) {
        if(Music.musicInfos.get(curDynamicSong)!=null) {
            var info:MusicInfo = Music.musicInfos.get(curDynamicSong);
            var random:Int = FlxG.random.int(0, Lambda.count(info.sections));
            for(choice in [for(section=>time in info.sections) section]) {
                if(choice == [for(section=>time in info.sections) section][random]) {
                    trace(choice);
                    trace([for(section=>time in info.sections) section][random+1]);
                    Music.playOnceMusic(song, choice, [for(section=>time in info.sections) section][random+1], ()->{
                        if(onSectionEnd!=null) onSectionEnd();
                        playRandomSection(song);
                    });
                }
            }
        }
    }
    public static function playDynamicMusic(song:String, startSection:OneOfTwo<String, Float>, endSection:OneOfTwo<String, Float>) {
        Music.playOnceMusic(song, startSection, endSection, ()->{
            if(onSectionEnd!=null) onSectionEnd();
            playRandomSection(song);
        });
        Music.currentlyPlayingSong = curDynamicSong = song;
    }
}