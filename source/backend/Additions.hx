package backend;
final class Functions {
    /**
     * inverts the input color.
     * @param color input color
     * @return inverted color
     */
    public static inline function invertColor(color:Int):Int return (~color & 0x00FFFFFF) | (color & 0xFF000000);
    /**
     * wait a specific ammount of time, then run code.
     * @param time how long to wait
     * @param onComplete function to run after time is done
     * @param loops Int how many times to loop, defaults to 1 for one loop.
     */
    public static function wait(time:Float, onComplete:FlxTimer->Void, ?loops:Int=1) {
        return new FlxTimer().start(time, (_)->{
            onComplete(_);
            if(_.loopsLeft==0 && loops!=0) _.destroy();
        }, loops);
    }
    /**
     * justPressed but ignore NONE 
     * @param keys keys
     * @return Bool
     */
    public static function checkJustPressedSafe(keys:Array<FlxKey>):Bool {
        var h:Array<FlxKey>=[];
        for(key in keys){
            if(key == NONE) continue;
            else h.push(key);
        }
        return FlxG.keys.anyJustPressed(h);
    }
    /**
     * Pressed. but ignore NONE 
     * @param keys keys
     * @return Bool
     */
    public static function checkPressedSafe(keys:Array<FlxKey>):Bool {
        var h:Array<FlxKey>=[];
        trace(keys);
        for(key in keys){
            if(key == NONE) continue;
            else h.push(key);
        }
        return FlxG.keys.anyPressed(h);
    }
    /**
     * Pressed, but ignore NONE
     * @param keys keys
     * @return Bool
     */
    public static function checkJustReleasedSafe(keys:Array<FlxKey>):Bool {
        var h:Array<FlxKey>=[];
        for(key in keys){
            if(key == NONE) continue;
            else h.push(key);
        }
        return FlxG.keys.anyJustReleased(h);
    }
    /**
     * Returns a FlxKey from an int.
     * @param key target int number.
     * @return FlxKey
     */
    public static function FlxKeyFromInt(key:Int):FlxKey {
        for (field in FlxKey.fromStringMap.keys()) {
            if (field == "fromStringMap" || field == "toStringMap" || field == "fromString" || field == "toString") continue;
            var fKey:Int = cast Math.abs(cast FlxKey.fromStringMap.get(field));
            if (key == fKey)
                return FlxKey.fromString(field);
        }
        return FlxKey.NONE;
    }
    /**
     * get the Milliseconds value out of a FL Studio Time pointer (M:S:CS)
     * @param M Minutes
     * @param S Seconds
     * @param CS Centi-Seconds
     * @return Milliseconds.
     */
    public static inline function MSCSToMS(M:Int, S:Int, CS:Int):Float return (M*60*1000)+(S*1000)+(CS*10);
    /**
     * check if all the given keys are pressed at the same time
     * @param keys keys to check
     * @param inverse should we check if all the keys are pressed, or none of them are pressed.
     * @return Bool if all the keys are pressed
     */
    public static function allKeysPressed(keys:Array<FlxKey>, inverse:Bool=false):Bool {
        var curPressed:Array<Bool> = new Array<Bool>(); //we dont have to set this by default, so we'll use the normal start sys.
        for(key in keys) {
            if(curPressed.length<keys.length) curPressed.push(false);
            if(FlxG.keys.anyPressed([key])) curPressed[keys.indexOf(key)] = inverse?false:true;
            else curPressed[keys.indexOf(key)] = inverse?true:false;
        }
        for(item in curPressed) item==(inverse?false:true)?continue:return(inverse?true:false); //optimization!
        return inverse?false:true;
    }
    /**
     * check through an array of things, if any are true, return true, else return false.
     * @param toCheck things to check
     * @return Bool if any of them are true
     */
    public static function anyTrue(toCheck:Array<Bool>):Bool {
        for(thingy in toCheck) {
            if(thingy) return true;
            else return false;
        }
        return false;
    }

    /**
     * convert from savefile's controls array storage, to internal map controls storage.
     * @param i 
     * @return Map<String, Array<Int>>
     */
    public static function convertFromControlsArray(i:Array<{c:String,keys:Array<FlxKey>}>):Map<String, Array<Int>> {
        var out:Map<String, Array<Int>>=new Map<String, Array<Int>>();
        for(entry in i) out.set(entry.c, entry.keys);
        return out;
    }

