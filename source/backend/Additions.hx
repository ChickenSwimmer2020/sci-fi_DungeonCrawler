package backend;

import backend.game.states.substates.HUDSubstate.Item;
import flixel.util.typeLimit.OneOfTwo;

final class Additions{
    //for math
    public static inline function clamp(n:Float, min:Float, max:Float) return Math.max(min, Math.min(n, max));
    public static inline function add(n:Float, added:Float):Float return n+=added;
    public static inline function subtract(n:Float, removed:Float):Float return n-=removed;
    public static inline function toString(n:OneOfTwo<Int, Float>):String return '$n';
    //for strings
    public static inline function insert(s:String, b:String, i:Dynamic):String return '${s.split(b)[0]}$i${s.split(b)[1]}';
    public static inline function graft(s:String, b:String):String return '${s.split(b)[0]}${s.split(b)[1]??""}';
    public static inline function toInt(s:String):Int return Std.parseInt(s);
    public static inline function toBool(i:String):Bool return i.toLowerCase()=="true"?true:false;
    public static inline function toFloat(s:String):Float return Std.parseFloat(s);
    public static inline function remove(s:String, b:String) return s.replace(b, '');
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
    public static function flip(a:Array<Dynamic>):Array<Dynamic>{
        var reversed:Array<Dynamic>=new Array<Dynamic>();
        for(object in a.length...0)reversed[object] = a[object];
        return reversed;
    }
}