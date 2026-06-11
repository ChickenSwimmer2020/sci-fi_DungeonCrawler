package backend.save;

import backend.game.Player;
import haxe.io.Bytes;
import haxe.zip.Entry;
import haxe.io.BytesInput;
import haxe.zip.Reader;

typedef Prefs = {
    var autoPause:Bool;
    var musicPF:String;
    var flashingLights:Bool;
    var shaders:Bool;
    var controls:Array<{c:String, keys:Array<FlxKey>}>;
    var language:String;
    var precacheShaders:Bool;
}
typedef SaveFile = {
    var meta:{
        name:String,
        playTime:{H:Int,M:Int,S:Int},
        difficulty:String,
        depth:Int,
        level:Int,
        money:Int
    };
    var playerState:{
        health:Float,
        stamina:Float,
        xp:Float,
        position:{x:Float, y:Float, level:String},
    };
    var inventory:Array<OneOfTwo<String, Item>>; //Items are a typedef, we can save these here!
    var preferences:Prefs;
    var maps:Array<String>;
}

class Save {
    public var data:Null<SaveFile>;
    public static var InstanceData:Null<SaveFile>;
    public function new() {
        Main.Trace(INFO, 'save init!');
        Main.Trace(WARN, 'dont forget to call `readSaveFile` to prevent null access!!');
        
        #if(windows||hl)
            if(!FileSystem.exists('assets/saves')){
                FileSystem.createDirectory('assets/saves');
                Main.Trace(DEBUG, 'created `assets/saves` because it didnt exist\n(exists? : ${FileSystem.exists('assets/saves')})');
            }
        #else
            //we DO actually have to do this slightly differently since we dont have FileSystem on HTML5
        #end
        //data = SaveReader.getSaveFile(Flags.DEFAULT_SAVE);
    }

    public static inline function createNewFile(name:String, ?data:SaveFile, onComplete:Void->Void):Bool return SaveReader.createSave(name, data, onComplete);

    public function readSaveFile(name:String):Bool {
        data = SaveReader.getSaveFile(name);
        InstanceData = data;
        return data!=null;
    }

    public function initDefaults() {//ig just force them since we cant check if their null?
        data.preferences.flashingLights=true;
        data.preferences.shaders=true;
        data.preferences.autoPause=true;
        data.preferences.precacheShaders=false;
        data.preferences.controls=([
            {c:"moveUP", keys:["UP", "W"]},
            {c:"moveDOWN", keys:["DOWN", "S"]},
            {c:"moveRIGHT", keys:["RIGHT", "D"]},
            {c:"moveLEFT", keys:["LEFT", "A"]},
            {c:"zoomIN", keys:["PLUS", "NONE"]},
            {c:"zoomOUT", keys:["MINUS", "NONE"]},
            {c:"pause", keys:["ESCAPE", "BACKSPACE"]},
            {c:"inventory", keys:["I", "NONE"]},
            {c:"interact", keys:["E", "ENTER"]},
            {c:"sprint", keys:["SHIFT", "NONE"]}
        ]:Array<{c:String, keys:Array<FlxKey>}>); //default init.
        data.preferences.language="EN_US";
    }
    /**
     * save the data to the .sf
     * @return Bool
     */
    public function flush():Bool {
        var path = Paths.save(Main.FILE);
        if(!FileSystem.exists(path)){
            Main.Trace(ERROR, 'unable to flush to ${path} (FILE DOESNT EXIST)');
            return false;
        }

        // read existing zip entries
        var r = new Reader(new BytesInput(File.getBytes(path)));
        var entries:List<Entry> = r.read();

        // rebuild each entry with updated data
        var newEntries = new List<Entry>();
        for(entry in entries) {
            if(entry.fileName.endsWith('.ini')) {
                // rebuild the ini from current data
                var newData = Bytes.ofString(buildIni());
                newEntries.add({
                    fileName: entry.fileName,
                    fileSize: newData.length,
                    fileTime: entry.fileTime,
                    compressed: false,
                    dataSize: newData.length,
                    data: newData,
                    crc32: haxe.crypto.Crc32.make(newData),
                    extraFields: entry.extraFields
                });
            } else if(entry.fileName.endsWith('.json')) {
                var newData = Bytes.ofString(Json.stringify(buildMapsJson()));
                newEntries.add({
                    fileName: entry.fileName,
                    fileSize: newData.length,
                    fileTime: entry.fileTime,
                    compressed: false,
                    dataSize: newData.length,
                    data: newData,
                    crc32: haxe.crypto.Crc32.make(newData),
                    extraFields: entry.extraFields
                });
            } else if(entry.fileName.endsWith('.xml')) {
                var newData = Bytes.ofString(buildInvXml());
                newEntries.add({
                    fileName: entry.fileName,
                    fileSize: newData.length,
                    fileTime: entry.fileTime,
                    compressed: false,
                    dataSize: newData.length,
                    data: newData,
                    crc32: haxe.crypto.Crc32.make(newData),
                    extraFields: entry.extraFields
                });
            } else {
                newEntries.add(entry); // keep unknown files untouched
            }
        }

        // write the new zip back to disk
        var out = new haxe.io.BytesOutput();
        var writer = new haxe.zip.Writer(out);
        writer.write(newEntries);
        File.saveBytes(path, out.getBytes());
        Main.Trace(DEBUG, 'Succesfully saved to $path!');
        return true;
    }