    /**
     * convert a dynamic object into a map file.
     * @param d 
     * @return MapFile
     */
    public static function dynamicToMapFile(d:Dynamic):MapFile {
        var map:MapFile;

        function getTiles(d:Array<Dynamic>):Array<TileData> {
            var t:Array<TileData> = [];
            for(obj in 0...d.length) {
                var point:Dynamic = d[obj];
                t.push({
                    set: point?.set??"placeholder",
                    forcedIndex: point?.forcedIndex??-1,
                    pos: {
                        row: point?.pos?.row??0,
                        colum: point?.pos?.colum??0
                    },
                    collides: point?.collides??false,
                    isSpecial: point?.isSpecial??false,
                    specialType: point?.specialType??-1
                });
            }
            return t;
        }
        function getObjects(d:Dynamic):Array<ObjectData> {
            var o:Array<ObjectData> = [];

            function getAnims(d:Array<Dynamic>):Array<{name:String, frames:Array<Int>, fps:Int, flipX:Bool, flipY:Bool}> {
                var a:Array<{name:String, frames:Array<Int>, fps:Int, flipX:Bool, flipY:Bool}> = [];

                for(anim in 0...(d:Array<Dynamic>).length) {
                    var an:Dynamic = (d:Array<Dynamic>)[anim];
                    a.push({
                        name: an?.name??"ERROR",
                        frames: (an?.frames:Array<Int>)??[0],
                        fps: an?.fps??30,
                        flipX: an?.flipX??false,
                        flipY: an?.flipy??false
                    });
                }

                return a;
            }

            for(obj in 0...(d:Array<Dynamic>).length) {
                var point:Dynamic = (d:Array<Dynamic>)[obj];

                o.push({
                    object: point?.object??"FALLBACK",
                    size: {
                        w: point?.size?.w??1,
                        h: point?.size?.h??1
                    },
                    pos: {
                        x: point?.pos?.x??0,
                        y: point?.pos?.y??0
                    },
                    isAnimated: point?.isAnimated??false,
                    animations: getAnims((point?.animations:Array<Dynamic>)??[])
                });
            }

            return o;
        }

        map = {
            name: d?.name??"ERROR",
            size: {
                w: d?.size?.w??0,
                h: d?.size?.h??0
            },
            spawn: {
                x: d?.spawn?.x??0,
                y: d?.spawn?.y??0
            },
            tiles: getTiles(d?.tiles??[]),
            objects: getObjects(d?.objects??[]),
            enemies: [], //TBA
            npcs: [] //TBA
        };

        return map;
    }
}
final class Additions{
    private static final fileExtensionsList:Array<String>=[
        ".png", ".json", ".xml", ".ogg", ".weapon",
        ".lang", ".ttf"
    ];
    //for math
    /**
     * return positive version of negative input number
     * @param number number to make positive.
     * @return positive number input
     */
    public static inline function toPositive(number:Float):Float return number+(number*2);
    /**
     * floor a number
     * @param n input number
     * @return Int
     */
    public static inline function floor(n:Float):Int return Math.floor(n);
    /**
     * return clampped number
     * @param n input
     * @param min minimum
     * @param max maximum
     * @return Float
     */
    public static inline function clamp(n:Float, min:Float, max:Float):Int return Math.floor(Math.max(min, Math.min(n, max)));
    /**
     * clamp but floating point
     * @param n input
     * @param min minimum
     * @param max maxiumum
     * @return Int return Math.floor(Math.max(min, Math.min(n, max)))
     */
    public static inline function clampf(n:Float, min:Float, max:Float):Float return Math.max(min, Math.min(n, max));
    /**
     * return added number
     * @param n input number
     * @param added number to add by
     * @return Float
     */
    public static inline function add(n:Float, added:Float):Float return n+=added;
    /**
     * return subtracted number
     * @param n input number
     * @param removed subtracted
     * @return Float
     */
    public static inline function subtract(n:Float, removed:Float):Float return n-=removed;
    /**
     * return stringified number
     * @param n input Number
     * @return String
     */
    public static inline function toString(n:Float):String return '$n';
    /**
     * get a percentage of a value.
     * @param number number to get percentage from
     * @param percentage what percentage we want.
     * @return Float return (percentage / 100) * number
     */
    public static inline function getPercentage(number:Float, percentage:Float):Float return (percentage/100)*number;

