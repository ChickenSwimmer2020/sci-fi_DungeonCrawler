package;

class Flags {

    public static final DEFAULT_JSON_RECURSION_CHECKS:Int = 20;
    public static final CONDUCTOR_BPM_CHECK_INTERVAL:Int=1;

    //intro loop twice, then tense loop twice, then super-tense loop twice
    public static final SECURITY_SECONDSTILLACTIVATION:Float = 263.28;
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