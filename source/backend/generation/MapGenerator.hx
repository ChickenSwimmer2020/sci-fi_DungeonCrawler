package backend.generation;

enum abstract SpecialTileType(Int) from Int to Int {
    var NONE=-1; //JUST incase.
    var SPAWN=0;
    var HALLWAY=1;
    var WALKABLEAREA=2; //can be used for pathfinding, mainly used for setting things up to actually work and generate properly. hopefully.
    var BREAKER=3;
}
typedef TileData = {
    var set:String;
    @:optional var forcedIndex:Int;
    var pos:{row:Int, colum:Int};
    var collides:Bool;
    var isSpecial:Bool;
    @:optional var specialType:SpecialTileType;
}
typedef ObjectData = {
    var object:String;
    var size:{w:Int, h:Int}; //in tiles
    var pos:{x:Int, y:Int};
    var isAnimated:Bool;
    @:optional var animations:Array<{name:String, frames:Array<Int>, fps:Int, flipX:Bool, flipY:Bool}>;
}
typedef MapFile = {
    var name:String;
    var size:{w:Int, h:Int};
    var spawn:{x:Int, y:Int};
    var tiles:Array<TileData>;
    var objects:Array<ObjectData>;
    var enemies:Array<Dynamic>;
    var npcs:Array<Dynamic>;
}
/**
 * basic map generation implementation.
 */
class MapGenerator {
    public static final HALLWAY_MIN_LENGTH:Int = 8; // these are in tiles, not normal numbers.
    public static final HALLWAY_MAX_LENGTH:Int = 16;
    public static final HALLWAY_HEIGHT:Int=3;

    public static function generateMap(width:Int, height:Int, depth:Int, r:Bool=false):MapFile {
        #if(debug) Main.Trace(DEBUG, 'Attempting to generate a ${width}x$height map at depth $depth...'); #end
        var outputTiles:Array<TileData>=[];
        var toMapFile:MapFile = {
            name: 'depth_$depth',
            size: {
                w: width,
                h: height
            },
            spawn: {
                x: (width/2).floor(),
                y: (height/2).floor()
            },
            tiles: [],
            objects: [],
            enemies: [],
            npcs: []
        };

        for(index in 0...((width*height).floor())) { //width + height generally gives us
            outputTiles[index]=(FlxG.random.bool(50)?{
                set: 'placeholder',
                collides: FlxG.random.bool(50),
                isSpecial: false,
                pos: {
                    colum: (index%width).floor(),
                    row: ((index/width).floor())
                }
            }:null);
        }
        #if(debug) Main.Trace(DEBUG, 'placed spawn tile at center of map. tiles: ${outputTiles.length}'); #end
        //force override tile 0, 0 with the breaker for testing.
        toMapFile.tiles = outputTiles;
        if(!r){
            Main.Trace(DEBUG, '${Main.FILE}\'s maps array: ${(Main.saveFile.get("", "maps"):Array<MapFile>).length}');
            Main.saveFile.set("", "maps", (Main.saveFile.get("", "maps"):Array<MapFile>).combine([toMapFile])); //boom.
            Main.Trace(DEBUG, '${Main.FILE}\'s maps array: ${(Main.saveFile.get("", "maps"):Array<MapFile>).length} after adding map ${toMapFile.name}');
        }
        return toMapFile;
    }


    public static function createMap(file:String, ?mf:MapFile, ds:Bool=false):GameMap {
        var hasMap:Bool=(mf!=null)?true:false;
        var save:SaveFile;
        save = Main.saveFile.data;
        var index:Int = 0;
        if(mf==null){
            for(map in 0...save.maps.length){
                if(save.maps[map]==null || save.maps[map].name!=file){
                    if(map == save.maps.length-1) {
                        Main.Trace(ERROR, 'Map $file not found in save file ${Main.FILE}!');
                        hasMap = false; //sanity check.
                        return null;
                    }else continue;
                }
                if(save.maps[map].name==file){
                    hasMap=true; //check if we have the target map in the save file.
                    break; //STOP.
                }
                index++;
            }
        }

        var map:GameMap = new GameMap(hasMap?mf??save.maps[index]:null);
        map.generate(ds);
        return map;
    }

    public static inline function mapExists(name:String):Bool return Main.foundMaps.contains(name);
    public static inline function findMaps(){
        if(Main.saveFile.data==null) return; //dont even try if its null.
        if(Main.saveFile.data.maps!=null) {
            var allMaps:Array<MapFile> = SaveReader.readMapsFile(Main.FILE); //finally properly reads maps!
            if(allMaps==null||allMaps.length==0) {
                Main.Trace(ERROR, 'Unable to read the maps file of ${Main.FILE}, this is a bad thing!');
                return;
            }else{
                Main.foundMaps.clear();
                for(map in allMaps) {
                    if(map==null) { //TODO: add function for checking map validity, and if its invalid just dont use it at all. but of course throw errors.
                        Main.Trace(ERROR, 'Map $map is null in map file for ${Main.FILE}.');
                        continue;
                    }else Main.foundMaps.push(map.name);
                }
            }
        }else{
            Main.Trace(WARN, 'No maps found in save file "${Main.FILE}"');
        }
    }
}