    private function buildIni():String {
        var buf = new StringBuf();
        buf.add('[ROOT]\n');
        buf.add('name="${data.meta.name}"\n');
        buf.add('difficulty="${data.meta.difficulty}"\n');
        buf.add('depth=${data.meta.depth}\n');
        buf.add('level=${data.meta.level}\n');
        buf.add('money=${data.meta.money}\n');
        buf.add('playTime=${data.meta.playTime.H},${data.meta.playTime.M},${data.meta.playTime.S};\n');

        buf.add('\n[PLAYERSTATE]\n');
        buf.add('health=${data.playerState.health}\n');
        buf.add('stamina=${data.playerState.stamina}\n');
        buf.add('xp=${data.playerState.xp}\n');
        buf.add('posX=${data.playerState.position.x}\n');
        buf.add('posY=${data.playerState.position.y}\n');

        buf.add('\n[PREFERENCES]\n');
        buf.add('autoPause=${data.preferences.autoPause}\n');
        buf.add('musicPF=${data.preferences.musicPF}\n');
        buf.add('flashingLights=${data.preferences.flashingLights}\n');
        buf.add('shaders=${data.preferences.shaders}\n');
        buf.add('language=${data.preferences.language}\n');
        buf.add('precacheShaders=${data.preferences.precacheShaders}\n');
        

        // write controls key list then each control's keys
        var controlNames:Array<String> = [];
        for(name => keys in Main.controls) {
            controlNames.push(name); //get the name from the controls.
        }
        buf.add('controlsKEYS=${controlNames.toString()}\n');
        buf.add('\n[controls]\n');
        for(name => controls in Main.controls) {
            buf.add('$name=${controls.toString()}\n');
        }
        return buf.toString();
    }

    private function buildMapsJson():Dynamic {
        var obj = {};
        for(map in data.maps) {
            Reflect.setField(obj, Reflect.getProperty(map, "name"), true); // just mark existence, same as how parseMaps reads it
        }
        return obj;
    }

    private function buildInvXml():String {
        var buf = new StringBuf();
        buf.add('<inventory slots="${data.inventory.length}">\n');
        for(i in 0...data.inventory.length) {
            var slot = data.inventory[i];
            if(slot is String) continue; // covers "EMPTY" and any other string placeholders
            var item:Item = cast slot;
            buf.add('  <item name="${item.item}" x="${i % 10}" y="${Math.floor(i / 10)}" />\n');
        }
        buf.add('</inventory>');
        return buf.toString();
    }

    public function get(area:String, field:String):Dynamic {
        Main.Trace(DEBUG, 'attempting to get find $area in ${Main.FILE}\'s data...');
        if(Reflect.getProperty(data, area)!=null || area=="") { //if area is empty, just skip it.
            Main.Trace(DEBUG, 'found $area in data, checking for $field in $area');

            if(Reflect.getProperty(area==""?data:Reflect.getProperty(data, area), field)!=null) {
                Main.Trace(DEBUG, 'found $field in $area, returning.');
                return Reflect.getProperty(area==""?data:Reflect.getProperty(data, area), field);
            }else{
                Main.Trace(ERROR, 'couldnt find $field in $area');
                return null;
            }
        }else{
            Main.Trace(ERROR, 'couldnt find $area in data');
            return null;
        }
    }

