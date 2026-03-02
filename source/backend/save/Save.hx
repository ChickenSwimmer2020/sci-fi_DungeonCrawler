package backend.save;

typedef SaveFile = {
    var health:Int;
    var stamina:Int;
    var xp:Int;
    var position:{x:Float, y:Float};
    var controls:Array<{c:String, keys:Array<FlxKey>}>;
    var inventory:Array<Array<Item>>; //Items are a typedef, we can save these here!
    var maps:Array<MapFile>; //store every map in the user save file so that we dont have to do a bunch of extra stuff to regenerate them.
}
enum abstract SaveField(String) from String to String{
    var HEALTH="HEALTH";
    var STAMINA="STAMINA";
    var XP="XP";
    var POSITION="POSITION";
    var INVENTORY="INVENTORY";
    var MAPS="MAPS";
    var OTHER="OTHER";
}
class Save {
    public static function writeFieldToSave(varible:String="", value:Dynamic):Bool {
        Reflect.setField(Main.saveFile.data, varible, value);
        return (Reflect.getProperty(Main.saveFile.data, varible)==value);
    }
    public static inline function getInventory():Array<Item> return Main.saveFile.data.inventory;
    public static inline function readFieldFromSaveADV(sve:String, field:String, varible:String):Dynamic {
        //TODO: this
        return null;
    }
    public static inline function readFieldFromSave(varible:String):Dynamic return Reflect.field(Main.saveFile.data, varible);
    //TODO: these functions for finding active saves.
    //public static inline function saveExists(s:String):Bool return (Main.saveFiles.contains(s)||Main.saveFiles.contains('$s.sav'));
    //public static inline function findSaves(){
    //    Main.saveFiles=[]; //clear the array and start again
    //    for(save in FileSystem.readDirectory(Paths.savePath))if(save.endsWith('.sav'))Main.saveFiles.push(save);
    //}

    /**
     * alias for `generateSaveFile`
     * @return bool
     */
    public static inline function writeSaveFile():Bool return generateSaveFile();
    public static inline function generateSaveFile():Bool return Main.saveFile.flush(); //File.saveContent('${Paths.savePath}/$name.sav', Json.stringify(save, null, "    "));

    private static function loadControls():Map<String, Array<FlxKey>> {
        var control:Map<String, Array<FlxKey>>=[];
        if(Reflect.hasField(Main.saveFile.data, "controls")) {
            for(ctrl in 0...Main.saveFile.data.controls.length) {
                var arr:Array<FlxKey>=[];
                for(k in 0...Main.saveFile.data.controls[ctrl].keys.length){
                    trace(Main.saveFile.data.controls[ctrl].keys[k]);
                    var keys:FlxKey = cast FlxKey.fromString(Main.saveFile.data.controls[ctrl].keys[k]);
                    arr.push(keys);
                }
                control.set(Main.saveFile.data.controls[ctrl].c, arr);
            }
            Main.controls=control;
            return control;
        }else if(Main.controls==[]) Main.showError(""); //TODO: error type for save file missing critical data and Main.controls somehow being empty.
        return null;
    }
    public static function readSaveFile(file:String):SaveFile {
        loadControls();
        return {
            health: Main.saveFile.data.health??0,
            stamina: Main.saveFile.data.stamina??0,
            xp: Main.saveFile.data.xp??0,
            position:{x: Main.saveFile.data.position.x??0, y: Main.saveFile.data.position.y??0},
            controls: Main.saveFile.data.controls??([]:Array<{c:String,keys:Array<FlxKey>}>),
            inventory: Main.saveFile.data.inventory??([]:Array<Array<Item>>),
            maps: Main.saveFile.data.maps??([]:Array<MapFile>),
        };
        return null;
    }
    #if (debug && !android)
        public static function DEBUGSAVE(name:String) {
            Main.saveFile.data.health = 420;
            Main.saveFile.data.xp = 421;
            Main.saveFile.data.stamina = 555;
            Main.saveFile.data.position = {x:412, y:32};
            Main.saveFile.data.controls=[
                {c: "moveUP", keys:["UP", "W"]},
                {c: "moveDOWN", keys:["DOWN", "S"]},
                {c: "moveRIGHT", keys:["RIGHT", "D"]},
                {c: "moveLEFT", keys:["LEFT", "A"]},
                {c: "zoomIN", keys:["PLUS"]},
                {c: "zoomOUT", keys:["MINUS"]},
                {c: "pause", keys:["ESCAPE", "BACKSPACE"]},
                {c: "inventory", keys:["I"]},
                {c: "interact", keys:["E", "ENTER"]}
            ];
            Main.saveFile.data.inventory=([
                [{type: RANGED,weaponType: GUN,gunType: BALLISTIC,item: "pistol",durability: 100.0,damage: [],charges: 100.0,}]
            ]:Array<Array<Item>>);
            Main.saveFile.data.maps=([]:Array<MapFile>);
            generateSaveFile();
        }
    #end
}