package;

class TestingState extends flixel.FlxState {
    public function new(?LoadingFromSave:Bool=false) {
        super();
        #if (debug) Main.loadedTestedState=true; #end
        Main.camGame = new FlxCamera(0, 0, FlxG.width, FlxG.height, 1); //TODO: intiate in gamestate when that exists.
        Main.camGame.bgColor=0x00FFFFFF;
        FlxG.cameras.add(Main.camGame, false);

        Main.camHUD = new FlxCamera(0, 0, FlxG.width, FlxG.height, 1);
        Main.camHUD.bgColor=0x00FFFFFF;
        FlxG.cameras.add(Main.camHUD, false);

        Main.camOther = new FlxCamera(0, 0, FlxG.width, FlxG.height, 1);
        Main.camOther.bgColor=0x00FFFFFF;
        FlxG.cameras.add(Main.camOther, false);

        FlxG.watch.addQuick("main file", Main.FILE);

        #if (debug)
            if(LoadingFromSave!=true){
                Save.DEBUGSAVE('fucker'); //generate save BEFORE generating map. since maps are stored inthe save file they were being overridden. whoopsies!
                Save.readSaveFile('fucker'); //load controls, we'll use this more in the future
                MapGenerator.generateMap(100, 100);
                add(MapGenerator.createMap('PLACEHOLDER'));
            }else{
                 #if(debug&&(windows||hl)) Main.LOG('is this even working?'); #end
                var map:GameMap = Save.getMapFromSaveFile(Main.FILE, "PLACEHOLDER");
                add(map);
                Save.readSaveFile(Main.FILE);
            }
        #else
            trace('not in a debug build. functionality disabled.\nHow\'d you even load this state??');
        #end
    }
}