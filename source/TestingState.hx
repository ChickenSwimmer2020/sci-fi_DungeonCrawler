package;

import flixel.FlxCamera;
import backend.game.Player;

class TestingState extends flixel.FlxState {
    public function new() {
        super();
        #if debug Main.loadedTestedState=true; #end
        Main.camGame = new FlxCamera(0, 0, FlxG.width, FlxG.height, 1);
        Main.camGame.bgColor=0x00FFFFFF;
        FlxG.cameras.add(Main.camGame, false);

        Main.camHUD = new FlxCamera(0, 0, FlxG.width, FlxG.height, 1);
        Main.camHUD.bgColor=0x00FFFFFF;
        FlxG.cameras.add(Main.camHUD, false);

        Main.camOther = new FlxCamera(0, 0, FlxG.width, FlxG.height, 1);
        Main.camOther.bgColor=0x00FFFFFF;
        FlxG.cameras.add(Main.camOther, false);

        #if debug
            MapGenerator.generateMap(100, 100);
            Save.DEBUGSAVE('fucker');
            add(MapGenerator.createMap('PLACEHOLDER'));
            Save.readSaveFile('fucker'); //load controls, we'll use this more in the future
        #else
            trace('not in a debug build. functionality disabled.\nHow\'d you even load this state??');
        #end
    }
}