package backend;

final class Functions {
    public static function wait(time:Float, onComplete:FlxTimer->Void) {
        return new FlxTimer().start(time, (_)->{
            onComplete(_);
            _.destroy();
        });
    }
    
    public static function checkJustPressedSafe(keys:Array<FlxKey>):Bool {
        var h:Array<FlxKey>=[];
        for(key in keys){
            if(key == NONE) continue;
            else h.push(key);
        }
        return FlxG.keys.anyJustPressed(h);
    }
    public static function checkPressedSafe(keys:Array<FlxKey>):Bool {
        var h:Array<FlxKey>=[];
        for(key in keys){
            if(key == NONE) continue;
            else h.push(key);
        }
        return FlxG.keys.anyPressed(h);
    }
    public static function checkJustReleasedSafe(keys:Array<FlxKey>):Bool {
        var h:Array<FlxKey>=[];
        for(key in keys){
            if(key == NONE) continue;
            else h.push(key);
        }
        return FlxG.keys.anyJustReleased(h);
    }

    //is this a horrible fucking way to do it? abso-fucking-lutely (DO NOT USE OFTEN. LAST RESORT)
    public static function FlxKeyFromInt(key:Int):FlxKey {
        switch(key){
            case 2: return FlxKey.ANY;
            case 1: return FlxKey.NONE;
            case 65: return FlxKey.A;
            case 66: return FlxKey.B;
            case 67: return FlxKey.C;
            case 68: return FlxKey.D;
            case 69: return FlxKey.E;
            case 70: return FlxKey.F;
            case 71: return FlxKey.G;
            case 72: return FlxKey.H;
            case 73: return FlxKey.I;
            case 74: return FlxKey.J;
            case 75: return FlxKey.K;
            case 76: return FlxKey.L;
            case 77: return FlxKey.M;
            case 78: return FlxKey.N;
            case 79: return FlxKey.O;
            case 80: return FlxKey.P;
            case 81: return FlxKey.Q;
            case 82: return FlxKey.R;
            case 83: return FlxKey.S;
            case 84: return FlxKey.T;
            case 85: return FlxKey.U;
            case 86: return FlxKey.V;
            case 87: return FlxKey.W;
            case 88: return FlxKey.X;
            case 89: return FlxKey.Y;
            case 90: return FlxKey.Z;
            case 48: return FlxKey.ZERO;
            case 49: return FlxKey.ONE;
            case 50: return FlxKey.TWO;
            case 51: return FlxKey.THREE;
            case 52: return FlxKey.FOUR;
            case 53: return FlxKey.FIVE;
            case 54: return FlxKey.SIX;
            case 55: return FlxKey.SEVEN;
            case 56: return FlxKey.EIGHT;
            case 57: return FlxKey.NINE;
            case 33: return FlxKey.PAGEUP;
            case 34: return FlxKey.PAGEDOWN;
            case 36: return FlxKey.HOME;
            case 35: return FlxKey.END;
            case 45: return FlxKey.INSERT;
            case 27: return FlxKey.ESCAPE;
            case 189: return FlxKey.MINUS;
            case 187: return FlxKey.PLUS;
            case 46: return FlxKey.DELETE;
            case 8: return FlxKey.BACKSPACE;
            case 219: return FlxKey.LBRACKET;
            case 221: return FlxKey.RBRACKET;
            case 220: return FlxKey.BACKSLASH;
            case 20: return FlxKey.CAPSLOCK;
            case 145: return FlxKey.SCROLL_LOCK;
            case 144: return FlxKey.NUMLOCK;
            case 186: return FlxKey.SEMICOLON;
            case 222: return FlxKey.QUOTE;
            case 13: return FlxKey.ENTER;
            case 16: return FlxKey.SHIFT;
            case 188: return FlxKey.COMMA;
            case 190: return FlxKey.PERIOD;
            case 191: return FlxKey.SLASH;
            case 192: return FlxKey.GRAVEACCENT;
            case 17: return FlxKey.CONTROL;
            case 18: return FlxKey.ALT;
            case 32: return FlxKey.SPACE;
            case 38: return FlxKey.UP;
            case 40: return FlxKey.DOWN;
            case 37: return FlxKey.LEFT;
            case 39: return FlxKey.RIGHT;
            case 9: return FlxKey.TAB;
            case 15: return FlxKey.WINDOWS;
            case 302: return FlxKey.MENU;
            case 301: return FlxKey.PRINTSCREEN;
            case 19: return FlxKey.BREAK;
            case 112: return FlxKey.F1;
            case 113: return FlxKey.F2;
            case 114: return FlxKey.F3;
            case 115: return FlxKey.F4;
            case 116: return FlxKey.F5;
            case 117: return FlxKey.F6;
            case 118: return FlxKey.F7;
            case 119: return FlxKey.F8;
            case 120: return FlxKey.F9;
            case 121: return FlxKey.F10;
            case 122: return FlxKey.F11;
            case 123: return FlxKey.F12;
            case 96: return FlxKey.NUMPADZERO;
            case 97: return FlxKey.NUMPADONE;
            case 98: return FlxKey.NUMPADTWO;
            case 99: return FlxKey.NUMPADTHREE;
            case 100: return FlxKey.NUMPADFOUR;
            case 101: return FlxKey.NUMPADFIVE;
            case 102: return FlxKey.NUMPADSIX;
            case 103: return FlxKey.NUMPADSEVEN;
            case 104: return FlxKey.NUMPADEIGHT;
            case 105: return FlxKey.NUMPADNINE;
            case 109: return FlxKey.NUMPADMINUS;
            case 107: return FlxKey.NUMPADPLUS;
            case 110: return FlxKey.NUMPADPERIOD;
            case 106: return FlxKey.NUMPADMULTIPLY;
            case 111: return FlxKey.NUMPADSLASH;
            default: return NONE; //return NONE by default.
        }
    }
}

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
    public static inline function isEmptySTR(s:String):Bool return s==""; 
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