    /**
     * set a field in the save file, returns true if it succeeded to save.
     * @param area 
     * @param field 
     * @param value 
     * @return Bool
     */
    public function set(area:String, field:String, value:Dynamic):Bool {
        Main.Trace(DEBUG, 'attempting to find $area in ${Main.FILE}\'s data...');
        if(Reflect.getProperty(data, area)!=null || area=="") { 
            Main.Trace(DEBUG, 'found $area in data! looking for $field...');
            if(Reflect.getProperty(area==""?data:Reflect.getProperty(data, area), field)!=null) {
                Main.Trace(DEBUG, 'found $field! (data.$area.$field)!');
                Reflect.setProperty(area==""?data:Reflect.getProperty(data, area), field, value);
                return flush(); //autoflush lol.
            }else{
                Main.Trace(ERROR, 'couldnt find $field in $area');
                return false;
            }
        }else{
            Main.Trace(ERROR, 'couldnt find $area in data');
            return false;
        }
    }

    public function getMap(map:String):GameMap {
        if(Main.saveFile.data.maps.indexOf(map)!=-1) {
            var mapsFile:Dynamic = SaveReader.readMapsFile(Main.FILE);
            for(m in Reflect.fields(mapsFile)) {
                if(m == map) {
                    Main.Trace(INFO, 'found $map in ${Main.FILE}\'s maps.json file');
                    return MapGenerator.createMap(null); //for now, just generate nothing.
                }
            }
        }else Main.Trace(ERROR, 'Tried to get map $map but it doesnt exist in ${Main.FILE}!');
        return null;
    }

    /**
     * returns wether the save was deleted successfully.
     * @return Bool
     */
    public function erase():Bool {
        return false;
    }
    //static stuff.
    public static function findSaves() {
        Main.saveFiles = []; //empty the array to prevent errors.
        #if(windows||hl)
            for(file in FileSystem.readDirectory('assets/saves')) {
                Main.Trace(DEBUG, 'found $file in assets/saves');
                if(file.endsWith('/') || file.indexOf('.')==-1){
                    Main.Trace(WARN, 'found a folder in assets/saves, ignoring...');
                    continue;
                }
                var f:String = file.split('.')[0]; //NO EXTENSION.
                Main.Trace(INFO, 'Found `assets/saves/$f (${file.split('.')[1]})`, checking validity...');
                if(exists(f) && isValid(f)){
                    Main.Trace(INFO, '$f has been pushed to `Main.saveFiles`!');
                    Main.saveFiles.push(f);
                }else Main.Trace(WARN, '$f has been found to be invalid, or not exist.');
            }
        #end
        return null;
    }

