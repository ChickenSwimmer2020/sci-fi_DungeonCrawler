package backend.game.states;

import backend.extensions.ExtendedCamera;

class GameState extends FlxState {
    public static var inGame:Bool=false; //for disabling changing difficulty settings in-game.

    public static var generatedCameras:Bool=false;
    public static var securitySystemActivated:Bool=false;
    public static var timeLeftUntilSecuritySystemActive:Float=0;
    public static var pulledBreaker(default, set):Bool=false;

    public static function set_pulledBreaker(value:Bool):Bool {
        pulledBreaker = value;
        if(FlxG.sound.music.volume!=1) FlxG.sound.music.fadeIn(1.5, FlxG.sound.music.volume, 1);
        return pulledBreaker;
    }
    public static function beginCountdown() {
        FlxG.sound.music.volume=1;//??
        Music.playOnceMusic("ProtocalValidation", "", null, ()->{
            FlxG.sound.music.stop();
        });
    }
    public function new(LoadingFromSave:Bool=false) {
        super();
        if(!generatedCameras) generateCameras();

        if(LoadingFromSave!=true){


            Save.createNewFile("", null);
            MapGenerator.generateMap(100, 100, 0);
            add(MapGenerator.createMap('depth_0'));
            //showIntroCutscene();

            //TODO: non loading logic. (FOR NEW GAME SYSTEM)
            //Save.DEBUGSAVE('fucker'); //generate save BEFORE generating map. since maps are stored inthe save file they were being overridden. whoopsies!
            //Save.readSaveFile('fucker'); //load controls, we'll use this more in the future
            //MapGenerator.generateMap(100, 100);
            //add(MapGenerator.createMap('PLACEHOLDER'));
        }else{ //now properly loads the map at DEPTH that the player was at.
            var saveFile:SaveFile = Save.readSaveFile(Main.FILE); //just realized i can do this lol.
            var map:GameMap = Save.getMapFromSaveFile(Main.FILE, saveFile.maps[saveFile.meta.depth].name);
            add(map);

            Music.stopMusic();
            DynamicMusic.playDynamicMusic('SubLayers', "default", "piano");
        }
    }

    public static function generateCameras() {
        Main.camGame = new ExtendedCamera(0, 0, FlxG.width, FlxG.height, 1);
        Main.camGame.bgColor=0x00FFFFFF;
        Main.camGame.filters=[];
        Main.addCameraToGame(Main.camGame, "game");

        Main.camHUD = new ExtendedCamera(0, 0, FlxG.width, FlxG.height, 1);
        Main.camHUD.bgColor=0x00FFFFFF;
        Main.camHUD.filters=[];
        Main.addCameraToGame(Main.camHUD, "hud");

        Main.camOther = new ExtendedCamera(0, 0, FlxG.width, FlxG.height, 1);
        Main.camOther.bgColor=0x00FFFFFF;
        Main.camOther.filters=[];
        Main.addCameraToGame(Main.camOther, "other");
        generatedCameras=true;
    }
}