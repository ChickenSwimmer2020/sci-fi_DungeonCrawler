package backend.generation;

enum abstract SpecialTileType(Int) from Int to Int {
    var NONE=-1; //JUST incase.
    var SPAWN=0;
    var HALLWAY=1;
    var WALKABLEAREA=2; //can be used for pathfinding, mainly used for setting things up to actually work and generate properly. hopefully.
}

typedef TilePointer = {
    type:String,
    collides:Bool,
    ?special:Bool,
    ?specialType:SpecialTileType
} 

typedef Room = {
    w:Int,
    h:Int,
    x:Int,
    y:Int,
    doors:Int,
    doorLocations:Array<FlxPoint>,
} 

typedef MapFile = {
    var name:String;
    var width:Int;
    var height:Int;
    var tiles:Array<Array<TilePointer>>;
}
/**
 * basic map generation implementation.
 */
class MapGenerator {
    public static final HALLWAY_MIN_LENGTH:Int = 8; // these are in tiles, not normal numbers.
    public static final HALLWAY_MAX_LENGTH:Int = 16;
    public static final HALLWAY_HEIGHT:Int=3;

    public static function generateTileAt(tile:TilePointer,x:Int,y:Int,map:Array<Array<TilePointer>>){
        //this just got a bit more interesting!
        if(tile?.special==true) {
            switch(tile.specialType){
                case HALLWAY:
                    GENERATE_hallway(map,x,y);
                default:
            }
        }else map[y][x]=tile;
    }
    public static function generateMap(width:Int, height:Int) {  
        var outputTiles:Array<Array<TilePointer>> = [];
        var toMapFile:MapFile = {
            name: "PLACEHOLDER",
            width: width,
            height: height,
            tiles: []
        };
        //TODO: rewrite generation system to be based off of extensions, kinda like what minecraft random structures do.
        for(h in 0...height) outputTiles[h]=[]; //just for assigning and making sure we dont access nulls in the arrays because im too lazy to initilize properly.
        outputTiles[Math.floor(outputTiles.length/2)][Math.floor(outputTiles[Math.floor(outputTiles.length/2)].length/2)]={collides: false,type: "",specialType:SPAWN,special: true};

        var generatedHallway:Bool=false;
        for(h in 0...height){
            for(w in 0...width) {
                //generateTileAt({type: "placeholder", collides: FlxG.random.bool(50), specialType: HALLWAY, special: true}, 0, 0, outputTiles);
                //generateTileAt(
                //    FlxG.random.bool(50)?{
                //        type: "placeholder",
                //        collides: FlxG.random.bool(50),
                //        special: !generatedHallway,
                //        specialType: !generatedHallway?HALLWAY:NONE
                //    }:null,
                //    w, h, outputTiles
                //);
                //generatedHallway=true;
            }
        }

        toMapFile.tiles = outputTiles;
        if(Main.saveFile.data.maps==null)Main.saveFile.data.maps=([]:Array<MapFile>); //this should never be null, but in-case it is.
        (Main.saveFile.data.maps:Array<MapFile>).push(toMapFile); //stupid fuckin, i dont even know if this works or not.
    }
    private static function GENERATE_hallway(tiles:Array<Array<TilePointer>>, startX:Int, startY:Int){
        var hallwayLength:Int = FlxG.random.int(HALLWAY_MIN_LENGTH, HALLWAY_MAX_LENGTH);
        var tile:TilePointer={
            type: "placeholder",
            collides: false,
            special: true,
            specialType: WALKABLEAREA
        };
        for(HEIGHT in 0...HALLWAY_HEIGHT) {
            for(WIDTH in 0...hallwayLength) {
                generateTileAt(
                    {
                        type: "placeholder",
                        collides: FlxG.random.bool(50),
                        special: true,
                        specialType: WALKABLEAREA
                    },
                    WIDTH, HEIGHT, tiles
                );
            }
        }
    }
    private static function GENERATE_room(tiles:Array<Array<TilePointer>>, x:Int, y:Int, width:Int, height:Int, doors:Int, doorLocations:Array<FlxPoint>) {
        
    };

    public static function createMap(file:String):GameMap {
        trace(Main.saveFile.data);
        var hasMap:Bool=false;
        for(map in 0...Main.saveFile.data.maps.length)if(Main.saveFile.data.maps[map].name==file)hasMap=true; //check if we have the target map in the save file.
        if(hasMap) {
            var internalMap:Null<MapFile>=null;
            for(possibleMap in 0...Main.saveFile.data.maps.length) {
                if(Main.saveFile.data.maps[possibleMap].name == file){
                    internalMap={
                        name: Main.saveFile.data.maps[possibleMap].name??"ERROR",
                        width: Main.saveFile.data.maps[possibleMap].width??0,
                        height: Main.saveFile.data.maps[possibleMap].height??0,
                        tiles: Main.saveFile.data.maps[possibleMap].tiles??([]:Array<Array<TilePointer>>)
                    }
                }
            }
            var returnMap:GameMap = new GameMap(internalMap);
            returnMap.generate();
            #if (debug&&!android) //because the debugger doesnt exist on android.
                new FlxTimer().start(1, (_)->{
                    Main.DEBUG_updateMapsInfo(internalMap.width, internalMap.height, internalMap.tiles);
                    _.destroy();
                });
            #end
            //if im correct, i should be able to override the world bounds to be better!
            FlxG.worldBounds.set(0, 0, 0+(16*internalMap.width), 0+(16*internalMap.height));
            return returnMap;
        }else{
            Main.showError("MISSINGMAP", file);
            return null;
        }
        return null;
    }

    public static inline function mapExists(name:String):Bool return Main.foundMaps.contains(name);
    public static inline function findMaps(){
        if(Main.saveFile.data.maps!=null) {
            for(i in 0...(Main.saveFile.data.maps:Array<MapFile>).length) {
                Main.foundMaps.push((Main.saveFile.data.maps:Array<MapFile>)[i].name);
            }
        }else{
            trace('no maps found in save file, this is okay.');
        }
    }
}