    //for strings
    /**
     * check if a string contains any string within an array of strings.
     * @param s string to check
     * @param any array of strings to compare too
     * @return Bool if the string contains anything from `any`
     */
    public static function containsAny(s:String, any:Array<String>):Bool {
        for(k in any) if(s.indexOf(k)!=-1) return true;
        return false;
    }
    /**
     * compares if a string is a datafile (intended for use with File.hx to find the recursive file we want.)
     * @param s string to check
     * @return Bool if the path is a datafile.
     */
    public static inline function isDataFile(s:String):Bool {
        if(s.containsAny(fileExtensionsList)) return true;
        return false;
    }
    /**
     * insert function for when StringTools wants to be a bitch
     * @param s left half
     * @param b right half
     * @param i what to insert
     * @return String
     */
    public static inline function insert(s:String, b:String, i:Dynamic):String return '${s.split(b)[0]}$i${s.split(b)[1]}';
    /**
     * same as insert, but different.
     * @param s input string
     * @param b where to graft it
     * @return String
     */
    public static inline function graft(s:String, b:String):String return '${s.split(b)[0]}${s.split(b)[1]??""}';
    /**
     * turn a String into a Int
     * @param s input string
     * @return Int
     */
    public static inline function toInt(s:String):Int return Std.parseInt(s);
    /**
     * turn a String into a Bool
     * @param i input string
     * @return Bool
     */
    public static inline function toBool(i:String):Bool return i.toLowerCase()=="true"?true:false;
    /**
     * turn a String into a Float
     * @param s input string
     * @return Float return Std.parseFloat(s)
     */
    public static inline function toFloat(s:String):Float return Std.parseFloat(s);
    /**
     * remove a part from a string
     * @param s input
     * @param b to be removed
     * @return String
     */
    public static inline function remove(s:String, b:String) return s.replace(b, '');
    /**
     * check if a string is empty
     * @param s input
     * @return Bool
     */
    public static inline function isEmptySTR(s:String):Bool return s==""; 
    /**
     * turn a string into an array of Int
     * @param s input string
     * @param indicies 
     * @return Array<Int>
     */
    public static function StringToArray(s:String,?indicies:Bool=false):Array<Int>{
        var toReturn:Array<Int>=[];
        var nums:Array<String> = s.split(indicies?',':'...');
        if(indicies) for(number in 0...nums.length) toReturn.push(Std.parseInt(nums[number]));
        else for(number in Std.parseInt(nums[0])...Std.parseInt(nums[1]))toReturn.push(number);
        return toReturn;
    }

    //arrays
    /**
     * combine two arrays
     * @param a original array
     * @param b secondary array
     * @return both arrays combined, a then b
     */
    public static function combine(a:Array<Dynamic>, b:Array<Dynamic>):Array<Dynamic> {
        var returnArray:Array<Dynamic>=[];
        for(item in a) returnArray.push(item);
        for(item in b) returnArray.push(item);
        return returnArray;
    }
    /**
     * clear an array
     * @param a original array
     * @return it just returns an empty array lol.
     */
    public static function clear(a:Array<Dynamic>):Array<Dynamic> return a=[];
    /**
     * Specifically made for the inventory system as im implementing item movement between slots in a very basic way now.
     * @param a inventory array (must be Array<OneOfTwo<String, Item>>)
     * @return Int index of first empty.
     * WILL RETURN -1 IF THERE ARE NO EMPTY SLOTS.
     */
    public static function getFirstEmpty(a:Array<OneOfTwo<String, Item>>):Int {
        for(index in 0...a.length) {
            if(a[index]!="EMPTY")continue;
            else return index;
        }
        return -1;
    }
    /**
     * flip an array around
     * @param a input array
     * @return Array<Dynamic>
     */
    public static function reverse(a:Array<Dynamic>):Array<Dynamic>{
        var reversed:Array<Dynamic> = a;
        reversed.reverse();
        return reversed;
    }

    //actual objects.
    public static function center(spr:FlxSprite, on:OneOfTwo<FlxObject, ExtendedCamera>, ?offs:FlxPoint):FlxSprite {
        if(offs==null) offs=FlxPoint.weak(0, 0);
        spr.x = (on.x+on.width/2-spr.width/2)+(offs.x);
        spr.y = (on.y+on.height/2-spr.height/2)+(offs.y);
        return spr;
    }
}