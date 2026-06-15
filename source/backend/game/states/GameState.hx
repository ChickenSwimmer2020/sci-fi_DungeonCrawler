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
        Main.Trace(DEBUG, 'sooo is this working??');
        Music.playOnceMusic("ProtocolValidation", "mainloop", null, ()->{
            Main.Trace(DEBUG, 'makes me wonder. are you doing things when you shouldnt be?');
            Music.stopMusic();
            Music.stopLoops(true);
        });
    }
    public function new(LoadingFromSave:Bool=false, loadLastAvailableSave:Bool = true, saveName:String="") {
        super();
        if(!generatedCameras) generateCameras();

        if(LoadingFromSave!=true){
            Save.createNewFile("fucker", null, ()->{
                MapGenerator.generateMap(100, 100, 0);
                add(MapGenerator.createMap('depth_0'));
            });
            //showIntroCutscene();
        }else{ //now properly loads the map at DEPTH that the player was at.
            if(saveName == "") {
                Main.Trace(ERROR, 'SaveFile name input is empty!! something went wrong.');
                return;
            }else{
                //var saveFile:SaveFile = Save.readSaveFile(Main.FILE); //just realized i can do this lol.
                //var map:GameMap = Save.getMapFromSaveFile(Main.FILE, "depth_0"/*saveFile.maps[saveFile.meta.depth].name*/);
                //add(map);

                //TODO: loading from saves n sthif

                MapGenerator.generateMap(100, 100, 0);
                add(MapGenerator.createMap('depth_0')); //fuck it we ball !THIS IS FOR TESTING!
            }
        }
        Music.stopMusic();
        DynamicMusic.playDynamicMusic('SubLayers', "default", "piano");
    }

    public static function generateCameras() {
        if(Main.camGame!=null){
            Main.camGame.destroy();
            Main.camGame = null;
        }
        if(Main.camHUD!=null) {
            Main.camHUD.destroy();
            Main.camHUD = null;
        }
        if(Main.camOther!=null) {
            Main.camOther.destroy();
            Main.camOther = null;
        }   
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

    public static function degenerateCameras() {
        if(Main.camGame!=null){
            Main.camGame.destroy();
            Main.camGame = null;
        }
        if(Main.camHUD!=null) {
            Main.camHUD.destroy();
            Main.camHUD = null;
        }
        if(Main.camOther!=null) {
            Main.camOther.destroy();
            Main.camOther = null;
        }
        generatedCameras=false;
    }

    //reset all the static varibles n shit.
    public static function reset() {
        inGame=false;
        securitySystemActivated=false;
        timeLeftUntilSecuritySystemActive=0;
        @:bypassAccessor pulledBreaker=false;
    }
}