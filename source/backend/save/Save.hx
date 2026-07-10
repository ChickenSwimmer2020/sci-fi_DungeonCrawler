package backend.save;

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
        position:{x:Float, y:Float, curLevel:String},
    };
    var inventory:Array<OneOfTwo<String, Item>>; //Items are a typedef, we can save these here!
    var maps:Array<MapFile>;
}

class Save {
    public var data:Null<SaveFile>;
    public static var InstanceData:Null<SaveFile>;
    public static var instance:Save;
    public function new() {
        Main.Trace(INFO, 'save init!');
        Main.Trace(WARN, 'dont forget to call `readSaveFile` to prevent null access!!');
        instance = this;
        
        if(!FileSystem.exists('assets/saves')){
            FileSystem.createDirectory('assets/saves');
            Main.Trace(DEBUG, 'created `assets/saves` because it didnt exist\n(exists? : ${FileSystem.exists('assets/saves')})');
        }
        //data = SaveReader.getSaveFile(Flags.DEFAULT_SAVE);
    }

    public static inline function createNewFile(name:String, ?data:SaveFile, onComplete:Void->Void):Bool return SaveReader.createSave(name, data, onComplete);

    public function readSaveFile(name:String):Bool {
        data = SaveReader.getSaveFile(name);
        InstanceData = data;
        return data!=null;
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
                var newData = Bytes.ofString(buildIni(data));
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
                var newData = Bytes.ofString(Json.stringify(buildMapsJson(data)));
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
                var newData = Bytes.ofString(buildInvXml(data));
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

    /**
     * erase all the current data stored for the currently loaded save file, then load a default one or make a new one if this was the last save we had.
     * @return Bool
     */
    public function erase():Bool {
        return false;
    }

    public static function buildIni(dat:Dynamic):String {
        var buf = new StringBuf();
        buf.add('[ROOT]\n');
        buf.add('name="${dat?.meta?.name}"\n');
        buf.add('difficulty="${dat?.meta?.difficulty}"\n');
        buf.add('depth=${dat?.level?.depth}\n');
        buf.add('level=${dat?.level?.level}\n');
        buf.add('money=${dat?.level?.money}\n');
        buf.add('playTime=${dat?.meta?.playTime.H},${dat?.meta?.playTime.M},${dat?.meta?.playTime.S};\n');

        buf.add('\n[PLAYERSTATE]\n');
        buf.add('health=${dat?.playerState?.health}\n');
        buf.add('stamina=${dat?.playerState?.stamina}\n');
        buf.add('xp=${dat?.playerState?.xp}\n');
        buf.add('posX=${dat?.playerState?.position?.x}\n');
        buf.add('posY=${dat?.playerState?.position?.y}\n');
        buf.add('curLevel=${dat?.playerState?.position?.curLevel}\n'); //WHOOPS I FORGOT THIS TOTALLY OH MY GOD.
        return buf.toString();
    }

    public static function buildMapsJson(dat:Dynamic):Dynamic {
        var obj:Dynamic = {};
        if (dat == null) return obj;
        if (dat.maps == null) return obj;
        for(map in (dat.maps:Array<Dynamic>)) {
            Reflect.setProperty(obj, Reflect.getProperty(map, "name"), map); // just mark existence, same as how parseMaps reads it
        }
        return obj;
    }

    public static function buildInvXml(dat:Dynamic):String {
        var buf = new StringBuf();
        if (dat == null) return buf.toString();
        buf.add('<inventory slots="${(dat.inventory:Array<Dynamic>).length}">\n');
        for(i in 0...(dat.inventory:Array<Dynamic>).length) {
            var slot = (dat.inventory:Array<Dynamic>)[i];
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
        var mapsFile:Array<MapFile> = SaveReader.readMapsFile(Main.FILE);
        var mapFile:Null<MapFile> = null;
        if(mapsFile==null || mapsFile.length==0) {
            Main.Trace(ERROR, 'Tried to get map $map but it doesnt exist in ${Main.FILE}!');
            return null;
        }

        for(mf in mapsFile) { //mf is mapfile, not motherf*cker.
            if(mf.name==map) {
                Main.Trace(INFO, 'found $map in ${Main.FILE}\'s maps.json file, initilizing...');
                mapFile = mf;
                break;
            }else continue;
        }

        if(mapFile==null) return null;
        var map:GameMap = new GameMap(mapFile);
        map.generate(false); //generate the map without editor mode.
        //shoulnt ever reach here, but yeah X3
        return map;
    }

    //static stuff.
    public static function findSaves() {
        Main.saveFiles = []; //empty the array to prevent errors.
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
        return null;
    }

    // is there a better way to do this? most certainly.
    public static function isValid(save:String):Bool {
        Main.Trace(INFO, 'Checking validity of $save...');
        var saveData:SaveFile = SaveReader.getSaveFile(save);
        //inv and maps.
        for(thingy in saveData.inventory){
            if(thingy is String || thingy is Dynamic) continue;
            else{
                Main.Trace(ERROR, '$save is invalid! (inventory contains non String||Dynamic object(s)...)');
                return false;
            }
        }
        for(thingy in saveData.maps){
            if(thingy is Dynamic){
                if(mapValid(thingy)) continue;
                else{
                    Main.Trace(ERROR, '$save is invalid! (map "${thingy.name}" has invalid data...)');
                    return false;
                }
            }else{
                Main.Trace(ERROR, '$save is invalid! (maps contains non String object(s)...)');
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

    public static function mapValid(map:MapFile):Bool {
        var mapName:String = ((map.name is String)?map.name:"[INVALID MAP NAME DATA]");
        if(!(map.name is String)){
            Main.Trace(ERROR, '$mapName is invalid! (map name is not a String...)');
            return false;
        }
        if(!(map.size.w is Int) || !(map.size.h is Int)){
            Main.Trace(ERROR, '$mapName is invalid! (Player size data is invalid...)');
            return false;
        }
        if(!(map.spawn.x is Int) || !(map.spawn.y is Int)){
            Main.Trace(ERROR, '$mapName is invalid! (Player spawn location is invalid...)');
            return false;
        }
        if(!(map.tiles is Array)){
            Main.Trace(ERROR, '$mapName is invalid! (Map Tile Data has wrong format...)');
            return false;
        }
        if(!(map.objects is Array)){
            Main.Trace(ERROR, '$mapName is invalid! (Map Objects Data has wrong format...)');
            return false;
        }
        if(!(map.enemies is Array)){
            Main.Trace(ERROR, '$mapName is invalid! (Map Enemies Data has wrong format...)');
            return false;
        }
        if(!(map.npcs is Array)){
            Main.Trace(ERROR, '$mapName is invalid! (Map Npcs Data has wrong format...)');
            return false;
        }
        return true;
    }

    public static function deleteSave(save:String):Bool {
        if(FileSystem.exists(Paths.save(save))) {
            FileSystem.deleteFile(Paths.save(save));
            return !FileSystem.exists(Paths.save(save));
        }
        //meaning the deletion failed
        return false;
    }
    /**
     * check if a save file exists
     * @param save file to find
     * @return Bool if the save exists
     */
    public static inline function exists(save:String):Bool return FileSystem.exists(Paths.save(save));
}

class SaveReader { //okay, its a zip file. fine.
    /**
     * alright, heres how the system version of the save system works. its basically like this.
     * file.sf
     *     meta.ini
     *     maps.json
     *     inventory.xml
     */

    public static function createSave(name:String, ?dat:Null<SaveFile>, ?onComplete:Void->Void, ?forceOverwrite:Bool=true):Bool {//! forceOverwrite SHOULD DEFAULT TO FALSE, its only true while i test and get everything working. this message also shouldnt be seen ever, so hi!
        var path = Paths.save(name);
        if(!FileSystem.exists(path)) File.saveContent(path, "TEST STRING, this gets overwritten lol."); //make an empty file.
        else {
            //TODO: ask if you would like to overwrite the save file.
            //TODO: find way to make this NOT overflow the stack because thats a uhhhh, really bad thing.
            //if(forceOverwrite) return createSave(name, dat, onComplete, true); //exit the block, by just running internally and forcing :3 
            
        }

        // output to new save file.
        var newEntries = new List<Entry>();

        var time:Date = Date.now();

        //meta
        var iniData:Bytes = Bytes.ofString(Save.buildIni(dat));
        newEntries.add({
            fileName: "meta.ini",
            fileSize: iniData.length,
            fileTime: time,
            compressed: false,
            dataSize: iniData.length,
            data: iniData,
            crc32: haxe.crypto.Crc32.make(iniData),
            extraFields: null
        });

        //maps
        var mapsData:Bytes = Bytes.ofString(Json.stringify(Save.buildMapsJson(dat)));
        newEntries.add({
            fileName: "maps.json",
            fileSize: mapsData.length,
            fileTime: time,
            compressed: false,
            dataSize: mapsData.length,
            data: mapsData,
            crc32: haxe.crypto.Crc32.make(mapsData),
            extraFields: null
        });

        //inventory
        var invData:Bytes = Bytes.ofString(Save.buildInvXml(dat));
        newEntries.add({
            fileName: "inventory.xml",
            fileSize: invData.length,
            fileTime: time,
            compressed: false,
            dataSize: invData.length,
            data: invData,
            crc32: haxe.crypto.Crc32.make(invData),
            extraFields: null
        });

        var out = new haxe.io.BytesOutput();
        var writer = new haxe.zip.Writer(out);
        writer.write(newEntries);
        File.saveBytes(Paths.save(name), out.getBytes());

        if(FileSystem.exists(Paths.save(name))) {
            Save.instance.readSaveFile(name);
            if(onComplete!=null) onComplete();
            return true; //autoload the file so that it doesnt get like, overriden with other stuff i think.
        }

        return false;
    }

    private static function mapsDynamicParseToArrayOfMapsFile(da:Dynamic):Array<MapFile> {
        var out:Array<MapFile> = ([]:Array<MapFile>);
        for(m in Reflect.fields(da)) {
            var map:MapFile = Functions.dynamicToMapFile(Reflect.getProperty(da, m));
            out.push(map);
        }
        return out;
    }

    public static function readMapsFile(file:String):Array<MapFile> {
        if(FileSystem.exists(Paths.save(file))) {
            var r:Reader = new Reader(new BytesInput(File.getBytes(Paths.save(file))));
            var entries:List<Entry> = r.read();
            for(entry in entries) {
                if(entry.fileName == "maps.json") {
                    Main.Trace(INFO, 'Located maps.json in $file');
                    return mapsDynamicParseToArrayOfMapsFile(Json.parse(((entry.compressed)?Reader.unzip(entry):entry.data).toString()));
                }
            }
            return null;
        }else{
            Main.showError("SAVENOTCACHED", file, null, "");
            return null;
        }
        return null;
    }

    public static function getSaveFile(file:String):SaveFile {
        if(FileSystem.exists(Paths.save(file))) {
            if (File.getContent(Paths.save(file)) == "TEST STRING, this gets overwritten lol.") {
                Main.showError("CORRUPTSAVE", file, null, "");
                return null;
            }
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
                    }else if(data.startsWith('{')) { //meaning its the maps.json file
                        var mapsOut:Array<MapFile> = ([]:Array<MapFile>);
                        var dataOut:Array<Dynamic> = parseMaps(data);
                        for(entry in dataOut) mapsOut.push(Functions.dynamicToMapFile(entry));
                        out.maps = mapsOut;
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
        return null;
    }
    private static function parsePlayerstate(dat:String):{health:Float,stamina:Float,xp:Float,position:{x:Float, y:Float, curLevel:String}} {
        var o:{health:Float,stamina:Float,xp:Float,position:{x:Float, y:Float, curLevel:String}} =
        {health:0,stamina:0,xp:0,position:{x:0, y:0, curLevel:""}};

        var active:Bool=false;
        for(line in dat.split('\n')) {
            if(!active){
                if(!line.startsWith("[PLAYERSTATE]")) continue;
                else active=true;
            }else{
                if(line.startsWith('health')) {
                    o.health = line.split('=')[1].trim().toFloat();
                }else if(line.startsWith('stamina')) {
                    o.stamina = line.split('=')[1].trim().toFloat();
                }else if(line.startsWith('xp')) {
                    o.xp = line.split('=')[1].trim().toFloat();
                }else if(line.startsWith('curLevel')){
                    o.position.curLevel = line.split('=')[1].trim();
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
    private static function parseMaps(dat:String):Array<Dynamic> {
        var data:Dynamic = Json.parse(dat);
        var out:Array<String>=[];
        for(object in Reflect.fields(data)) {
            Main.Trace(DEBUG, 'found "$object" in map file for ${Main.FILE}. Pushed to array.');
            out.push(Reflect.getProperty(data, object));
        }
        return out;
    }
}