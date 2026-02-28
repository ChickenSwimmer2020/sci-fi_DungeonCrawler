package backend.save;

import flixel.input.keyboard.FlxKey;
import backend.game.states.substates.HUDSubstate.Item;

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
    public static function writeFieldToSave(sve:String, field:SaveField, ?varible:String="", value:Dynamic):Bool {
        if(saveExists(sve)){
            var data:Dynamic=Json.parse(File.getContent('${Paths.savePath}/$sve.sav'));
            switch(field){
                case HEALTH: data.health=value;
                case STAMINA: data.stamina=value;
                case XP: data.xp=value;
                case POSITION: Reflect.setField(data.position, varible, value);
                case INVENTORY: if(data.inventory!=null) data.inventory.push(value);
                case MAPS:
                case OTHER: Reflect.setField(data,varible, value);
                default:
            }
            writeSaveFile(data, sve); //write the same data back. this should work?
            return readFieldFromSave(sve, field, varible)==value;
        }else Main.showError("SAVENOTCACHED", sve);
        return false;
    }
    public static function getInventory(sve:String):Array<Item> {
        if(saveExists(sve)){
            var data:Dynamic=Json.parse(File.getContent('${Paths.savePath}/$sve.sav'));
            return data.inventory;
        }else Main.showError("SAVENOTCACHED", sve);
        return null;
    }
    public static function readFieldFromSaveADV(sve:String, field:String, varible:String):Dynamic {
        if(saveExists(sve)) {
            var data:Dynamic=Json.parse(File.getContent('${Paths.savePath}/$sve.sav'));
            return Reflect.field(Reflect.field(data, field), varible);
        }else Main.showError('SAVENOTCACHED', sve);
        return null;
    }
    public static function readFieldFromSave(sve:String, field:SaveField, varible:String):Dynamic{
        if(saveExists(sve)){
            var data:Dynamic=Json.parse(File.getContent('${Paths.savePath}/$sve.sav'));
            switch(field){
                case HEALTH: return data.health;
                case STAMINA: return data.stamina;
                case XP: return data.xp;
                case POSITION: return Reflect.field(data.position, varible);
                case INVENTORY: if(data.inventory!=null) for(row in 0...data.inventory.length) for(itm in 0...data.inventory[row].length) if(data.inventory[row][itm].item==varible) return data.inventory[row][itm];
                case MAPS: return "feature not implemented";
                case OTHER:
                    return Reflect.field(data, varible);
                default:
            }
        }else Main.showError("SAVENOTCACHED", sve);
        return null;
    }
    public static inline function saveExists(s:String):Bool return (Main.saveFiles.contains(s)||Main.saveFiles.contains('$s.sav'));
    public static inline function findSaves(){
        Main.saveFiles=[]; //clear the array and start again
        for(save in FileSystem.readDirectory(Paths.savePath))if(save.endsWith('.sav'))Main.saveFiles.push(save);
    }
    public static inline function writeSaveFile(?save:Save, name:String) File.saveContent('${Paths.savePath}/$name.sav', Json.stringify(save));

    public static function generateSaveFile(save:Save, name:String) {
        File.saveContent('${Paths.savePath}/$name.sav', Json.stringify(save, null, "    "));
    }
    private static function loadControls(data:Dynamic):Map<String, Array<FlxKey>> {
        var control:Map<String, Array<FlxKey>>=[];
        if(Reflect.hasField(data, "controls")) {
            for(ctrl in 0...data.controls.length) {
                var arr:Array<FlxKey>=[];
                for(k in 0...data.controls[ctrl].keys.length) arr.push(data.controls[ctrl].keys[k]);
                control.set(data.controls[ctrl].c, arr);
            }
            Main.controls=control;
            return control;
        }else Main.showError("");
        return null;
    }
    public static function readSaveFile(file:String):SaveFile {
        if(saveExists(file)){
            var data:Dynamic = Json.parse(File.getContent('${Paths.savePath}/$file.sav'));
            loadControls(data);
            var sve:SaveFile = {
                health: data.health,
                stamina: data.stamina,
                xp: data.xp,
                position:{x: data.position.x, y: data.position.y},
                controls: data.controls,
                inventory: data.inventory,
                maps: data.maps,
            };
            return sve;
        }else Main.showError("SAVENOTCACHED", file);
        return null;
    }
    #if debug
        public static function DEBUGSAVE(name:String) {
            var toFile:SaveFile = {
                health: 420,
                xp: 421,
                stamina: 555,
                position: {x: 412, y: 32},
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
                inventory: [
                    [{type: RANGED,weaponType: GUN,gunType: BALLISTIC,item: "pistol",durability: 100.0,damage: [],charges: 100.0,}]
                ],
                maps: []
            };
            File.saveContent('${Paths.savePath}/${name.remove('.sav')}.sav', Json.stringify(toFile));
        }
    #end
}