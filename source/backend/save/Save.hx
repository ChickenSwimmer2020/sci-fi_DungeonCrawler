package backend.save;

import backend.game.states.substates.HUDSubstate.Item;

typedef SaveFile = {
    var health:Int;
    var stamina:Int;
    var xp:Int;
    var position:{x:Float, y:Float};
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
    public static inline function findSaves()for(save in FileSystem.readDirectory(Paths.savePath))if(save.endsWith('.sav'))Main.saveFiles.push(save);
    public static inline function writeSaveFile(?save:Save, name:String) File.saveContent('${Paths.savePath}/$name.sav', Json.stringify(save));

    #if debug
        public static function DEBUGSAVE(name:String) {
            var toFile:SaveFile = {
                health: 420,
                xp: 421,
                stamina: 555,
                position: {x: 412, y: 32},
                inventory: [
                    [{type: RANGED,weaponType: GUN,gunType: BALLISTIC,item: "pistol",durability: 100.0,damage: [],charges: 100.0,}]
                ],
                maps: []
            };
            File.saveContent('${Paths.savePath}/${name.remove('.sav')}.sav', Json.stringify(toFile));
        }
    #end
}