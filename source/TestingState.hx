package;

class TestingState extends GameState {
    public function new(?LoadingFromSave:Bool=false) {
        super();
        #if (debug) Main.loadedTestedState=true; #end

        FlxG.watch.addQuick("main file", Main.FILE);

        #if (debug)
            if(LoadingFromSave!=true){
                Save.createNewFile("fucker", null, ()->{ //proably should migrate to this new function.
                    Save.readSaveFile('fucker'); //load controls, we'll use this more in the future
                    MapGenerator.generateMap(100, 100, 0);
                    add(MapGenerator.createMap('depth_0'));
                });
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