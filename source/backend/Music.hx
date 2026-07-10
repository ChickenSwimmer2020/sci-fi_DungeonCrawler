package backend;

import funkin.vis.dsp.SpectralAnalyzerR;

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
        ""=>{ //default fallback in-case of music stopping. or other bs, idk.
            path: 'none',
            internalName: "None",
            name: "",
            artist: "[NO MUSIC PLAYING]",
            sections: [],
            versionInfo: {NewestVersion: "", OldestVersion: "", AvailableVersions: [""]},
            BPM: 0
        },
        "CellCompilation"=>{ //(Main Menu Theme)
            path: 'assets/audio/music/CellCompilation-p.ogg',
            internalName: "CellCompilation",
            name: "Cell Compilation",
            artist: "ChickenSwimmer2020",
            sections: [
                "loop"=>Functions.MSCSToMS(0, 20, 75),
            ],
            versionInfo: {NewestVersion: "p", OldestVersion: "p", AvailableVersions: ["p"]},
            BPM: 185
        },
        "ProtocolValidation"=>{ //(Security Theme)
            path: 'assets/audio/music/ProtocolValidation-p.ogg',
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
        "SubLayers"=>{ //(Idle Theme)
            path: 'assets/audio/music/SubLayers-p.ogg',
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
        "PowerCells"=>{ //(Exposition Theme)
            path: 'assets/audio/music/PowerCells-p.ogg',
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
        },
        "LithiumDegredation"=>{ //(Death Theme)
            path: 'assets/audio/music/LithiumDegredation-p.ogg',
            internalName: "LithiumDegredation",
            name: "Lithium Degredation",
            artist: "ChickenSwimmer2020",
            sections: [],
            versionInfo: {NewestVersion: "p", OldestVersion: "p", AvailableVersions: ["p"]},
            BPM: 100
        },
        "Miscalculation"=>{ //(Death Theme (Relocation Failed Death EasterEgg))
            path: 'assets/audio/music/Miscalculation-p${'.ogg'}',
            internalName: "Miscalculation",
            name: "Miscalculation",
            artist: "ChickenSwimmer2020",
            sections: [],
            versionInfo: {NewestVersion: "f", OldestVersion: "f", AvailableVersions: ["f"]},
            BPM: 90
        },
        //"colbaltenhancement"=>{ //(Low Health Theme (health under 50%))
        //},
        "HallOfHeros"=>{ //acvhiements gallery theme
            path: 'assets/audio/music/HallOfHeros-p.ogg',
            internalName: "HallOfHeros",
            name: "Hall of Heros",
            artist: "ChickenSwimmer2020",
            sections: [],
            versionInfo: {NewestVersion: "p", OldestVersion: "p", AvailableVersions: ["p"]},
            BPM: 90
        }
    ];
    public static var currentFFTFrame:Array<Float> = [];
    public static var normalizedCurrentFFTFrame:Array<Float> = [];
    public static var analyzer:SpectralAnalyzerR;
    public static var analyzerBars:Int = 50;
    public static var analyzerSound:FlxSound;

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
        Main.Trace(INFO, 'returned path from ResolvePostfix: ${Paths.getPath('audio/music', '$name-$truePostFix', 'ogg')}');
        return '${Paths.getPath('audio/music', '$name-$truePostFix', 'ogg')}';
    }

    public static function playSfx(name:String, looped:Bool=false, ?onComplete:Void->Void) {
        var sound:FlxSound = new FlxSound();
        sound.loadEmbedded(Paths.sfx(name), looped, true, ()->{
            activeSoundEffects.remove(name);
            if(onComplete!=null) onComplete();
        });
        activeSoundEffects.set(name, sound);
        sound.play();
    }


    /**
     * active playing music file of FlxG.sound.music.
     */
    public static var currentlyPlayingSong:String="";
    /**
     * active music objects that are not running based off of FlxG.sound.music.
     */
    public static var activeMusicObjects:Map<String,FlxSound>=[];
    public static var activeSoundEffects:Map<String, FlxSound>=[];
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
        }else if(activeSoundEffects.get(name)!=null){
            var object:FlxSound = activeSoundEffects.get(name);
            object.kill();
            object.destroy();
            object = null;
            activeSoundEffects.remove(name);
            return activeSoundEffects.get(name)==null;
        }return false;
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
        var sound:FlxSound = new FlxSound()
        .loadEmbedded(
            resolvePostfix(songInfo.internalName),
            true,
            false
        )
        .play(
            false,
            getLoopSection(songInfo.internalName, startSection),
            getLoopSection(songInfo.internalName, endSection)
        );
        activeMusicObjects.set(name, sound);
        reloadAnalyzer(sound);
    }
    static var startedChecker:Bool=false;
    static var checkingForMusicSection:Bool=false;
    static var MUSIC_targetFunctionSection:String="";
    static var MUSIC_targetFunctionSectionFunc:Void->Void;

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
                Main.Trace(ERROR, 'audio Object $name tried to update, but was null! (should be destroyed)');
            }
        }
        for(name => sfx in activeSoundEffects) {
            if(sfx!=null) {
                sfx.update(elapsed);
            }else{
                Main.Trace(ERROR, 'attempted to update SFX object $name but was null! (should be destroyed)');
            }
        }


        if(checkingForMusicSection) {
            if(FlxG.sound.music.time >= getLoopSection(currentlyPlayingSong, MUSIC_targetFunctionSection)){
                Main.Trace(INFO, 'reached section $MUSIC_targetFunctionSection in $currentlyPlayingSong');
                if(MUSIC_targetFunctionSectionFunc!=null) MUSIC_targetFunctionSectionFunc();
                checkingForMusicSection = false;
            }
        }

        if (analyzerSound != null && analyzerSound.playing && analyzer != null) {
            var bars = analyzer.getLevels();
			currentFFTFrame = [];
			for (bar in bars)
				currentFFTFrame.push(bar.value);

            normalizedCurrentFFTFrame = [];

            var frameMin = Math.POSITIVE_INFINITY;
            var frameMax = Math.NEGATIVE_INFINITY;

            for (v in currentFFTFrame) {
                frameMin = Math.min(frameMin, v);
                frameMax = Math.max(frameMax, v);
            }

            var range = frameMax - frameMin;
            if (range == 0) range = 1;

            var absMinDb = -100.0;
            var absMaxDb = 0.0;
            var absRange = absMaxDb - absMinDb;

            for (v in currentFFTFrame) {
                var frameNorm = (v - frameMin) / range;
                var absNorm = (v - absMinDb) / absRange;
                var finalNorm = frameNorm * absNorm;
                normalizedCurrentFFTFrame.push(finalNorm);
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
        var sound = new FlxSound()
        .loadEmbedded(resolvePostfix(songInfo.internalName), false, true, ()->{
            onFinish();
            activeMusicObjects.remove(name);
        }).play(
            false,
            getLoopSection(songInfo.internalName, startSection),
            getLoopSection(songInfo.internalName, endSection??null)
        );
        activeMusicObjects.set(name, sound);
        reloadAnalyzer(sound);
        Main.Trace(DEBUG, activeMusicObjects);
    }

    public static function onSectionReached() {} //TODO

    /**
     * Reloads the spectral analyzer. The sound must be playing for this to work.
     * @param smoothingTimeConstant 
     */
    public static function reloadAnalyzer(?sound:FlxSound, ?smoothingTimeConstant:Float = 0.1)
	{
        if (sound == null)
            sound = FlxG.sound.music;
        if (sound == null) return;
        if (!sound.playing) return;

		@:privateAccess
		var channel = sound._channel;
		var source = null;
		if (channel == null)
		{
			var oldVol = sound.volume;
			@:privateAccess
			source = sound._channel.__audioSource;
		}
		else
		{
			@:privateAccess
			source = channel.__audioSource;
		}
        analyzerSound = sound;
		analyzer = new SpectralAnalyzerR(source, analyzerBars, smoothingTimeConstant, 30);
        currentFFTFrame = [];
        normalizedCurrentFFTFrame = [];
	}

    public static function onSectionReachedMusic(s:OneOfTwo<String,Float>, f:Void->Void) {
        Main.Trace(INFO, 'added listener for section $s in $currentlyPlayingSong');
        MUSIC_targetFunctionSectionFunc = f;
        MUSIC_targetFunctionSection = s;
        checkingForMusicSection=true;
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
        var songInfo:MusicInfo = musicInfos.get(song);
        if(songInfo==null){
            Main.Trace(ERROR, 'null song info for $song');
            return;
        }
        startedChecker = false;
        currentlyPlayingSong = songInfo.internalName;
        lastMusicVolume = FlxG.sound.music != null ? FlxG.sound.music.volume : 1.0;
        FlxG.sound.music = null;

        var startTime = getLoopSection(songInfo.internalName, startSection);
        FlxG.sound.playMusic(resolvePostfix(songInfo.internalName), lastMusicVolume, false);
        var endTime = getLoopSection(songInfo.internalName, endSection??FlxG.sound.music.length);
        //if (FlxG.sound.music != null) FlxG.sound.music.pause();
        //FlxG.sound.music.play(false, startTime, endTime);
        FlxG.sound.music.time = FlxG.sound.music.loopTime = startTime;
        FlxG.sound.music.endTime = endTime;
        FlxG.sound.music.onComplete = onFinish;
        // To ovewrwrite the old music instance with this new one
        Conductor.targetAudioObject = FlxG.sound.music;
        reloadAnalyzer();
    }

    public static function makeSureThatSoundsArentLooping() {
        for(name=>audio in activeSoundEffects) {
            Main.Trace(INFO, '$name is ${audio.playing?'playing':'not playing'}');
            audio.stop();
        }
    }

    public static function resetPitch() {
        for(sfx in activeSoundEffects) if(sfx.pitch!=Flags.DEFAULT_PITCH) sfx.pitch = Flags.DEFAULT_PITCH;
        for(music in activeMusicObjects) if(music.pitch!=Flags.DEFAULT_PITCH) music.pitch = Flags.DEFAULT_PITCH;
        if(Conductor.pitch!=Flags.DEFAULT_PITCH) Conductor.pitch = Flags.DEFAULT_PITCH;
        if(FlxG.sound.music.pitch!=Flags.DEFAULT_PITCH) FlxG.sound.music.pitch = Flags.DEFAULT_PITCH;
    }

    /**
     * play looping music (uses FlxG.sound.music)
     * @param song song to play
     * @param startSection what section to start playing from
     * @param endSection what section to end at and loop back to `startSection`
     */
    public static function playLoopingMusic(song:String, ?startSection:OneOfTwo<String, Float>=null, ?endSection:OneOfTwo<String, Float>=null) {
        var songInfo:MusicInfo = musicInfos.get(song);
        if(songInfo==null) return;
        startedChecker=false;
        //if(currentlyPlayingSong!=songInfo.internalName) { //only change the song if the current playing music is not what we want.
            currentlyPlayingSong = songInfo.internalName;
            Conductor.BPM = songInfo.BPM;
            FlxG.sound.playMusic(resolvePostfix(songInfo.internalName), 1.0, true);
            FlxG.sound.music.looped=true; //apparently this doesnt get properly set after doDeathGlitch??
            FlxG.sound.music.loopTime = getLoopSection(songInfo.internalName, startSection??0);
            FlxG.sound.music.time = FlxG.sound.music.loopTime;
            FlxG.sound.music.endTime = getLoopSection(songInfo.internalName, endSection??FlxG.sound.music.length);

            Main.Trace(INFO, 'looping music "$song" should loop: ${FlxG.sound.music.looped}');
        //}
        reloadAnalyzer();
    }
    private static final GLITCH_TIME:Int = 30;
    private static final AUDIOPITCHVARIENCE:Float = FlxG.random.float(0.95, 1.15); //just for some varience on the death themes n shtuff.
    public static function doDeathGlitch() {
        Conductor.pitch = AUDIOPITCHVARIENCE; //jsut as a precaution
        FlxG.sound.music.pitch=AUDIOPITCHVARIENCE;
        for(sfx in activeSoundEffects) {
            Main.Trace(DEBUG, activeSoundEffects);
            //sfx.destroy(); //TODO: make this ACTUALLY fucking work instead of breaking everything by looping sound effects that shouldnt loop in the first fucking place. im going to fucking crash out so goddamn hard over this one stupid fucking line of code istg.
            sfx.pitch = AUDIOPITCHVARIENCE;
            sfx.loopTime = sfx.time;
            sfx.endTime = (sfx.loopTime+GLITCH_TIME);
            sfx.looped = true;
            sfx.onComplete=null;
        }
        for(looping in activeMusicObjects) {
            //if(looping.playing) {
                looping.pitch = AUDIOPITCHVARIENCE;
                looping.loopTime = looping.time;
                looping.endTime = (looping.time+GLITCH_TIME);
                looping.looped=true;
            //}
        }
        //if(FlxG.sound.music.playing){
            FlxG.sound.music.onComplete = null; //cancel the onComplete stuff. maybe this will fix it?
            FlxG.sound.music.loopTime = FlxG.sound.music.time;
            FlxG.sound.music.endTime = (FlxG.sound.music.time+GLITCH_TIME);
            FlxG.sound.music.looped=true;
        //}
    }   
    public static function deathFadeOut(time:Float=1.1231, stop:Bool=true) {
        overrideSpecialTileAudioVolume=true;
        stopLoops();
        FlxG.sound.music.fadeOut(time, 0, (_)->{
            if(stop) stopMusic();
        });   
    }
    public static function deathFadeIn(time:Float=1.1231) { //ONLY CALL THIS IF FlxG.sound.music IS PLAYING, OTHERWISE NULL ACCESS
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
        Main.Trace(INFO, 'current song $currentlyPlayingSong ${currentlyPlayingSong==songInfo.internalName?"is":"is not"} equL to song (no Path) "${songInfo.internalName}"');
        if(currentlyPlayingSong!=songInfo.internalName || section!="") { //only override if the current song isnt what we want, or the section is forced.
            currentlyPlayingSong = songInfo.internalName;
            FlxG.sound.playMusic(songInfo.path, 1.0, (loopSection!=""&&looping==true)); 
            FlxG.sound.music.loopTime = getLoopSection(songInfo.internalName, loopSection);
            if(endSection!=null) FlxG.sound.music.endTime = getLoopSection(songInfo.internalName, endSection);
            if(!playfull) FlxG.sound.music.time = getLoopSection(songInfo.internalName, section);
            reloadAnalyzer();
        }
    }
    /**
     * stop and destroy all looping objects in `activeMusicObjects`
     */
    public static function stopLoops(soft:Bool=true) {
        if(soft){
            Main.Trace(DEBUG, activeMusicObjects);
            for(name=>object in activeMusicObjects){
                if(object!=null){
                    if(object.playing){
                        object.volume=0;
                        object.pause();
                    }else{
                        Main.Trace(DEBUG, '$name == $object\nshouldnt be null');
                    }
                }else{
                    Main.Trace(ERROR, 'audio Object "$name" tried to stop, but was null! (should be destroyed)');
                }
            }
            for(name=>object in activeSoundEffects){
                if(object!=null){
                    if(object.playing){
                        if(object.looped) object.looped=false;
                        object.volume=0;
                        object.pause();
                    }else{
                        Main.Trace(DEBUG, '$name == $object\nshouldnt be null');
                    }
                }else{
                    Main.Trace(ERROR, 'audio Object "$name" tried to stop, but was null! (should be destroyed)');
                }
            }
        }else stopLoopsUnsafe();
    }
    public static inline function stopLoopsUnsafe(){
        for(name=>object in activeMusicObjects) removeLooping(name);
        for(name=>object in activeSoundEffects) removeLooping(name);
    }
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

class DynamicMusic { //tis a little fucky, but works again!
    public static var onSectionEnd:Void->Void;
    public static var curDynamicSong:String="";

    private static var lastSection:String="";
    private static function playRandomSection() {
        var info:MusicInfo = Music.musicInfos.get(curDynamicSong);
        if(info == null) return;

        // Build (key, time) pairs and sort chronologically by actual time value
        var sorted = [for(section=>time in info.sections) {key: section, time: time}];
        sorted.sort((a, b) -> a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));

        // "random" = what plays next (a purely random pick, independent of ordering)
        var randomIndex:Int = FlxG.random.int(0, sorted.length - 1);
        var choice = sorted[randomIndex].key;
        while(choice == lastSection && sorted.length > 1) { //re-iterate until we have a section that ISNT the last one we played.
            randomIndex = FlxG.random.int(0, sorted.length - 1);
            choice = sorted[randomIndex].key;
        }


        // "endTime" = chronologically-next timestamp after `choice`'s own position,
        // used ONLY to know when `choice`'s audio content ends — not what plays next.
        var choicePosInSorted = sorted.indexOf(sorted[randomIndex]);
        var endTime:Float = (choicePosInSorted + 1 < sorted.length)
            ? sorted[choicePosInSorted + 1].time
            : FlxG.sound.music.length; // last section: play to end of file

        Main.Trace(DEBUG, 'chose $choice in dynamic music $curDynamicSong, ends at $endTime');

        Music.playOnceMusic(curDynamicSong, choice, endTime, ()->{
            if(onSectionEnd!=null) onSectionEnd();
            playRandomSection();
        });
        lastSection = choice;
    }
    public static function playDynamicMusic(song:String, startSection:OneOfTwo<String, Float>, endSection:OneOfTwo<String, Float>) {
        Music.playOnceMusic(song, startSection, endSection, ()->{
            if(onSectionEnd!=null) onSectionEnd();
            trace('MUSIC: Playing Random Section.');
            playRandomSection();
        });
        Music.currentlyPlayingSong = curDynamicSong = song;
        trace('MUSIC: Playing Dynamic Music');
    }
}