package backend.game.states;

class GameState extends FlxState {
    public static var generatedCameras:Bool=false;
    public static var securitySystemActivated:Bool=false;
    public static var timeLeftUntilSecuritySystemActive:Int=0;
    public static var pulledBreaker(default, set):Bool=false;

    public static function set_pulledBreaker(value:Bool):Bool {
        pulledBreaker = value;
        if(FlxG.sound.music.volume!=1) FlxG.sound.music.fadeIn(1.5, FlxG.sound.music.volume, 1);
        return pulledBreaker;
    }
    public static function beginCountdown() {
        timeLeftUntilSecuritySystemActive = Flags.SECURITY_SECONDSTILLACTIVATION;
        Functions.wait(1, (_)->{
            timeLeftUntilSecuritySystemActive--;
            trace(timeLeftUntilSecuritySystemActive);
            switch(timeLeftUntilSecuritySystemActive) {
                case 60: Music.playLoopingMusic("ProtocalValidation", "looptense1min", "looptense30s");
                case 30: Music.playLoopingMusic("ProtocalValidation", "looptense30s", "looptense15s");
                case 15: Music.playLoopingMusic("ProtocalValidation", "looptense15s", "end");
                case 0: FlxG.sound.music.stop();
                    Music.playOnce("ProtocalValidation", "escapeEnd", "end", null, ()->{
                        Music.flushAudio();
                    });
            }
        }, Flags.SECURITY_SECONDSTILLACTIVATION);
    }
    public function new(LoadingFromSave:Bool=false) {
        super();
        if(!generatedCameras) generateCameras();

        if(LoadingFromSave!=true){
            //TODO: non loading logic. (FOR NEW GAME SYSTEM)
            //Save.DEBUGSAVE('fucker'); //generate save BEFORE generating map. since maps are stored inthe save file they were being overridden. whoopsies!
            //Save.readSaveFile('fucker'); //load controls, we'll use this more in the future
            //MapGenerator.generateMap(100, 100);
            //add(MapGenerator.createMap('PLACEHOLDER'));
        }else{ //now properly loads the map at DEPTH that the player was at.
            var saveFile:SaveFile = Save.readSaveFile(Main.FILE); //just realized i can do this lol.
            var map:GameMap = Save.getMapFromSaveFile(Main.FILE, saveFile.maps[saveFile.meta.depth].name);
            add(map);
        }
    }

    public static function generateCameras() {
        Main.camGame = new FlxCamera(0, 0, FlxG.width, FlxG.height, 1);
        Main.camGame.bgColor=0x00FFFFFF;
        FlxG.cameras.add(Main.camGame, false);

        Main.camHUD = new FlxCamera(0, 0, FlxG.width, FlxG.height, 1);
        Main.camHUD.bgColor=0x00FFFFFF;
        FlxG.cameras.add(Main.camHUD, false);

        Main.camOther = new FlxCamera(0, 0, FlxG.width, FlxG.height, 1);
        Main.camOther.bgColor=0x00FFFFFF;
        FlxG.cameras.add(Main.camOther, false);
        generatedCameras=true;
    }
}