    // is there a better way to do this? most certainly.
    public static function isValid(save:String):Bool {
        Main.Trace(INFO, 'Checking validity of $save...');
        var saveData:SaveFile = SaveReader.getSaveFile(save);
        //inv and maps.
        for(thingy in saveData.inventory){
            if(thingy is String || thingy is Dynamic){
                Main.Trace(INFO, '$thingy in $save\'s inventory is Dynamic, or String.');
                continue;
            }
            else{
                Main.Trace(ERROR, '$save is invalid! (inventory contains non String||Dynamic object(s)...)');
                return false;
            }
        }
        for(thingy in saveData.maps){
            if(thingy is String){
                Main.Trace(INFO, '$thingy in $save\'s map is String');
                continue;
            }else{
                Main.Trace(ERROR, '$save is invalid! (maps contains non String object(s)...)');
                return false;
            }
        }

        //prefs
        if(!(saveData.preferences.autoPause is Bool)){
            Main.Trace(ERROR, '$save is invalid! (preferences.autoPause is not a Bool...)');
            return false;
        }
        if(!(saveData.preferences.musicPF is String)){
            Main.Trace(ERROR, '$save is invalid! (preferences.musicPF is not a String...)');
            return false;
        }
        if(!(saveData.preferences.flashingLights is Bool)){
            Main.Trace(ERROR, '$save is invalid! (preferences.flashingLights is not a Bool...)');
            return false;
        }
        if(!(saveData.preferences.shaders is Bool)){
            Main.Trace(ERROR, '$save is invalid! (preferences.shaders is not a Bool...)');
            return false;
        }
        if(!(saveData.preferences.language is String)){
            Main.Trace(ERROR, '$save is invalid! (preferences.language is not a String...)');
            return false;
        }
        if(!(saveData.preferences.precacheShaders is Bool)) {
            Main.Trace(ERROR, '$save is invalid! (preferences.precacheShaders is not a Bool...)');
            return false;
        }
        for(thingy in saveData.preferences.controls) {
            if((thingy.c is String) || (thingy.keys is Array)){
                Main.Trace(INFO, '$thingy is a valid controls object.');
                continue;
            }else{
                Main.Trace(ERROR, '$save is invalid! (controls array contains malformed data...)');
                return false;
            }
        }

        //meta
        if(!(saveData.meta.name is String)){
            Main.Trace(ERROR, '$save is invalid! (meta.name is not a String...)');
            return false;
        }
        if(!(saveData.meta.playTime.H is Int) ||
            (!(saveData.meta.playTime.M is Int) ||
        !(saveData.meta.playTime.S is Int))){
            Main.Trace(ERROR, '$save is invalid! (meta.playTime contains malformed data...)');
            return false;
        }
        if(!(saveData.meta.difficulty is String)){
            Main.Trace(ERROR, '$save is invalid! (meta.difficulty is not a String...)');
            return false;
        }
        if(!(saveData.meta.depth is Int)){
            Main.Trace(ERROR, '$save is invalid! (meta.depth is not a Int...)');
            return false;
        }
        if(!(saveData.meta.level is Int)){
            Main.Trace(ERROR, '$save is invalid! (meta.level is not a Int...)');
            return false;
        }
        if(!(saveData.meta.money is Int)){
            Main.Trace(ERROR, '$save is invalid! (meta.money is not a Int...)');
            return false;
        }

        //player state
        if(!(saveData.playerState.health is Float)){
            Main.Trace(ERROR, '$save is invalid! (playerState.health is not a Float...)');
            return false;
        }
        if(!(saveData.playerState.stamina is Float)){
            Main.Trace(ERROR, '$save is invalid! (playerState.stamina is not a Float...)');
            return false;
        }
        if(!(saveData.playerState.xp is Float)){
            Main.Trace(ERROR, '$save is invalid! (playerState.xp is not a Float...)');
            return false;
        }
        if(!(saveData.playerState.position.x is Float) || !(saveData.playerState.position.y is Float)){
            Main.Trace(ERROR, '$save is invalid! (playerState.position contains malformed data...)');
            return false;
        }

        Main.Trace(INFO, '$save is valid!');
        return true;
    }

    public static function deleteSave(save:String):Bool {
        return false;
    }
    /**
     * check if a save file exists
     * @param save file to find
     * @return Bool if the save exists
     */
    public static inline function exists(save:String):Bool{
        #if(windows||hl) return FileSystem.exists(Paths.save(save));
        #else return (InstanceData!=null); #end
    }
}

class SaveReader { //okay, its a zip file. fine.
    /**
     * alright, heres how the system version of the save system works. its basically like this.
     * file.sf
     *     meta.ini
     *     maps.json
     *     inventory.xml
     */

    public static function createSave(name:String, ?data:Null<SaveFile>, ?onComplete:Void->Void):Bool {
        return false;
    }

    public static function readMapsFile(file:String):Dynamic {
        #if(windows||hl)
            if(FileSystem.exists(Paths.save(file))) {
                var r:Reader = new Reader(new BytesInput(File.getBytes(Paths.save(file))));
                var entries:List<Entry> = r.read();
                for(entry in entries) {
                    if(entry.fileName == "maps.json") {
                        Main.Trace(INFO, 'Located maps.json in $file');
                        return Json.parse(((entry.compressed)?Reader.unzip(entry):entry.data).toString());
                    }
                }
                return null;
            }else{
                Main.showError("SAVENOTCACHED", file, null, "");
                return null;
            }
        #else

        #end
        return null;
    }

