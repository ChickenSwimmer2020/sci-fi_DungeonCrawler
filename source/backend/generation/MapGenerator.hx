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
        #if(debug&&(windows||hl)) Main.LOG('attempting to generate map with width $width and height $height'); #end
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
        #if(debug&&(windows||hl)) Main.LOG('placed spawn tile at ${Math.floor(outputTiles.length/2)}, ${Math.floor(outputTiles[Math.floor(outputTiles.length/2)].length/2)} tiles: ${outputTiles.length}, $outputTiles'); #end
        var generatedHallway:Bool=false;
        for(h in 0...height){
            for(w in 0...width) {
                //generateTileAt({type: "placeholder", collides: FlxG.random.bool(50), specialType: HALLWAY, special: true}, 0, 0, outputTiles);
                generateTileAt(
                    FlxG.random.bool(50)?{
                        type: "placeholder",
                        collides: FlxG.random.bool(50),
                        special: false,
                        specialType: NONE
                    }:null,
                    w, h, outputTiles
                );
                //generatedHallway=true;
            }
        }

        toMapFile.tiles = outputTiles;
        if((Main.saveFile.data.saves:Map<String,SaveFile>).get(Main.FILE).maps==null)(Main.saveFile.data.saves:Map<String,SaveFile>).get(Main.FILE).maps=([]:Array<MapFile>);
        (Main.saveFile.data.saves:Map<String,SaveFile>).get(Main.FILE).maps.push(toMapFile); //whoops, forgot to update this writing logic!
        Main.saveFile.flush(); //should probably do this im realizing. maybe i should add a setter or something to automatically do this for me.
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
        var hasMap:Bool=false;
        var save:SaveFile = (Main.saveFile.data.saves:Map<String, SaveFile>).get(Main.FILE);
        for(map in 0...save.maps.length)if(save.maps[map].name==file)hasMap=true; //check if we have the target map in the save file.
        if(hasMap) {
            var internalMap:Null<MapFile>=null;
            for(possibleMap in 0...save.maps.length) {
                if(save.maps[possibleMap].name == file){
                    internalMap={
                        name: save.maps[possibleMap].name??"ERROR",
                        width: save.maps[possibleMap].width??0,
                        height: save.maps[possibleMap].height??0,
                        tiles: save.maps[possibleMap].tiles??([]:Array<Array<TilePointer>>)
                    }
                }
            }
            var returnMap:GameMap = new GameMap(internalMap);
            returnMap.generate();
            
            #if (debug&&!html5) //maps window doesnt exist on html5.
                Functions.wait(1, (_)->{
                    Main.DEBUG_updateMapsInfo(internalMap.width, internalMap.height, internalMap.tiles);
                });
            #end
            //if im correct, i should be able to override the world bounds to be better!
            FlxG.worldBounds.set(0, 0, 0+(16*internalMap.width), 0+(16*internalMap.height));
            return returnMap;
        }else{
            //Save.genereateMapFile shows this error. we dont need to do it twice.
            //Main.showError("MAPNULL", file); //swapped to new error, same message though.
            var returnMap:GameMap = new GameMap(null);
            returnMap.generate();
            FlxG.worldBounds.set(0, 0, 0+(16*1), 0+(16*1));
            return returnMap;
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
            #if(debug&&(windows||hl)) Main.LOG('no maps found in save file, this is okay.'); #end
        }
    }
}