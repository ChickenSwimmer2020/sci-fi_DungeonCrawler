package;

class Flags {
    public static final SECURITY_SECONDSTILLACTIVATION:Int = 120;
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