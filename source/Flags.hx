package;
#if(!html5) import openfl.filesystem.File as OpenFLFile; #end
class Flags {
    #if debug
        public static var CC_MADECUTSCENE:Bool=false; //allows create new popup to be closed if you accidently click it.
        public static var CC_THEREISAPOPUPOPENDONOTUSECUTSCENECONTROLS:Bool=false;
        public static final CC_DEFAULTLOADPATH:String = #if(html5)"assets/cutscenes/"#else'${OpenFLFile.applicationDirectory.nativePath}/assets/cutscenes/'#end;
    #end
    public static final SLS_WARNING_THRESHOLD:Int=120; //this is in seconds. (120=2 minutes)
    public static final ERROR_MESSAGES:Map<String, Array<String>>=[
        "TEST"=>["window title", "message box"],
        "IOERROR"=>["error.nullio.title", "error.nullio.message"],
        "RENDERFAILURE"=>["error.renderfailure.title", "error.renderfailure.message"],
        "SAVENOTCACHED"=>["error.cachefault.title", "error.cachefault.message"],
        "MISSINGLANG"=>["error.languagemissing.title", "error.languagemissing.message"],
        //"MISSINGMAP"=>["error.mapnotfound", "error.mapnotfound.message"], //!CUT CONTENT (removed in 0.02)
        "NULLITEM"=>["error.nullitem.title", "error.nullitem.message"],
        "MAPNULL"=>["error.mapnotfound.title", "error.mapnotfound.message"] //LOL imma just reuse this cut error message
    ];
    public static final DEFAULT_LANGUAGE:Lang = EN_US;
    public static final DEFAULT_CONTROLS:Map<String,Array<FlxKey>>=[
        "moveUP" => [UP, W],
        "moveDOWN" => [DOWN, S],
        "moveRIGHT" => [FlxKey.RIGHT, D], //Thanks FlxTextAlign! (Dont remove the `FlxKey.` as it will try to use FlxTextAlign instead of FlxKey.) :/
        "moveLEFT" => [FlxKey.LEFT, A],

        "zoomIN" => [PLUS, FlxKey.NONE], //so, apparently PotionType.NONE replaced FlxKey.NONE?????
        "zoomOUT" => [MINUS, FlxKey.NONE],
        "pause" => [ESCAPE, BACKSPACE],
        "inventory" => [I, FlxKey.NONE],
        "interact" => [E, ENTER],
        "sprint" => [SHIFT, FlxKey.NONE],
    ];
    public static final DEFAULT_JSON_RECURSION_CHECKS:Int = 20;
    public static final CONDUCTOR_BPM_CHECK_INTERVAL:Int=1;
    public static final FALLBACK_WEAPON:WeaponData = {
        animations: [],
        damage: [],
        kickback: 0,
        fireMode: SEMI,
        format: NULL,
        fireTime: 0.0,
        sprite: {n:"",a:false,f:{w:0,h:0}},
        weaponType: NULL,
        name: "",
        magicType: NULL,
        gunType: NULL,
    };
    public static inline final DEFAULT_SAVE:String="default";
    public static final DEFAULT_SAVEFILE:SaveFile = { //would be inline but apparently this isnt constant?
        meta:{
            name: "",
            playtime:{H: 0,M: 0,s: 0},
            difficulty: "",
            depth: 0,
            level: 0
        },
        health: 0,
        stamina: 0,
        xp: 0,
        position: {x:0, y:0},
        inventory: [],
        maps: [],
    };
}