    public static function getSaveFile(file:String):SaveFile {
        #if(windows||hl)
            if(FileSystem.exists(Paths.save(file))) {
                Main.FILE = file; //should work?
                var out:SaveFile = Flags.DEFAULT_SAVEFILE;
                var r:Reader = new Reader(new BytesInput(File.getBytes(Paths.save(file))));
                var entries:List<Entry> = r.read();
                for(entry in entries) {
                    if(entry.fileName.endsWith(".txt") || (entry.fileName.endsWith(".json") || (entry.fileName.endsWith('.xml') || entry.fileName.endsWith('.ini')))) {
                        var data:String = ((entry.compressed)?Reader.unzip(entry):entry.data).toString(); //boom.

                        if(data.contains('[ROOT]')) { //meaning its an ini file.
                            out.meta = parseMeta(data);
                            out.playerState = parsePlayerstate(data);
                            out.preferences = parsePrefs(data);
                        }else if(data.startsWith('{')) { //meaning its the maps.json file
                            out.maps = parseMaps(data);
                        }else if(data.startsWith('<inventory')) {
                            Main.Trace(DEBUG, 'inventory XML, lets do this shite.');
                            out.inventory = parseInv(data);
                        }
                    }else Main.Trace(WARN, 'unexpected file in save! ${entry.fileName}');
                }
                return out;
            }else{
                Main.showError("SAVENOTCACHED", file, null, "");
                return null;
            }
        #else

        #end
        return null;
    }

    private static function parsePrefs(dat:String):Prefs {
        var p:Prefs = {
            autoPause: false,
            musicPF: "",
            flashingLights: false,
            shaders: false,
            controls: [], //Array<{c:String, keys:Array<FlxKey>}>,
            language: "",
            precacheShaders: false
        };
        var keys:Array<{c:String, keys:Array<FlxKey>}>=[];

        var controlsArrayIndex:Int=0;

        var lines:Array<String> = dat.split('\n');
        
        var keysBeingSearchedFor:Array<String>=[];
        for(line in lines) {
            if(line.contains('[controls]')) {
                Main.Trace(INFO, 'Found the pointer for controls keys at ${lines.indexOf(line)}');
                controlsArrayIndex = lines.indexOf(line);
            }

            if(line.startsWith('autoPause')) {
                p.autoPause= line.split('=')[1].trim().toBool();
            }else if(line.startsWith('musicPF')) {
                p.musicPF = line.split('=')[1].trim();
            }else if(line.startsWith('flashingLights')) {
                p.flashingLights = line.split('=')[1].trim().toBool();
            }else if(line.startsWith('shaders')) {
                p.shaders = line.split('=')[1].trim().toBool();
            }else if(line.startsWith('language')) {
                p.language = line.split('=')[1].trim();
            }else if(line.startsWith('controlsKEYS')) {
                //oh boy here we go.
                var sepArray:String = line.split('=')[1].trim();
                keysBeingSearchedFor = sepArray.remove('[').remove(']').remove('"').split(',');
                Main.Trace(INFO, 'Searching for keys: $keysBeingSearchedFor');
            }
        }
        for(i in 0...lines.length) {
            if(i<controlsArrayIndex) continue;
            else { //actually read the controls and stuff to populate the array
                var line:String = lines[i];
                for(k in keysBeingSearchedFor) {
                    if(line.startsWith(k)) {
                        Main.Trace(INFO, 'Found target controls array for "$k"');
                        if(line.indexOf('=')==-1) {
                            Main.Trace(ERROR, 'KEYS IN SAVE FILE ARE NULL, DEFAULTING TO DEFAULT KEYBINDS TO PREVENT CRASH');
                            for(title => ks in Flags.DEFAULT_CONTROLS) {
                                keys.push({c: title, keys: ks});
                            }
                        }else{
                            var key:Array<FlxKey>=[];
                            var strArray:String = line.split('=')[1].trim();
                            var keysStr:Array<String> = strArray.remove('[').remove(']').remove('"').split(',');
                            for(y in keysStr) {
                                key.push(FlxKey.fromString(y.trim()));
                            }
                            keys.push({c: k, keys: key});
                            Main.Trace(INFO, keys);
                        }
                    }else continue;
                    break;
                }
            }
        }
        return p;
    }
    private static function parsePlayerstate(dat:String):{health:Float,stamina:Float,xp:Float,position:{x:Float, y:Float, level:String}} {
        var o:{health:Float,stamina:Float,xp:Float,position:{x:Float, y:Float, level:String}} =
        {health:0,stamina:0,xp:0,position:{x:0, y:0, level:""}};

        var active:Bool=false;
        var posY:String = "";
        var posX:String = "";
        var lvl:String = "";
        for(line in dat.split('\n')) {
            if(!active){
                if(!line.startsWith("[PLAYERSTATE]")) continue;
                else active=true;
            }else{

                if(line.contains('[PREFERENCES]')) break; //stop at next section.
                if(line.startsWith('health')) {
                    o.health = line.split('=')[1].trim().toFloat();
                }else if(line.startsWith('stamina')) {
                    o.stamina = line.split('=')[1].trim().toFloat();
                }else if(line.startsWith('xp')) {
                    o.xp = line.split('=')[1].trim().toFloat();
                }else if(line.startsWith('level')){
                    o.position.level = line.split('=')[1].trim();
                }else if(line.startsWith('posX')) { //auto scans for posY
                    o.position.x = line.split('=')[1].trim().toFloat();
                }else if(line.startsWith('posY')) { //auto scans for posY
                    o.position.y = line.split('=')[1].trim().toFloat();
                }
            }
        }
        Main.Trace(INFO, 'Built playerState block with: "$o"');
        return o;
    }
    private static function parseMeta(dat:String):{name:String,playTime:{H:Int,M:Int,S:Int},difficulty:String,depth:Int,level:Int,money:Int} {
        var o:{name:String,playTime:{H:Int,M:Int,S:Int},difficulty:String,depth:Int,level:Int,money:Int}=
        {name: "",playTime:{H: 0,M: 0,S:0},difficulty:"",depth:0,level:0,money:0};
        for(line in dat.split('\n')) {
            if(line.contains('[PLAYERSTATE]')) break; //end at the next section.
            if(line.startsWith('name')) {
                o.name = line.split('=')[1].trim().remove('"');
            }else if(line.startsWith('difficulty')) {
                o.difficulty = line.split('=')[1].trim().remove('"');
            }else if(line.startsWith('depth')) {
                o.depth = line.split('=')[1].trim().toInt();
            }else if(line.startsWith('level')) {
                o.level = line.split('=')[1].trim().toInt();
            }else if(line.startsWith('money')) {
                o.money = line.split('=')[1].trim().toInt();
            }else if(line.startsWith('playTime')) {
                var time:Array<String>=[];
                var t:{H:Int,M:Int,S:Int} = {H: 0,M: 0,S:0};
                time = line.split('=')[1].trim().split(';')[0].trim().split(',');
                Main.Trace(DEBUG, 'calculated time array: ($time:Array<String>)');
                for(i in 0...time.length) {
                    switch(i) {
                        case 0,1,2: [t.H, t.M, t.S][i] = time[i].toInt();
                        default: Main.Trace(WARN, 'Time array value over three discarded from time array: ${time[i]}');
                    }
                }
                o.playTime = t;
            }
        }
        Main.Trace(DEBUG, 'Returned metadata "$o" from "${Main.FILE}"');
        return o;
    }

