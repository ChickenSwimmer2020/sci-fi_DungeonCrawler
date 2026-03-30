package backend.save;

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
    var controls:Array<{c:String, keys:Array<FlxKey>}>; //TODO: store in MAIN save, not per save instance.
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
        trace('hello??');
        if(saveExists(file)) {
            trace('save exists.');
            trace((Main.saveFile.data.saves:Map<String,SaveFile>).get(file));
            for(m in 0...(Main.saveFile.data.saves:Map<String,SaveFile>).get(file).maps.length){
                trace('checking map file: ${(Main.saveFile.data.saves:Map<String,SaveFile>).get(file).maps[m]}');
                if(map==(Main.saveFile.data.saves:Map<String,SaveFile>).get(file).maps[m].name) {
                    trace('found targeted map, building...');
                    return MapGenerator.createMap(map);
                }else Main.showError("MAPNULL", map); //TODO: this error type.
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

    private static function loadControls(file:String):Map<String, Array<FlxKey>> {
        var InternalSave:SaveFile = (Main.saveFile.data.saves:Map<String, SaveFile>).get(file);
        var control:Map<String, Array<FlxKey>>=[];
        if(InternalSave==null) return null; //return nothing if the save is null.
        if(Reflect.hasField(InternalSave, "controls")) {
            for(ctrl in 0...InternalSave.controls.length) {
                var arr:Array<FlxKey>=[];
                for(k in 0...InternalSave.controls[ctrl].keys.length){
                    trace(InternalSave.controls[ctrl].keys[k]);
                    var keys:FlxKey = cast FlxKey.fromString(InternalSave.controls[ctrl].keys[k]);
                    arr.push(keys);
                }
                control.set(InternalSave.controls[ctrl].c, arr);
            }
            Main.controls=control;
            return control;
        }else if(Main.controls==[]) Main.showError(""); //TODO: error type for save file missing critical data and Main.controls somehow being empty.
        return null;
    }
    public static function readSaveFile(file:String):SaveFile {
        loadControls(file);
        Main.FILE=file;
        Main.saveFile.data.lastLoadedSave = file;
        Main.lastLoadedSaveName = file;
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
                controls: [
                    {c: "moveUP", keys:["UP", "W"]},
                    {c: "moveDOWN", keys:["DOWN", "S"]},
                    {c: "moveRIGHT", keys:["RIGHT", "D"]},
                    {c: "moveLEFT", keys:["LEFT", "A"]},
                    {c: "zoomIN", keys:["PLUS"]},
                    {c: "zoomOUT", keys:["MINUS"]},
                    {c: "pause", keys:["ESCAPE", "BACKSPACE"]},
                    {c: "inventory", keys:["I"]},
                    {c: "interact", keys:["E", "ENTER"]}
                ],
                inventory: ([
                    [{type: RANGED,weaponType: GUN,gunType: BALLISTIC,item: "pistol",durability: 100.0,damage: [],charges: 100.0,}]
                ]:Array<Array<Item>>),
                maps: ([]:Array<MapFile>)
            };
            (Main.saveFile.data.saves:Map<String, SaveFile>).set(name, up); //why does this keep crashing on html5 specifically??
            generateSaveFile();
            trace(Main.saveFile.data);
        }
    #end
}