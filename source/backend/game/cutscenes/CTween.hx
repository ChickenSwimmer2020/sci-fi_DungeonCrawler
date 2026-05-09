package backend.game.cutscenes;

typedef BakedTween = {
    obj:String, prop:String,
    from:Float, to:Float,
    startFrame:Int, endFrame:Int,
    easeFn:Float->Float
}
/** <Tween obj="sky" prop="y" from="-720" to="0" duration="218" ease="expoIn"/> */
class CTween {
    public var obj:String;
    public var prop:String;
    public var from:Null<Float>;
    public var to:Float;
    public var duration:Int;
    public var ease:String = "linear";

    public function new() {}

    public static function fromXml(el:Xml):CTween {
        var t = new CTween();
        t.obj      = el.get("obj") ?? "";
        t.prop     = el.get("prop") ?? "x";
        t.to       = Std.parseFloat(el.get("to") ?? "0") ?? 0;
        t.duration = Std.parseInt(el.get("duration") ?? "24") ?? 24;
        t.ease     = el.get("ease") ?? "linear";
        var fromStr = el.get("from");
        t.from = fromStr != null ? Std.parseFloat(fromStr) : null;
        return t;
    }

    public function serialize(sb:StringBuf, depth:Int) {
        var ind = _indent(depth);
        var fromAttr = from != null ? ' from="$from"' : "";
        sb.add('$ind<Tween obj="$obj" prop="$prop"$fromAttr to="$to" duration="$duration" ease="$ease"/>\n');
    }

    public function clone():CTween {
        var t = new CTween();
        t.obj = obj; t.prop = prop; t.from = from; t.to = to;
        t.duration = duration; t.ease = ease;
        return t;
    }

    public static function resolveEase(name:String):Float->Float {
        return switch(name) {
            case "quadIn":      FlxEase.quadIn;
            case "quadOut":     FlxEase.quadOut;
            case "quadInOut":   FlxEase.quadInOut;
            case "cubeIn":      FlxEase.cubeIn;
            case "cubeOut":     FlxEase.cubeOut;
            case "cubeInOut":   FlxEase.cubeInOut;
            case "expoIn":      FlxEase.expoIn;
            case "expoOut":     FlxEase.expoOut;
            case "expoInOut":   FlxEase.expoInOut;
            case "sineIn":      FlxEase.sineIn;
            case "sineOut":     FlxEase.sineOut;
            case "sineInOut":   FlxEase.sineInOut;
            case "bounceIn":    FlxEase.bounceIn;
            case "bounceOut":   FlxEase.bounceOut;
            case "bounceInOut": FlxEase.bounceInOut;
            case "elasticIn":   FlxEase.elasticIn;
            case "elasticOut":  FlxEase.elasticOut;
            case "backIn":      FlxEase.backIn;
            case "backOut":     FlxEase.backOut;
            default:            (t:Float) -> t;
        };
    }

    public static final ALL_EASES:Array<String> = [
        "linear","quadIn","quadOut","quadInOut","cubeIn","cubeOut","cubeInOut",
        "expoIn","expoOut","expoInOut","sineIn","sineOut","sineInOut",
        "bounceIn","bounceOut","bounceInOut","elasticIn","elasticOut",
        "backIn","backOut"
    ];

    static function _indent(d:Int) return StringTools.rpad("", " ", d * 4);
}