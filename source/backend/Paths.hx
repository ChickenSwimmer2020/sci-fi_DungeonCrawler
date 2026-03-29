package backend;

class Paths {
    public static final tilesPath:String="assets/tiles";
    public static final langPath:String="assets/lang";
    public static final itemPath:String="assets/items";
    public static final weaponsPath:String="assets/items/weapons";
    public static final musicPath:String="assets/audio/music";
    #if (debug) public static final debugPath:String="assets/debug"; #end

    public static inline function weaponExists(w:String):Bool{
        #if (android || html5)
            return Assets.getText(Paths.weapon(w))!=null;
        #else
            return FileSystem.exists(Paths.weapon(w));
        #end
    }

    public static inline function tiles(image:String)#if (android||html5) :BitmapData#else:String#end{
        return Paths.image('tiles', image);
    }
    public static inline function lang(l:String):String return '${langPath}/${l.toUpperCase()}.lang';
    public static inline function image(folder:String,i:String)#if (android||html5) :BitmapData#else:String#end{
        #if (android || html5)
            return Assets.getBitmapData('assets/$folder/$i.png');
        #else
            return 'assets/$folder/$i.png';
        #end
    }
    public static inline function weapon(w:String):String return '${weaponsPath}/$w.weapon'; 
    #if (debug)
        public static inline function DEBUG(i:String,?ext:String="png")#if(android||html5):BitmapData#else:String#end
            return Paths.image('debug', i);
    #end
}