    private static function parseInv(dat:String):Array<OneOfTwo<String, Item>> {
        var xml:Xml = Xml.parse(dat);
        var total:Int = xml.firstElement().get('slots').toInt()??Player.INVENTORY_SLOTS; //default to the default inventory slots if we cant find the slots pointer.
        var out:Array<OneOfTwo<String, Item>>=[];
        for(i in 0...total)out[i]="EMPTY";

        for(node in xml.firstElement().elements()) {
            Main.Trace(INFO, 'found node ${node.nodeName} in inventory xml');

            switch(node.nodeName) {
                case "item":
                    var returnItem:Item = {
                        type: ITEM,
                        item: "null"
                    };
                    var itemName:String = node.get('name');
                    returnItem.item = itemName;
                    if(Paths.weaponExists(itemName)) {
                        returnItem = WeaponParser.buildWeaponItemPointer(WeaponParser.parse(Paths.weapon(itemName)));
                    }else{
                        var total:Int = (node.get('x').toInt()+(node.get('y').toInt()*10)).floor();
                        out[total] = returnItem;
                    }
                    
                    Main.Trace(DEBUG, 'ITEM: $node');
                default: Main.Trace(INFO, node);
            }
        }

        Main.Trace(DEBUG, 'got inventory: $out from "${Main.FILE}".');
        return out;
    }
    private static function parseMaps(dat:String):Array<String> {
        var data:Dynamic = Json.parse(dat);
        var out:Array<String>=[];
        for(object in Reflect.fields(data)) {
            Main.Trace(DEBUG, 'found "$object" in map file for ${Main.FILE}. Pushed to array.');
            out.push(object);
        }
        return out;
    }
}