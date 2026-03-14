package;

class Flags {
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
        #if !android controls: [], #end
        inventory: [],
        maps: [],
    };
}