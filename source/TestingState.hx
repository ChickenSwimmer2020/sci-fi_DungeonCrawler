package;

class TestingState extends GameState {
    public function new(?LoadingFromSave:Bool=false) {
        super();
        #if (debug) Main.loadedTestedState=true; #end

        FlxG.watch.addQuick("main file", Main.FILE);

        #if (debug)
            if(LoadingFromSave!=true){ //FINALLY changed this back.
                Save.createNewFile("fucker", null, ()->{ //proably should migrate to this new function.
                    Main.saveFile.readSaveFile('fucker');
                    MapGenerator.generateMap(100, 100, 0);
                    add(MapGenerator.createMap('depth_0'));
                });
            }else{
                #if(debug) Main.Trace(DEBUG, 'is this even working?'); #end
                var map:GameMap = Main.saveFile.getMap("depth_0");
                add(map);
                Main.saveFile.readSaveFile(Main.FILE);
            }
        #else
            Main.Trace(INFO, 'not in a debug build. functionality disabled.\nHow\'d you even load this state??');
        #end
    }
}