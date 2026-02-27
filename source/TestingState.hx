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
            trace('before: ${Save.readFieldFromSave('fucker', HEALTH, null)}');
            Save.writeFieldToSave('fucker', HEALTH, null, 100);
            trace('after: ${Save.readFieldFromSave('fucker', HEALTH, null)}');

            //trace('checked save file for health and got: ${Save.readFieldFromSave('fucker', HEALTH, null)}');
            //trace('checked save file for stamina and got: ${Save.readFieldFromSave('fucker', STAMINA, null)}');
            //trace('checked save file for xp and got: ${Save.readFieldFromSave('fucker', XP, null)}');
            //trace('checked save file for position (X) and got: ${Save.readFieldFromSave('fucker', POSITION, "x")}');
            //trace('checked save file for position (Y) and got: ${Save.readFieldFromSave('fucker', POSITION, "y")}');
            //trace('checked save file for inventory item (pistol) and got: ${Save.readFieldFromSave('fucker', INVENTORY, "pistol")}');
            //trace('attempted to read save file inventory and got: ${Save.getInventory('fucker')}');
        #else
            trace('not in a debug build. functionality disabled.\nNice try using the terminal to see console output!');
        #end
    }
}