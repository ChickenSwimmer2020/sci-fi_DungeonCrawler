package;

class TestingState extends GameState {
    public function new(?LoadingFromSave:Bool=false) {
        super(false, false, "", true); //whoops, forgot testing state is based on GameState.
        Main.loadedTestedState=true;


        var map:GameMap = MapGenerator.createMap(null, MapGenerator.generateMap(10, 10, 0, true), false);
        add(map);
    }

    override public function destroy() {
        #if debug Main.loadedTestedState = false; #end

        super.destroy();
    }
}