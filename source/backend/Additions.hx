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
            if(_.loopsLeft==0) _.destroy();
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
}
final class Additions{
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

    //for strings
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
    public static function center(spr:FlxSprite, on:FlxObject):FlxSprite {
        spr.x = on.x+on.width/2-spr.width/2;
        spr.y = on.y+on.height/2-spr.height/2;
        return spr;
    }
}