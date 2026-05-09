package;

class TestingState extends GameState {
    public function new(?LoadingFromSave:Bool=false) {
        super();
        #if (debug) Main.loadedTestedState=true; #end

        FlxG.watch.addQuick("main file", Main.FILE);

        #if (debug)
            if(LoadingFromSave!=true){ //FINALLY changed this back.
                Save.createNewFile("fucker", null, ()->{ //proably should migrate to this new function.
                    #if(windows||hl)
                        Main.saveFile.readSaveFile('fucker');
                    #else
                        Save.readSaveFile('fucker'); //load controls, we'll use this more in the future
                    #end
                    MapGenerator.generateMap(100, 100, 0);
                    add(MapGenerator.createMap('depth_0'));
                });
            }else{
                #if(debug) Main.Trace(DEBUG, 'is this even working?'); #end
                var map:GameMap = #if(windows||hl)Main.saveFile.getMap("depth_0") #else Save.getMapFromSaveFile(Main.FILE, "depth_0")#end;
                add(map);
                #if(windows||hl)
                    Main.saveFile.readSaveFile(Main.FILE);
                #else
                    Save.readSaveFile(Main.FILE);
                #end
            }
        #else
            Main.Trace(INFO, 'not in a debug build. functionality disabled.\nHow\'d you even load this state??');
        #end
    }
}