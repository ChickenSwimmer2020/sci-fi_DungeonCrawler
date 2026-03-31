package backend.save;

import haxe.ds.StringMap;

typedef SaveFile = {
    var meta:{
        name:String,
        playtime:{H:Int,M:Int,s:Int},
        difficulty:String,
        depth:Int,
        level:Int
    };
    var health:Int;
    var stamina:Int;
    var xp:Int;
    var position:{x:Float, y:Float};
    var inventory:Array<Array<Item>>; //Items are a typedef, we can save these here!
    var maps:Array<MapFile>; //store every map in the user save file so that we dont have to do a bunch of extra stuff to regenerate them.
}
class Save {
    public static function writeFieldToSave(file:String, varible:String="", value:Dynamic):Bool {
        if(saveExists(file)){
            var sve:SaveFile = (Main.saveFile.data.saves:Map<String,SaveFile>).get(file);
            Reflect.setField(sve, varible, value);
            (Main.saveFile.data.saves:Map<String,SaveFile>).set(file, sve);
            writeSaveFile(); //make sure we flush to the file (save)
            return Reflect.field((Main.saveFile.data.saves:Map<String,SaveFile>).get(file), varible)==value;
        }else Main.showError("SAVENOTCACHED", file);
        return false;
    }
    public static inline function getInventory(file:String):OneOfTwo<Array<Item>, Array<Array<Item>>> return (Main.saveFile.data.saves:Map<String,SaveFile>).get(file).inventory;
    public static function readFieldFromSave(file:String, varible:String):Dynamic{
        if(saveExists(file)){
            if(varible.contains('.')){ //for advanced reading.
                return Reflect.field(Reflect.field((Main.saveFile.data.saves:Map<String,SaveFile>).get(file), varible.split('.')[0]), varible.split('.')[1]);
            }
            return Reflect.field((Main.saveFile.data.saves:Map<String,SaveFile>).get(file), varible);
        }else Main.showError("SAVENOTCACHED", file);
        return null;
    }
    public static inline function saveExists(s:String):Bool return Main.saveFiles.contains(s);
    public static inline function findSaves(){
        Main.saveFiles=[]; //clear and try again
        for(name => save in (Main.saveFile.data.saves:Map<String, SaveFile>)??([]:Map<String,SaveFile>)) {
            Main.saveFiles.push(name);
        }
    }

    public static function getMapFromSaveFile(file:String, map:String):GameMap {
        #if(debug&&(windows||hl)) Main.LOG('hello??'); #end
        if(saveExists(file)) {
            var save:SaveFile = (Main.saveFile.data.saves:Map<String, SaveFile>).get(file);
            if(save.maps==null || save.maps.length<=0){
                Main.showError("MAPNULL", map);
                return MapGenerator.createMap(null); //return an empty map AND show an error message
            }else{
                for(m in 0...save.maps.length){
                    #if(debug&&(windows||hl)) Main.LOG('checking map file: ${save.maps[m]}'); #end
                    if(map==save.maps[m].name) {
                        #if(debug&&(windows||hl)) Main.LOG('found targeted map, building...'); #end
                        return MapGenerator.createMap(map);
                    }else Main.showError("MAPNULL", map);
                }
            }
        }else Main.showError("SAVENOTCACHED", file);
        return null;
    }

    /**
     * alias for `generateSaveFile`
     * @return bool
     */
    public static inline function writeSaveFile():Bool return generateSaveFile();
    public static inline function generateSaveFile():Bool return Main.saveFile.flush(); //File.saveContent('${Paths.savePath}/$name.sav', Json.stringify(save, null, "    "));

    private static function loadControls():Map<String, Array<FlxKey>> {
        var control:Map<String, Array<FlxKey>> = [];
        if (Main.saveFile.data.controls == null) {
            trace('uh oh');
            return null;
        }
        
        for (ctrl in 0...Main.saveFile.data.controls.length) {
            var arr:Array<FlxKey> = [];
            var keys:Array<Dynamic> = Main.saveFile.data.controls[ctrl].keys;
            
            for (k in 0...keys.length) {
                var raw = keys[k];
                var key:FlxKey;
                
                // handle both int and string stored keys
                if (Std.isOfType(raw, Int)) {
                    key = cast(raw, Int); // already an int, just cast directly to FlxKey
                } else {
                    key = cast FlxKey.fromString(Std.string(raw));
                }
                
                arr.push(key);
            }
            
            control.set(Main.saveFile.data.controls[ctrl].c, arr);
        }
        return control;
    }

    public static function readSaveFile(file:String):SaveFile {
        #if(debug&&(windows||hl)) Main.LOG(Main.saveFile.data); #end
        Main.FILE=file;
        Main.saveFile.data.lastLoadedSave = file;
        Main.lastLoadedSaveName = file;
        Main.controls=loadControls();
        Main.saveFile.flush(); //upload the last loaded save file name to the save and actually save it, forgot to do that lol.
        return (Main.saveFile.data.saves:Map<String, SaveFile>).get(file);
    }
    #if (debug)
        public static function DEBUGSAVE(name:String) {
            var up:SaveFile = {
                meta:{
                    name: '$name',
                    playtime:{H: 0,M: 0,s: 0},
                    difficulty: "NONE",
                    depth: 0,
                    level: 0
                },
                health: 420,
                xp: 421,
                stamina: 555,
                position: {x:0, y:0},
                inventory: ([
                    [{type: RANGED,weaponType: GUN,gunType: BALLISTIC,item: "pistol",durability: 100.0,damage: [],charges: 100.0,}]
                ]:Array<Array<Item>>),
                maps: ([]:Array<MapFile>)
            };
            (Main.saveFile.data.saves:Map<String, SaveFile>).set(name, up); //why does this keep crashing on html5 specifically??
            generateSaveFile();
            #if(debug&&(windows||hl)) Main.LOG(Main.saveFile.data); #end
        }
    #end
}